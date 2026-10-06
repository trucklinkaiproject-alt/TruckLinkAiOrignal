import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Features/Broker Module/bloc/brokerAssignDriverBloc/brokerAssignDriverState.dart';

/// Canonical comparison key for vehicle types (case/space/punctuation-insensitive),
/// so "Pickup Truck" and "PickUp Truck" compare equal while "Truck" != "PickUp Truck".
String normalizeVehicleType(String? value) =>
    (value ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Offer statuses (Driver/{id}/ReceivedOffers) that mean the driver is on an active trip.
const List<String> kActiveDriverTripStatuses = [
  'accepted_by_driver',
  'accepted',
  'in_progress',
  'in_transit',
  'arrived_at_pickup',
  'heading_to_drop',
];

class BrokerAssignDriverCubit extends Cubit<BrokerAssignDriverState> {
  BrokerAssignDriverCubit() : super(BrokerAssignDriverInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// True if the driver currently has an accepted/in-transit trip.
  Future<bool> _hasActiveTrip(String driverId) async {
    try {
      final snap = await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .where('status', whereIn: kActiveDriverTripStatuses)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Fetches drivers from the current Broker's Driver Network whose vehicle_type
  /// matches the User Order's required vehicle type and who are currently online and available.
  Future<void> fetchEligibleDrivers({
    required String brokerId,
    required String requiredVehicleType,
  }) async {
    try {
      if (isClosed) return;
      emit(BrokerAssignDriverLoadingState());

      final snapshot = await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("DriverNetwork")
          .get();

      final targetVehicleType = normalizeVehicleType(requiredVehicleType);

      final List<Map<String, dynamic>> eligible = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final driverId = doc.id;
        final driverVehicleType = normalizeVehicleType(
          (data['vehicle_type'] ?? data['vehicleType'] ?? '').toString(),
        );

        // Check availability status
        final rawAvailability = (data['availability_status'] ?? data['status'] ?? 'offline').toString().toLowerCase();

        // Exact (normalized) match: Driver.vehicle_type == Order.vehicle_type.
        // No substring matching, so "Truck" never matches "PickUp Truck".
        final bool vehicleMatches =
            targetVehicleType.isEmpty || driverVehicleType == targetVehicleType;

        if (!vehicleMatches) continue;

        // Verify with the live Driver document (account must exist) and live availability.
        String liveStatus = rawAvailability;
        try {
          final driverDoc = await _firestore.collection("Driver").doc(driverId).get();
          if (!driverDoc.exists) continue; // account no longer valid
          final dData = driverDoc.data() ?? {};
          liveStatus = (dData['availability_status'] ?? dData['status'] ?? rawAvailability).toString().toLowerCase();

          // Live vehicle type is the source of truth if it differs from the network copy.
          final liveType = normalizeVehicleType(
            (dData['vehicle_type'] ?? dData['vehicleType'] ?? '').toString(),
          );
          if (liveType.isNotEmpty && targetVehicleType.isNotEmpty && liveType != targetVehicleType) {
            continue;
          }
        } catch (_) {}

        // Skip drivers already occupied by an active trip/order.
        if (liveStatus == 'on_ride') continue;
        if (await _hasActiveTrip(driverId)) continue;

        eligible.add({
          'id': driverId,
          ...data,
          'is_online': liveStatus == 'online' || liveStatus == 'active',
          'availability_status': liveStatus,
        });
      }

      if (!isClosed) {
        emit(BrokerAssignDriverLoadedState(
          eligibleDrivers: eligible,
          requiredVehicleType: requiredVehicleType,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(BrokerAssignDriverErrorState("Failed to fetch eligible drivers: ${e.toString()}"));
      }
    }
  }

  /// Sends a Broker -> Driver Offer Request for an Order.
  /// Enforces duplicate active offer protection and updates Order status.
  Future<void> sendDriverOffer({
    required String brokerId,
    required Map<String, dynamic> orderData,
    required Map<String, dynamic> driverData,
    required double fareAmount,
  }) async {
    try {
      final String orderId = (orderData['orderId'] ?? orderData['id'] ?? orderData['orderNo'] ?? '').toString();
      final String orderNo = (orderData['orderNo'] ?? orderId).toString();
      final String userUid = (orderData['userUid'] ?? orderData['user_uid'] ?? '').toString();
      final String driverId = (driverData['driver_id'] ?? driverData['driverId'] ?? driverData['id'] ?? '').toString();
      final String driverName = (driverData['name'] ?? driverData['driver_name'] ?? 'Driver').toString();
      final String vehicleType = (driverData['vehicle_type'] ?? orderData['vehicleType'] ?? 'Truck').toString();
      final String vehicleNumber = (driverData['vehicle_number'] ?? 'Not specified').toString();

      if (orderId.isEmpty) {
        emit(BrokerAssignDriverErrorState("Invalid Order ID."));
        return;
      }
      if (driverId.isEmpty) {
        emit(BrokerAssignDriverErrorState("Invalid Driver ID."));
        return;
      }
      if (fareAmount <= 0) {
        emit(BrokerAssignDriverErrorState("Please enter a valid fare amount."));
        return;
      }

      emit(BrokerAssignDriverSendingState(driverId));

      // PART 28: Duplicate Active Offer Protection
      final existingOfferCheck = await _firestore
          .collection("Orders")
          .doc(orderId)
          .collection("DriverOffers")
          .where("driver_id", isEqualTo: driverId)
          .get();

      for (var doc in existingOfferCheck.docs) {
        final status = (doc.data()['status'] ?? '').toString();
        if (status == 'pending' || status == 'accepted_by_driver') {
          emit(BrokerAssignDriverErrorState(
            "An active offer ($status) already exists for $driverName on Order #$orderNo.",
          ));
          return;
        }
      }

      final String offerId = DateTime.now().millisecondsSinceEpoch.toString();

      final offerPayload = {
        'offer_id': offerId,
        'order_id': orderId,
        'order_no': orderNo,
        'broker_id': brokerId,
        'broker_name': orderData['brokerName'] ?? 'Broker',
        'driver_id': driverId,
        'driver_name': driverName,
        'driver_phone': driverData['phone'] ?? driverData['driver_phone'] ?? '',
        'vehicle_type': vehicleType,
        'vehicle_number': vehicleNumber,
        'fare': fareAmount,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        // Complete Order Details Snapshot (PART 19)
        'user_uid': userUid,
        'pickup_city': orderData['pickupCity'] ?? orderData['pickup_city'] ?? '',
        'drop_city': orderData['dropCity'] ?? orderData['drop_city'] ?? '',
        'pickup_comp': orderData['pickupComp'] ?? orderData['pickup_comp'] ?? '',
        'drop_comp': orderData['dropComp'] ?? orderData['drop_comp'] ?? '',
        'pickup_lat': (orderData['pickup_lat'] ?? orderData['pickupLatitude'] ?? orderData['pickupLat'] as num?)?.toDouble() ?? 0.0,
        'pickup_lng': (orderData['pickup_lng'] ?? orderData['pickupLongitude'] ?? orderData['pickupLng'] as num?)?.toDouble() ?? 0.0,
        'drop_lat': (orderData['drop_lat'] ?? orderData['dropLatitude'] ?? orderData['dropLat'] as num?)?.toDouble() ?? 0.0,
        'drop_lng': (orderData['drop_lng'] ?? orderData['dropLongitude'] ?? orderData['dropLng'] as num?)?.toDouble() ?? 0.0,
        'item_type': orderData['itemType'] ?? orderData['item_type'] ?? '',
        'weight': orderData['weight'] ?? 0,
        'quantity': orderData['quantity'] ?? 0,
        'additional_info': orderData['additionalInfo'] ?? orderData['additional_info'] ?? '',
        'date': orderData['date'] ?? '',
      };


      // Write Offer under Orders/{orderId}/DriverOffers/{offerId}
      await _firestore
          .collection("Orders")
          .doc(orderId)
          .collection("DriverOffers")
          .doc(offerId)
          .set(offerPayload);

      // Write mirrored record under Driver/{driverId}/ReceivedOffers/{offerId} for fast indexing
      await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId)
          .set(offerPayload);

      // Notify Driver of assignment
      try {
        final String driverNotifId = "driver_offer_${orderId}_$offerId";
        await NotificationService().sendNotification(
          targetCollection: 'Driver',
          recipientId: driverId,
          type: NotificationTypes.driverAssigned,
          title: 'New Shipment Assignment',
          body: 'You have a new shipment assignment for Order #$orderNo. Driver Fare: PKR ${fareAmount.toStringAsFixed(0)}',
          notificationId: driverNotifId,
          orderId: orderId,
          orderNo: orderNo,
          senderId: brokerId,
          receiverRole: 'Driver',
          additionalData: {
            'driver_fare': fareAmount,
            'offer_id': offerId,
          },
        );
      } catch (_) {}

      final String driverPhone = (driverData['phone'] ?? driverData['driver_phone'] ?? '').toString();

      // Update Order Status in Broker/IncomingRequests and User/Requests
      // Preserve customer_fare/brokerOffer - store driver payment in driver_fare / assigned_fare
      final updateData = {
        'status': 'driver_offer_sent',
        'assigned_driver_id': driverId,
        'assigned_driver_name': driverName,
        'assigned_driver_phone': driverPhone,
        'assigned_fare': fareAmount,
        'driver_fare': fareAmount,
        'driverFare': fareAmount,
        'broker_driver_fare': fareAmount,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .update(updateData);

      // Broker Notification for driver assignment
      try {
        final String brokerNotifId = "driver_asgn_${orderId}_$driverId";
        await NotificationService().sendNotification(
          targetCollection: 'Broker',
          recipientId: brokerId,
          type: NotificationTypes.driverAssigned,
          title: 'Driver Assigned',
          body: 'Driver $driverName has been assigned to Order #$orderNo. Driver Payment: PKR ${fareAmount.toStringAsFixed(0)}',
          notificationId: brokerNotifId,
          orderId: orderId,
          orderNo: orderNo,
          senderId: brokerId,
          receiverRole: 'Broker',
          additionalData: {
            'driver_id': driverId,
            'driver_name': driverName,
            'driver_fare': fareAmount,
          },
        );
      } catch (_) {}

      if (userUid.isNotEmpty) {
        try {
          await _firestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .update(updateData);
        } catch (_) {}

        try {
          final String notifId = "driver_${orderId}_$driverId";
          await NotificationService().sendNotification(
            targetCollection: 'User',
            recipientId: userUid,
            type: NotificationTypes.driverAssigned,
            title: 'Driver Assigned',
            body: 'A driver has been assigned to your shipment.\n\nDriver: $driverName\nPhone: ${driverPhone.isNotEmpty ? driverPhone : 'N/A'}\nOrder No: #$orderNo',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: brokerId,
            receiverRole: 'User',
            additionalData: {
              'driver_id': driverId,
              'driver_name': driverName,
              'driver_phone': driverPhone,
            },
          );
        } catch (_) {}
      }

      if (!isClosed) {
        emit(BrokerAssignDriverSuccessState(
          "Offer of PKR ${fareAmount.toStringAsFixed(0)} successfully sent to $driverName!",
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(BrokerAssignDriverErrorState("Failed to send driver offer: ${e.toString()}"));
      }
    }
  }
}
