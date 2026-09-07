import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Broker Module/bloc/brokerAssignDriverBloc/brokerAssignDriverState.dart';

class BrokerAssignDriverCubit extends Cubit<BrokerAssignDriverState> {
  BrokerAssignDriverCubit() : super(BrokerAssignDriverInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches drivers from the current Broker's Driver Network whose vehicle_type
  /// matches the User Order's required vehicle type.
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

      final targetVehicleType = requiredVehicleType.trim().toLowerCase();

      final List<Map<String, dynamic>> eligible = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final driverVehicleType =
            (data['vehicle_type'] ?? '').toString().trim().toLowerCase();

        // PART 13 & 14: Match Driver.vehicle_type == Order.required_vehicle_type
        if (targetVehicleType.isEmpty ||
            driverVehicleType == targetVehicleType ||
            driverVehicleType.contains(targetVehicleType) ||
            targetVehicleType.contains(driverVehicleType)) {
          eligible.add({
            'id': doc.id,
            ...data,
          });
        }
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
        'pickup_city': orderData['pickupCity'] ?? '',
        'drop_city': orderData['dropCity'] ?? '',
        'pickup_comp': orderData['pickupComp'] ?? '',
        'drop_comp': orderData['dropComp'] ?? '',
        'item_type': orderData['itemType'] ?? '',
        'weight': orderData['weight'] ?? 0,
        'quantity': orderData['quantity'] ?? 0,
        'additional_info': orderData['additionalInfo'] ?? '',
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
        await _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("Notifications")
            .doc(brokerNotifId)
            .set({
              'id': brokerNotifId,
              'broker_id': brokerId,
              'type': 'driver_assigned',
              'title': 'Driver Assigned',
              'body': 'Driver $driverName has been assigned to Order #$orderNo. Driver Payment: PKR ${fareAmount.toStringAsFixed(0)}',
              'order_id': orderId,
              'order_no': orderNo,
              'driver_id': driverId,
              'driver_name': driverName,
              'driver_fare': fareAmount,
              'timestamp': FieldValue.serverTimestamp(),
              'is_read': false,
            }, SetOptions(merge: true));
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
          await _firestore
              .collection("User")
              .doc(userUid)
              .collection("Notifications")
              .doc(notifId)
              .set({
                'id': notifId,
                'user_uid': userUid,
                'type': 'driver_assigned',
                'title': 'Driver Assigned',
                'body': 'A driver has been assigned to your shipment.\n\nDriver: $driverName\nPhone: ${driverPhone.isNotEmpty ? driverPhone : 'N/A'}\nOrder No: #$orderNo',
                'order_id': orderId,
                'order_no': orderNo,
                'driver_id': driverId,
                'driver_name': driverName,
                'driver_phone': driverPhone,
                'timestamp': FieldValue.serverTimestamp(),
                'is_read': false,
              }, SetOptions(merge: true));
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
