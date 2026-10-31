import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Core/Services/orderService.dart';
import 'package:trucklinkai_orignal/Core/Services/brokerStatsService.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/Services/driverLocationService.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/bloc/driverOffersBloc/driverOffersState.dart';

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
          .limit(50)
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

      // Atomic batched update across all mirrored Firestore locations
      final batch = _firestore.batch();

      // 1. Orders/{orderId}/DriverOffers/{offerId}
      final offerRef = _firestore
          .collection("Orders")
          .doc(orderId)
          .collection("DriverOffers")
          .doc(offerId);
      batch.set(offerRef, updateData, SetOptions(merge: true));

      // 2. Driver/{driverId}/ReceivedOffers/{offerId}
      final driverOfferRef = _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId);
      batch.set(driverOfferRef, updateData, SetOptions(merge: true));

      // 3. Central root Orders document
      final orderDocRef = _firestore.collection("Orders").doc(orderId);
      batch.set(orderDocRef, updateData, SetOptions(merge: true));

      // 4. Broker/IncomingRequests
      if (brokerId.isNotEmpty) {
        final brokerReqRef = _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId);
        batch.set(brokerReqRef, updateData, SetOptions(merge: true));
      }

      // 5. User/Requests
      if (userUid.isNotEmpty) {
        final userReqRef = _firestore
            .collection("User")
            .doc(userUid)
            .collection("Requests")
            .doc(orderId);
        batch.set(userReqRef, updateData, SetOptions(merge: true));
      }

      await batch.commit();

      // Notify Broker
      if (brokerId.isNotEmpty) {
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
        } catch (e, stack) {
          AppLogger.error("Failed to notify broker of driver acceptance", e, stack, "DriverOffersCubit");
        }
      }

      // Notify User
      if (userUid.isNotEmpty) {
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
        } catch (e, stack) {
          AppLogger.error("Failed to notify user of driver acceptance", e, stack, "DriverOffersCubit");
        }
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

      // Phase 2.6: Reset state atomically across Broker, Orders, and User collections
      final String userUid = (offer['user_uid'] ?? offer['userUid'] ?? '').toString();
      await OrderService().handleDriverOfferRejected(
        orderId: orderId,
        offerId: offerId,
        driverId: driverId,
        brokerId: brokerId,
        userUid: userUid,
      );

      // Notify Broker of driver rejection
      if (brokerId.isNotEmpty) {
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
        } catch (e) {
          debugPrint("Failed to send driver rejected notification: $e");
        }
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

      // Atomic batched update across all mirrored locations
      final batch = _firestore.batch();

      // 1. Update Driver ReceivedOffers
      final driverOfferRef = _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId);
      batch.set(driverOfferRef, updateData, SetOptions(merge: true));

      // 2. Update central Orders doc
      final orderDocRef = _firestore.collection("Orders").doc(orderId);
      batch.set(orderDocRef, updateData, SetOptions(merge: true));

      // 3. Update Broker IncomingRequests
      if (brokerId.isNotEmpty) {
        final brokerReqRef = _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId);
        batch.set(brokerReqRef, updateData, SetOptions(merge: true));
      }

      // 4. Update User Requests
      if (userUid.isNotEmpty) {
        final userReqRef = _firestore
            .collection("User")
            .doc(userUid)
            .collection("Requests")
            .doc(orderId);
        batch.set(userReqRef, updateData, SetOptions(merge: true));
      }

      await batch.commit();

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
      } catch (e, stack) {
        AppLogger.error("Failed to update DriverNetwork availability on ride start", e, stack, "DriverOffersCubit");
      }

      // Notify Broker
      if (brokerId.isNotEmpty) {
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
        } catch (e, stack) {
          AppLogger.error("Failed to notify broker on ride start", e, stack, "DriverOffersCubit");
        }
      }

      // Notify User
      if (userUid.isNotEmpty) {
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
        } catch (e, stack) {
          AppLogger.error("Failed to notify user on ride start", e, stack, "DriverOffersCubit");
        }
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
        } catch (e, stack) {
          AppLogger.error("Failed to notify broker of cargo pickup", e, stack, "DriverOffersCubit");
        }
      }

      if (userUid.isNotEmpty) {
        try {
          await _firestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .set(updateData, SetOptions(merge: true));
        } catch (e, stack) {
          AppLogger.error("Failed to update User request on cargo pickup", e, stack, "DriverOffersCubit");
        }

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
        } catch (e, stack) {
          AppLogger.error("Failed to notify user of cargo pickup", e, stack, "DriverOffersCubit");
        }
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

      // Atomic batched update across all mirrored locations
      final batch = _firestore.batch();

      // 1. Update Driver ReceivedOffers
      final driverOfferRef = _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .doc(offerId);
      batch.set(driverOfferRef, updateData, SetOptions(merge: true));

      // 2. Update central Orders doc
      final orderDocRef = _firestore.collection("Orders").doc(orderId);
      batch.set(orderDocRef, updateData, SetOptions(merge: true));

      // 3. Update Broker IncomingRequests
      if (brokerId.isNotEmpty) {
        final brokerReqRef = _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId);
        batch.set(brokerReqRef, updateData, SetOptions(merge: true));
      }

      // 4. Update User Requests
      if (userUid.isNotEmpty) {
        final userReqRef = _firestore
            .collection("User")
            .doc(userUid)
            .collection("Requests")
            .doc(orderId);
        batch.set(userReqRef, updateData, SetOptions(merge: true));
      }

      await batch.commit();

      // 5. Update Driver profile trips and availability
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
      } catch (e, stack) {
        AppLogger.error("Failed to update DriverNetwork stats on trip completion", e, stack, "DriverOffersCubit");
      }

      // 6. Update Broker completion metrics & item_type_counts
      if (brokerId.isNotEmpty) {
        await BrokerStatsService().recordCompletedRequest(
          brokerId: brokerId,
          orderId: orderId,
          itemType: (offer['itemType'] ?? offer['item_type'])?.toString(),
        );

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
        } catch (e, stack) {
          AppLogger.error("Failed to notify broker on trip completion", e, stack, "DriverOffersCubit");
        }
      }

      // 7. Notify User
      if (userUid.isNotEmpty) {

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
        } catch (e, stack) {
          AppLogger.error("Failed to notify user on trip completion", e, stack, "DriverOffersCubit");
        }
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
