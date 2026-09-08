import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Services/driverLocationService.dart';
import 'package:trucklinkai_orignal/Features/Transporter Module/bloc/driverOffersBloc/driverOffersState.dart';

class DriverOffersCubit extends Cubit<DriverOffersState> {
  DriverOffersCubit() : super(DriverOffersInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot>? _offersSubscription;

  List<Map<String, dynamic>> _currentOffers = [];
  List<Map<String, dynamic>> get currentOffers => _currentOffers;

  /// Returns the current active ride if driver has an accepted or in-transit ride
  Map<String, dynamic>? get activeRide {
    for (final offer in _currentOffers) {
      final status = (offer['status'] ?? '').toString().toLowerCase();
      if (status == 'accepted_by_driver' ||
          status == 'accepted' ||
          status == 'in_progress' ||
          status == 'in_transit' ||
          status == 'arrived_at_pickup' ||
          status == 'heading_to_drop') {
        return offer;
      }
    }
    return null;
  }

  /// Subscribes to offers sent strictly to the current Driver in real-time.
  void listenToOffers({required String driverId}) {
    try {
      if (isClosed) return;
      emit(DriverOffersLoadingState());

      _offersSubscription?.cancel();
      _offersSubscription = _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .snapshots()
          .listen(
        (snapshot) {
          if (isClosed) return;

          _currentOffers = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();

          emit(DriverOffersLoadedState(_currentOffers));
        },
        onError: (error) {
          if (!isClosed) emit(DriverOffersErrorState(error.toString()));
        },
      );
    } catch (e) {
      if (!isClosed) emit(DriverOffersErrorState(e.toString()));
    }
  }

  /// Driver accepts a Broker offer from the Driver Home page.
  /// Sets offer status to 'accepted_by_driver' and updates Order status in all collections.
  Future<void> acceptOffer({required Map<String, dynamic> offer}) async {
    try {
      final String currentUid = _auth.currentUser?.uid ?? '';
      final String offerId = (offer['offer_id'] ?? offer['id'] ?? '').toString();
      final String orderId = (offer['order_id'] ?? offer['orderId'] ?? '').toString();
      final String brokerId = (offer['broker_id'] ?? offer['brokerId'] ?? '').toString();
      final String driverId = (offer['driver_id'] ?? offer['driverId'] ?? currentUid).toString();
      final String userUid = (offer['user_uid'] ?? offer['userUid'] ?? '').toString();
      final String orderNo = (offer['order_no'] ?? orderId).toString();
      final String driverName = (offer['driver_name'] ?? 'Driver').toString();

      // Guard: Ensure user is the assigned driver
      if (currentUid.isNotEmpty && driverId.isNotEmpty && currentUid != driverId) {
        emit(DriverOffersErrorState("Unauthorized: You cannot accept an offer assigned to another driver."));
        return;
      }

      if (offerId.isEmpty || orderId.isEmpty) {
        emit(DriverOffersErrorState("Invalid offer or order reference."));
        return;
      }

      final updateData = {
        'status': 'accepted_by_driver',
        'accepted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // 1. Update Offer in Orders/{orderId}/DriverOffers/{offerId}
      try {
        await _firestore
            .collection("Orders")
            .doc(orderId)
            .collection("DriverOffers")
            .doc(offerId)
            .update(updateData);
      } catch (_) {}

      // 2. Update Offer in Driver/{driverId}/ReceivedOffers/{offerId}
      await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId)
          .update(updateData);

      // 3. Update main Orders document
      await _firestore
          .collection("Orders")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      // 4. Update Order status in Broker/IncomingRequests
      if (brokerId.isNotEmpty) {
        await _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId)
            .update(updateData);

        // Notify Broker
        final String notifId = "driver_acc_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: brokerId,
            type: NotificationTypes.driverAccepted,
            title: 'Driver Accepted Assignment',
            body: '$driverName accepted the assignment for Order #$orderNo.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'Broker',
          );
        } catch (_) {}
      }

