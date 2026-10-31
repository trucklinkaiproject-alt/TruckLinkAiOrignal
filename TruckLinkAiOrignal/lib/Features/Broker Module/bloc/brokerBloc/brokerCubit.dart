import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Core/Services/brokerStatsService.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerStates.dart';

class BrokerCubit extends Cubit<BrokerState> {
  BrokerCubit() : super(BrokerInitialState());

  List<Map<String, dynamic>> incomingRequests = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  String userName = '';
  String brokerId = '';

  StreamSubscription<QuerySnapshot>? _incomingReqSubscription;

  Future<void> fetchUserData() async {
    try {
      emit(BrokerLoadingState());

      brokerId = _auth.currentUser!.uid;

      final userDoc = await firebaseFirestore
          .collection('Broker')
          .doc(brokerId)
          .get();

      userName = userDoc['name'];

      fetchIncomingReq(); // no await — this starts a live stream, not a one-off fetch
    } catch (e) {
      emit(BrokerErrorState(e.toString()));
    }
  }

  void fetchIncomingReq() {
    // Cancel any existing listener before starting a new one
    _incomingReqSubscription?.cancel();

    _incomingReqSubscription = firebaseFirestore
        .collection("Broker")
        .doc(brokerId)
        .collection("IncomingRequests")
        .where("status", isEqualTo: "pending")
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        incomingRequests = snapshot.docs
            .map((doc) => {"orderId": doc.id, ...doc.data()})
            .toList();

        emit(
          BrokerLoadedState(
            userData: userName,
            uid: brokerId,
            incomingRequests: incomingRequests,
          ),
        );
      },
      onError: (e) {
        emit(BrokerErrorState(e.toString()));
      },
    );
  }

  /// Updates the Broker's availability status in Firestore (online vs offline)
  Future<void> updateBrokerAvailability(String status) async {
    try {
      final bId = brokerId.isNotEmpty ? brokerId : _auth.currentUser?.uid;
      if (bId == null || bId.isEmpty) return;

      await firebaseFirestore.collection("Broker").doc(bId).set({
        'availability_status': status,
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stack) {
      AppLogger.error("Failed to update broker availability status", e, stack, "BrokerCubit");
    }
  }

  /// Accept a pending request.
  /// Updates status from 'pending' -> 'accepted' across Firestore.
  Future<void> acceptRequest(Map<String, dynamic> requestData) async {
    try {
      final String orderId = (requestData['orderId'] ?? requestData['id'] ?? requestData['orderNo'] ?? '').toString();
      final String userUid = (requestData['userUid'] ?? requestData['user_uid'] ?? '').toString();

      if (orderId.isEmpty) return;

      final updatePayload = {
        'status': 'accepted',
        'accepted_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final batch = firebaseFirestore.batch();

      // 1. Broker/IncomingRequests
      final brokerReqRef = firebaseFirestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId);
      batch.set(brokerReqRef, updatePayload, SetOptions(merge: true));

      // 2. User/Requests
      if (userUid.isNotEmpty) {
        final userReqRef = firebaseFirestore
            .collection("User")
            .doc(userUid)
            .collection("Requests")
            .doc(orderId);
        batch.set(userReqRef, updatePayload, SetOptions(merge: true));
      }

      // 3. Central Orders doc
      final orderRef = firebaseFirestore.collection("Orders").doc(orderId);
      batch.set(orderRef, updatePayload, SetOptions(merge: true));

      await batch.commit();

      if (userUid.isNotEmpty) {
        try {
          final String notifId = "accept_$orderId";
          final num amountNum = requestData['brokerOffer'] ??
              requestData['quoteAmount'] ??
              requestData['fare'] ??
              requestData['assigned_fare'] ??
              0;
          final String brokerNameStr = userName.isNotEmpty
              ? userName
              : (requestData['brokerName'] ?? 'Broker');
          final String orderNo = (requestData['orderNo'] ?? orderId).toString();

          await NotificationService().sendNotification(
            targetCollection: 'User',
            recipientId: userUid,
            type: NotificationTypes.requestAccepted,
            title: 'Request Accepted',
            body: 'Your shipment request has been accepted by $brokerNameStr.\n\nOrder No: #$orderNo\nAccepted Amount: PKR ${amountNum.toStringAsFixed(0)}',
            notificationId: notifId,
            orderId: orderId,
            orderNo: orderNo,
            senderId: brokerId,
            senderName: brokerNameStr,
            receiverRole: 'User',
            additionalData: {
              'broker_name': brokerNameStr,
              'amount': amountNum,
            },
          );
        } catch (e, stack) {
          AppLogger.error("Failed to send accept notification to user", e, stack, "BrokerCubit");
        }
      }

      // 4. Broker notification
      try {
        final String brokerNotifId = "req_acc_$orderId";
        final String orderNo = (requestData['orderNo'] ?? orderId).toString();
        await NotificationService().sendNotification(
          targetCollection: 'Broker',
          recipientId: brokerId,
          type: NotificationTypes.requestAccepted,
          title: 'Request Accepted',
          body: 'You accepted Order #$orderNo. You can now assign a driver from your network.',
          notificationId: brokerNotifId,
          orderId: orderId,
          orderNo: orderNo,
          senderId: brokerId,
          receiverRole: 'Broker',
        );
      } catch (e, stack) {
        AppLogger.error("Failed to send accept notification to broker", e, stack, "BrokerCubit");
      }

      // ── AI STATS: increment accepted_requests atomically & idempotently ──
      await BrokerStatsService().recordAcceptedRequest(
        brokerId: brokerId,
        orderId: orderId,
      );
      // ────────────────────────────────────────────────────────────────────
    } catch (e) {
      emit(BrokerErrorState("Failed to accept request: ${e.toString()}"));
    }
  }

  /// Reject/Cancel a pending request.
  /// Updates status from 'pending' -> 'rejected' across Firestore.
  Future<void> rejectRequest(Map<String, dynamic> requestData) async {
    try {
      final String orderId = (requestData['orderId'] ?? requestData['id'] ?? requestData['orderNo'] ?? '').toString();
      final String userUid = (requestData['userUid'] ?? requestData['user_uid'] ?? '').toString();

      if (orderId.isEmpty) return;

      final updatePayload = {
        'status': 'rejected',
        'rejected_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      final batch = firebaseFirestore.batch();

      // 1. Broker/IncomingRequests
      final brokerReqRef = firebaseFirestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId);
      batch.set(brokerReqRef, updatePayload, SetOptions(merge: true));

      // 2. User/Requests
      if (userUid.isNotEmpty) {
        final userReqRef = firebaseFirestore
            .collection("User")
            .doc(userUid)
            .collection("Requests")
            .doc(orderId);
        batch.set(userReqRef, updatePayload, SetOptions(merge: true));
      }

      // 3. Central Orders doc
      final orderRef = firebaseFirestore.collection("Orders").doc(orderId);
      batch.set(orderRef, updatePayload, SetOptions(merge: true));

      await batch.commit();

      // ── AI STATS: increment cancelled_requests atomically & idempotently ─
      await BrokerStatsService().recordCancelledRequest(
        brokerId: brokerId,
        orderId: orderId,
        reason: 'broker_rejected',
      );
      // ────────────────────────────────────────────────────────────────────
    } catch (e) {
      emit(BrokerErrorState("Failed to reject request: ${e.toString()}"));
    }
  }

  /// Mark an accepted order as completed.
  /// Updates status to 'completed' across all collections and atomically
  /// increments completed_requests + recalculates all AI rates.
  Future<void> completeOrder(Map<String, dynamic> requestData) async {
    try {
      final String orderId = (requestData['orderId'] ?? requestData['id'] ?? requestData['orderNo'] ?? '').toString();
      final String userUid = (requestData['userUid'] ?? requestData['user_uid'] ?? '').toString();

      if (orderId.isEmpty) return;

      final updatePayload = {
        'status': 'completed',
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // 1. Update Broker IncomingRequests
      await firebaseFirestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .update(updatePayload);

      // 2. Update User Requests (if exists)
      if (userUid.isNotEmpty) {
        try {
          await firebaseFirestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .update(updatePayload);
        } catch (e, stack) {
          AppLogger.error("Failed to update User request on complete", e, stack, "BrokerCubit");
        }
      }

      // 3. Update main Orders collection (if exists)
      try {
        await firebaseFirestore
            .collection("Orders")
            .doc(orderId)
            .update(updatePayload);
      } catch (e, stack) {
        AppLogger.error("Failed to update Orders doc on complete", e, stack, "BrokerCubit");
      }

      // 4. Broker notification
      try {
        final String brokerNotifId = "order_comp_$orderId";
        final String orderNo = (requestData['orderNo'] ?? orderId).toString();
        await NotificationService().sendNotification(
          targetCollection: 'Broker',
          recipientId: brokerId,
          type: NotificationTypes.tripCompleted,
          title: 'Order Completed',
          body: 'Order #$orderNo has been marked as completed.',
          notificationId: brokerNotifId,
          orderId: orderId,
          orderNo: orderNo,
          senderId: brokerId,
          receiverRole: 'Broker',
        );
      } catch (e, stack) {
        AppLogger.error("Failed to send complete notification to broker", e, stack, "BrokerCubit");
      }

      // ── AI STATS: increment completed_requests atomically & idempotently (Phase 2.1 & Phase 5) ──
      await BrokerStatsService().recordCompletedRequest(
        brokerId: brokerId,
        orderId: orderId,
        itemType: (requestData['itemType'] ?? requestData['item_type'])?.toString(),
      );
      // ────────────────────────────────────────────────────────────────────
    } catch (e) {
      emit(BrokerErrorState("Failed to complete order: ${e.toString()}"));
    }
  }

  Future<void> stopListening() async {
    await _incomingReqSubscription?.cancel();
    _incomingReqSubscription = null;
    incomingRequests.clear();
    userName = '';
    brokerId = '';
    if (!isClosed) emit(BrokerInitialState());
  }

  @override
  Future<void> close() {
    _incomingReqSubscription?.cancel();
    return super.close();
  }
}