// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerStates.dart';

// class BrokerCubit extends Cubit<BrokerState> {
//   BrokerCubit() : super(BrokerInitialState());
//   List<Map<String, dynamic>> incomingRequests = [];

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
//   String userName = '';
//   String brokerId = '';
// Future<void> fetchUserData() async {
//   try {
//     emit(BrokerLoadingState());

//     brokerId = _auth.currentUser!.uid;

//     final userDoc = await firebaseFirestore
//         .collection('Broker')
//         .doc(brokerId)
//         .get();

//     userName = userDoc['name'];

//     await fetchIncomingReq();
//   } catch (e) {
//     emit(BrokerErrorState(e.toString()));
//   }
// }
// Future<void> fetchIncomingReq() async {
//   final snapshot = await firebaseFirestore
//       .collection("Broker")
//       .doc(brokerId)
//       .collection("IncomingRequests")
//       .get();

//   incomingRequests = snapshot.docs
//       .map((doc) => doc.data() )
//       .toList();

//   emit(
//     BrokerLoadedState(
//       userData: userName,
//       uid: brokerId,
//       incomingRequests: incomingRequests,
//     ),
//   );
// }
// }

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
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
        .snapshots()
        .listen(
      (snapshot) {
        // Filter incoming requests so ONLY status == 'pending' appears on the Broker Main Page
        incomingRequests = snapshot.docs
            .map((doc) => {"orderId": doc.id, ...doc.data()})
            .where((doc) {
              final status = (doc['status'] ?? '').toString().toLowerCase();
              return status == 'pending';
            })
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
    } catch (_) {}
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

      // 1. Update Broker/brokerId/IncomingRequests/orderId
      await firebaseFirestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .update(updatePayload);

      // 2. Update User/userUid/Requests/orderId (if doc exists)
      if (userUid.isNotEmpty) {
        try {
          await firebaseFirestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .update(updatePayload);
        } catch (_) {}

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
        } catch (_) {}
      }

      // 3. Update main Orders/orderId (if doc exists)
      try {
        await firebaseFirestore
            .collection("Orders")
            .doc(orderId)
            .update(updatePayload);
      } catch (_) {}

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
      } catch (_) {}

      // ── AI STATS: increment accepted_requests atomically ────────────────
      await firebaseFirestore.runTransaction((txn) async {
        final brokerRef = firebaseFirestore.collection('Broker').doc(brokerId);
        final snap = await txn.get(brokerRef);
        final data = snap.data() ?? {};

        final int total = (data['total_requests'] as num?)?.toInt() ?? 0;
        final int accepted = ((data['accepted_requests'] as num?)?.toInt() ?? 0) + 1;
        final int cancelled = (data['cancelled_requests'] as num?)?.toInt() ?? 0;
        final int completed = (data['completed_requests'] as num?)?.toInt() ?? 0;

        final double acceptanceRate = total > 0 ? (accepted / total) * 100.0 : 0.0;
        final double cancellationRate = total > 0 ? (cancelled / total) * 100.0 : 0.0;
        final double completionRate = accepted > 0 ? (completed / accepted) * 100.0 : 0.0;

        txn.set(
          brokerRef,
          {
            'accepted_requests': accepted,
            'total_requests': total,
            'cancelled_requests': cancelled,
            'completed_requests': completed,
            'acceptance_rate': acceptanceRate,
            'cancellation_rate': cancellationRate,
            'completion_rate': completionRate,
            'broker_rating': (data['broker_rating'] as num?)?.toDouble() ?? 0.0,
            'broker_id': brokerId,
          },
          SetOptions(merge: true),
        );
      });
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

      // 1. Update Broker/brokerId/IncomingRequests/orderId
      await firebaseFirestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .update(updatePayload);

      // 2. Update User/userUid/Requests/orderId (if doc exists)
      if (userUid.isNotEmpty) {
        try {
          await firebaseFirestore
              .collection("User")
              .doc(userUid)
              .collection("Requests")
              .doc(orderId)
              .update(updatePayload);
        } catch (_) {}
      }

      // 3. Update main Orders/orderId (if doc exists)
      try {
        await firebaseFirestore
            .collection("Orders")
            .doc(orderId)
            .update(updatePayload);
      } catch (_) {}

      // ── AI STATS: increment cancelled_requests atomically ────────────────
      await firebaseFirestore.runTransaction((txn) async {
        final brokerRef = firebaseFirestore.collection('Broker').doc(brokerId);
        final snap = await txn.get(brokerRef);
        final data = snap.data() ?? {};

        final int total = (data['total_requests'] as num?)?.toInt() ?? 0;
        final int accepted = (data['accepted_requests'] as num?)?.toInt() ?? 0;
        final int cancelled = ((data['cancelled_requests'] as num?)?.toInt() ?? 0) + 1;
        final int completed = (data['completed_requests'] as num?)?.toInt() ?? 0;

        final double acceptanceRate = total > 0 ? (accepted / total) * 100.0 : 0.0;
        final double cancellationRate = total > 0 ? (cancelled / total) * 100.0 : 0.0;
        final double completionRate = accepted > 0 ? (completed / accepted) * 100.0 : 0.0;

        txn.set(
          brokerRef,
          {
            'cancelled_requests': cancelled,
            'total_requests': total,
            'accepted_requests': accepted,
            'completed_requests': completed,
            'acceptance_rate': acceptanceRate,
            'cancellation_rate': cancellationRate,
            'completion_rate': completionRate,
            'broker_rating': (data['broker_rating'] as num?)?.toDouble() ?? 0.0,
            'broker_id': brokerId,
          },
          SetOptions(merge: true),
        );
      });
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
        } catch (_) {}
      }

      // 3. Update main Orders collection (if exists)
      try {
        await firebaseFirestore
            .collection("Orders")
            .doc(orderId)
            .update(updatePayload);
      } catch (_) {}

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
      } catch (_) {}

      // ── AI STATS: increment completed_requests atomically ────────────────
      // Transaction prevents double-counting if this is called multiple times.
      await firebaseFirestore.runTransaction((txn) async {
        final brokerRef = firebaseFirestore.collection('Broker').doc(brokerId);
        final snap = await txn.get(brokerRef);
        final data = snap.data() ?? {};

        final int total = (data['total_requests'] as num?)?.toInt() ?? 0;
        final int accepted = (data['accepted_requests'] as num?)?.toInt() ?? 0;
        final int cancelled = (data['cancelled_requests'] as num?)?.toInt() ?? 0;
        final int completed = ((data['completed_requests'] as num?)?.toInt() ?? 0) + 1;

        final double acceptanceRate = total > 0 ? (accepted / total) * 100.0 : 0.0;
        final double cancellationRate = total > 0 ? (cancelled / total) * 100.0 : 0.0;
        // completion_rate = completed / accepted — measures delivery success rate
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
            'broker_rating': (data['broker_rating'] as num?)?.toDouble() ?? 0.0,
            'broker_id': brokerId,
          },
          SetOptions(merge: true),
        );
      });
      // ────────────────────────────────────────────────────────────────────
    } catch (e) {
      emit(BrokerErrorState("Failed to complete order: ${e.toString()}"));
    }
  }

  @override
  Future<void> close() {
    _incomingReqSubscription?.cancel();
    return super.close();
  }
}