      // 5. Update Order status in User/Requests
      if (userUid.isNotEmpty) {
        try {
          await _firestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .update(updateData);
        } catch (_) {}

        // Notify User
        final String notifId = "driver_acc_user_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'User',
            recipientId: userUid,
            type: NotificationTypes.driverAccepted,
            title: 'Driver Confirmed',
            body: '$driverName has accepted your shipment ride for Order #$orderNo.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'User',
          );
        } catch (_) {}
      }

      if (!isClosed) {
        emit(DriverOffersActionSuccessState(
          "Accepted assignment for Order #$orderNo! Active ride started.",
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(DriverOffersErrorState("Failed to accept offer: ${e.toString()}"));
      }
    }
  }

  /// Driver rejects a Broker offer from the Driver Home page.
  Future<void> rejectOffer({required Map<String, dynamic> offer}) async {
    try {
      final String currentUid = _auth.currentUser?.uid ?? '';
      final String offerId = (offer['offer_id'] ?? offer['id'] ?? '').toString();
      final String orderId = (offer['order_id'] ?? offer['orderId'] ?? '').toString();
      final String driverId = (offer['driver_id'] ?? offer['driverId'] ?? currentUid).toString();
      final String orderNo = (offer['order_no'] ?? orderId).toString();
      final String brokerId = (offer['broker_id'] ?? offer['brokerId'] ?? '').toString();

      if (offerId.isEmpty || orderId.isEmpty) {
        emit(DriverOffersErrorState("Invalid offer or order reference."));
        return;
      }

      final updateData = {
        'status': 'rejected_by_driver',
        'updated_at': FieldValue.serverTimestamp(),
      };

      try {
        await _firestore
            .collection("Orders")
            .doc(orderId)
            .collection("DriverOffers")
            .doc(offerId)
            .update(updateData);
      } catch (_) {}

      await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId)
          .update(updateData);

      // Also notify/update broker
      if (brokerId.isNotEmpty) {
        try {
          await _firestore
              .collection("Broker")
              .doc(brokerId)
              .collection("IncomingRequests")
              .doc(orderId)
              .update({
            'status': 'accepted', // resets back so broker can reassign
            'assigned_driver_id': null,
            'assigned_driver_name': null,
            'assigned_driver_phone': null,
            'updated_at': FieldValue.serverTimestamp(),
          });
        } catch (_) {}

        // Notify Broker of driver rejection
        try {
          final String notifId = "driver_rej_${orderId}_$driverId";
          final String driverName = (offer['driver_name'] ?? 'Driver').toString();
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: brokerId,
            type: NotificationTypes.driverRejected,
            title: 'Driver Declined Offer',
            body: '$driverName declined the assignment for Order #$orderNo. The shipment is now ready for re-assignment.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'Broker',
          );
        } catch (_) {}
      }

      if (!isClosed) {
        emit(DriverOffersActionSuccessState(
          "Rejected offer for Order #$orderNo.",
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(DriverOffersErrorState("Failed to reject offer: ${e.toString()}"));
      }
    }
  }

  /// Driver taps START RIDE:
  /// Transitions order status to 'in_transit' and begins real GPS tracking.
  Future<void> startRide({required Map<String, dynamic> offer}) async {
    try {
      final String currentUid = _auth.currentUser?.uid ?? '';
      final String offerId = (offer['offer_id'] ?? offer['id'] ?? '').toString();
      final String orderId = (offer['order_id'] ?? offer['orderId'] ?? '').toString();
      final String brokerId = (offer['broker_id'] ?? offer['brokerId'] ?? '').toString();
      final String driverId = (offer['driver_id'] ?? offer['driverId'] ?? currentUid).toString();
      final String userUid = (offer['user_uid'] ?? offer['userUid'] ?? '').toString();
      final String orderNo = (offer['order_no'] ?? orderId).toString();
      final String driverName = (offer['driver_name'] ?? 'Driver').toString();

      // Guard: Status and Driver verification
      if (currentUid.isNotEmpty && driverId.isNotEmpty && currentUid != driverId) {
        emit(DriverOffersErrorState("Unauthorized: Only the assigned driver can start this ride."));
        return;
      }

      final updateData = {
        'status': 'in_transit',
        'ride_started_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // 1. Update Driver ReceivedOffers & Driver availability
      await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId)
          .update(updateData);

      try {
        await _firestore.collection("Driver").doc(driverId).set({
          'availability_status': 'on_ride',
          'vehicle_available': false,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (brokerId.isNotEmpty) {
          await _firestore
              .collection("Broker")
              .doc(brokerId)
              .collection("DriverNetwork")
              .doc(driverId)
              .set({
            'availability_status': 'on_ride',
            'vehicle_available': false,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}

      // 2. Update main Orders
      await _firestore
          .collection("Orders")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      // 3. Update Broker IncomingRequests
      if (brokerId.isNotEmpty) {
        await _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId)
            .update(updateData);

        // Notify Broker
        final String notifId = "ride_start_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: brokerId,
            type: NotificationTypes.tripStarted,
            title: 'Ride In Transit',
            body: '$driverName has started the ride for Order #$orderNo and is travelling towards pickup.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'Broker',
          );
        } catch (_) {}
      }

      // 4. Update User Requests
      if (userUid.isNotEmpty) {
        try {
          await _firestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .update(updateData);
        } catch (_) {}

        // Notify User
        final String notifId = "ride_start_user_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'User',
            recipientId: userUid,
            type: NotificationTypes.tripStarted,
            title: 'Ride In Transit',
            body: 'Driver $driverName has started the ride for Order #$orderNo. Real-time GPS tracking is now live.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'User',
          );
        } catch (_) {}
      }

      // 5. Extract pickup/drop coordinates if present
      final double? pickupLat = (offer['pickup_lat'] ?? offer['pickupLatitude'] ?? offer['pickupLat'] as num?)?.toDouble();
      final double? pickupLng = (offer['pickup_lng'] ?? offer['pickupLongitude'] ?? offer['pickupLng'] as num?)?.toDouble();
      final double? dropLat = (offer['drop_lat'] ?? offer['dropLatitude'] ?? offer['dropLat'] as num?)?.toDouble();
      final double? dropLng = (offer['drop_lng'] ?? offer['dropLongitude'] ?? offer['dropLng'] as num?)?.toDouble();


      // 6. Start Real GPS Live Tracking
      await DriverLocationService().startTracking(
        orderId: orderId,
        driverId: driverId,
        brokerId: brokerId,
        userUid: userUid,
        orderNo: orderNo,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
      );

      if (!isClosed) {
        emit(DriverOffersActionSuccessState("Ride started! Real-time GPS tracking is active."));
      }
    } catch (e) {
      if (!isClosed) {
        emit(DriverOffersErrorState("Failed to start ride: ${e.toString()}"));
      }
    }
  }

  /// Driver confirms cargo collected after reaching pickup
  Future<void> confirmCargoPickedUp({required Map<String, dynamic> offer}) async {
    try {
      final String offerId = (offer['offer_id'] ?? offer['id'] ?? '').toString();
      final String orderId = (offer['order_id'] ?? offer['orderId'] ?? '').toString();
      final String brokerId = (offer['broker_id'] ?? offer['brokerId'] ?? '').toString();
      final String driverId = (offer['driver_id'] ?? offer['driverId'] ?? '').toString();
      final String userUid = (offer['user_uid'] ?? offer['userUid'] ?? '').toString();
      final String orderNo = (offer['order_no'] ?? orderId).toString();
      final String driverName = (offer['driver_name'] ?? 'Driver').toString();

      final updateData = {
        'ride_phase': 'heading_to_drop',
        'cargo_picked_up_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId)
          .set(updateData, SetOptions(merge: true));

      await _firestore
          .collection("Orders")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      if (brokerId.isNotEmpty) {
        await _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId)
            .set(updateData, SetOptions(merge: true));

        // Notify Broker
        final String notifId = "cargo_pk_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: brokerId,
            type: NotificationTypes.tripStarted,
            title: 'Cargo Collected',
            body: '$driverName has loaded the cargo for Order #$orderNo and is heading towards the drop location.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'Broker',
          );
        } catch (_) {}
      }

      if (userUid.isNotEmpty) {
        try {
          await _firestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .set(updateData, SetOptions(merge: true));
        } catch (_) {}

        // Notify User
        final String notifId = "cargo_pk_usr_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'User',
            recipientId: userUid,
            type: NotificationTypes.tripStarted,
            title: 'Cargo On The Way',
            body: 'Your cargo for Order #$orderNo has been collected and is in transit to destination.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'User',
          );
        } catch (_) {}
      }

      if (!isClosed) {
        emit(DriverOffersActionSuccessState("Cargo confirmed! Heading towards drop destination."));
      }
    } catch (e) {
      if (!isClosed) {
        emit(DriverOffersErrorState("Failed to update status: ${e.toString()}"));
      }
    }
  }

  /// Driver taps COMPLETE:
  /// Updates status to 'completed', stops GPS tracking, updates Broker AI metrics, and notifies all parties.
  Future<void> completeRide({required Map<String, dynamic> offer}) async {
    try {
      final String currentUid = _auth.currentUser?.uid ?? '';
      final String offerId = (offer['offer_id'] ?? offer['id'] ?? '').toString();
      final String orderId = (offer['order_id'] ?? offer['orderId'] ?? '').toString();
      final String brokerId = (offer['broker_id'] ?? offer['brokerId'] ?? '').toString();
      final String driverId = (offer['driver_id'] ?? offer['driverId'] ?? currentUid).toString();
      final String userUid = (offer['user_uid'] ?? offer['userUid'] ?? '').toString();
      final String orderNo = (offer['order_no'] ?? orderId).toString();
      final String driverName = (offer['driver_name'] ?? 'Driver').toString();

      // Guard: Only assigned driver can complete
      if (currentUid.isNotEmpty && driverId.isNotEmpty && currentUid != driverId) {
        emit(DriverOffersErrorState("Unauthorized: Only the assigned driver can complete this ride."));
        return;
      }

      // 1. Stop active GPS tracking immediately
      await DriverLocationService().stopTracking();

      int? durationSeconds;
      final rawStarted = offer['ride_started_at'];
      if (rawStarted is Timestamp) {
        durationSeconds = DateTime.now().difference(rawStarted.toDate()).inSeconds;
      }

      final Map<String, dynamic> updateData = {
        'status': 'completed',
        'ride_phase': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        if (durationSeconds != null && durationSeconds > 0)
          'delivery_duration_seconds': durationSeconds,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // 2. Update Driver ReceivedOffers
      await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId)
          .update(updateData);

      // 3. Update Driver profile trips and availability
      try {
        await _firestore.collection("Driver").doc(driverId).set({
          'completed_trips': FieldValue.increment(1),
          'total_trips': FieldValue.increment(1),
          'availability_status': 'online',
          'vehicle_available': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (brokerId.isNotEmpty) {
          await _firestore
              .collection("Broker")
              .doc(brokerId)
              .collection("DriverNetwork")
              .doc(driverId)
              .set({
            'completed_trips': FieldValue.increment(1),
            'total_trips': FieldValue.increment(1),
            'availability_status': 'online',
            'vehicle_available': true,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}

      // 4. Update main Orders
      await _firestore
          .collection("Orders")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      // 5. Update Broker IncomingRequests & atomically calculate AI stats
      if (brokerId.isNotEmpty) {
        await _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId)
            .update(updateData);


        // Atomically update Broker completion metrics
        try {
          await _firestore.runTransaction((txn) async {
            final brokerRef = _firestore.collection('Broker').doc(brokerId);
            final snap = await txn.get(brokerRef);
            final data = snap.data() ?? {};

            final int total = (data['total_requests'] as num?)?.toInt() ?? 0;
            final int accepted = (data['accepted_requests'] as num?)?.toInt() ?? 0;
            final int cancelled = (data['cancelled_requests'] as num?)?.toInt() ?? 0;
            final int completed = ((data['completed_requests'] as num?)?.toInt() ?? 0) + 1;

            final double acceptanceRate = total > 0 ? (accepted / total) * 100.0 : 0.0;
            final double cancellationRate = total > 0 ? (cancelled / total) * 100.0 : 0.0;
            final double completionRate = accepted > 0 ? (completed / accepted) * 100.0 : 0.0;

            txn.set(
              brokerRef,
              {
                'completed_requests': completed,
                'total_requests': total,
                'accepted_requests': accepted,
                'cancelled_requests': cancelled,
                'acceptance_rate': acceptanceRate,
                'cancellation_rate': cancellationRate,
                'completion_rate': completionRate,
                'broker_id': brokerId,
              },
              SetOptions(merge: true),
            );
          });
        } catch (e) {
          debugPrint("Broker stats update error: $e");
        }
        // Notify Broker
        final String notifId = "comp_broker_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: brokerId,
            type: NotificationTypes.tripCompleted,
            title: 'Order Completed',
            body: '$driverName has successfully completed delivery for Order #$orderNo.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'Broker',
          );
        } catch (_) {}
      }

      // 6. Update User Requests & notify user
      if (userUid.isNotEmpty) {
        try {
          await _firestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .update(updateData);
        } catch (_) {}

        final String notifId = "comp_user_${orderId}_$driverId";
        try {
          await NotificationService().sendNotification(
            targetCollection: 'User',
            recipientId: userUid,
            type: NotificationTypes.tripCompleted,
            title: 'Order Delivered & Completed',
            body: 'Your shipment for Order #$orderNo has been successfully delivered and completed.',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: driverId,
            senderName: driverName,
            receiverRole: 'User',
          );
        } catch (_) {}
      }

      if (!isClosed) {
        emit(DriverOffersActionSuccessState("Order #$orderNo marked as Completed ✓"));
      }
    } catch (e) {
      if (!isClosed) {
        emit(DriverOffersErrorState("Failed to complete ride: ${e.toString()}"));
      }
    }
  }

  void stopListening() {
    _offersSubscription?.cancel();
    _offersSubscription = null;
  }

  @override
  Future<void> close() {
    _offersSubscription?.cancel();
    return super.close();
  }
}
