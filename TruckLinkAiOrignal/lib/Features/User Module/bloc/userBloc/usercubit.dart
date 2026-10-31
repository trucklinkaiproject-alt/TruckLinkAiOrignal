import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Features/User Module/bloc/userBloc/userstate.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserInitialState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String userName = "";
  String userId = "";


  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _offerListener;

  bool _isListening = false;

  /// Fetch logged-in user information
  Future<void> fetchUserData() async {
    try {
      if (isClosed) return;

      emit(UserLoadingState());

      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        if (!isClosed) {
          emit(UserErrorState("No authenticated user found."));
        }
        return;
      }

      userId = currentUser.uid;

      final userDoc = await firestore.collection("User").doc(userId).get();
      
      

      if (!userDoc.exists) {
        if (!isClosed) {
          emit(UserErrorState("User document not found."));
        }
        return;
      }

      final data = userDoc.data();

      userName = data?["name"] ?? "";

      if (!isClosed) {
        emit(UserLoadedState(userName, userId));
      }

      if (!_isListening) {
        _isListening = true;
        _listenBrokerOffers();
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserErrorState(e.toString()));
      }
    }
  }

  void _listenBrokerOffers() {
    _offerListener?.cancel();

    _offerListener = firestore
        .collection("User")
        .doc(userId)
        .collection("Requests")
        .where("status", isEqualTo: "fare_offered")
        .limit(20)
        .snapshots()
        .listen(
          (snapshot) {
            if (isClosed) return;

            if (snapshot.docs.isEmpty) {
              if (state is BrokerOfferState) {
                emit(UserLoadedState(userName, userId, pendingOffers: const []));
              }
              return;
            }

            final offers = snapshot.docs
                .map((d) => {...d.data(), "requestId": d.id, "orderId": d.id})
                .toList();

            emit(BrokerOfferState(
              userName: userName,
              uid: userId,
              offers: offers,
              requestData: offers.first,
            ));
          },
          onError: (error) {
            if (!isClosed) {
              emit(UserErrorState(error.toString()));
            }
          },
        );
  }

  Future<void> acceptOffer(String requestId) async {
    try {
      final requestDoc = await firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId)
          .get();

      final data = requestDoc.data() ?? {};
      final String brokerId = (data["brokerId"] ?? data["broker_id"] ?? "").toString();
      final String orderNo = (data["orderNo"] ?? requestId).toString();
      final num agreedFare = data["customer_fare"] ??
          data["customerFare"] ??
          data["accepted_fare"] ??
          data["quoteAmount"] ??
          data["brokerOffer"] ??
          data["fare"] ??
          0;

      final updatePayload = {
        "status": "accepted",
        "customer_fare": agreedFare,
        "customerFare": agreedFare,
        "accepted_fare": agreedFare,
        "accepted_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();

      // 1. User request
      final userReqRef = firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId);
      batch.set(userReqRef, updatePayload, SetOptions(merge: true));

      // 2. Broker incoming request
      if (brokerId.isNotEmpty) {
        final brokerReqRef = firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(requestId);
        batch.set(brokerReqRef, updatePayload, SetOptions(merge: true));
      }

      // 3. Central root Orders document
      final orderRef = firestore.collection("Orders").doc(requestId);
      batch.set(orderRef, updatePayload, SetOptions(merge: true));

      await batch.commit();

      if (brokerId.isNotEmpty) {
        // Notify Broker of quote acceptance
        try {
          final String notifId = "quote_acc_${requestId}_$userId";
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: brokerId,
            type: NotificationTypes.requestAccepted,
            title: 'Quote Accepted',
            body: 'Shipper $userName has accepted your quote of PKR ${agreedFare.toStringAsFixed(0)} for Order #$orderNo.',
            notificationId: notifId,
            orderId: requestId,
            orderNo: orderNo,
            senderId: userId,
            senderName: userName,
            receiverRole: 'Broker',
            additionalData: {
              'customer_fare': agreedFare,
            },
          );
        } catch (e, stack) {
          AppLogger.error("Failed to send quote accepted notification", e, stack, "UserCubit");
        }
      }

      if (!isClosed) {
        emit(UserLoadedState(userName, userId));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserErrorState(e.toString()));
      }
    }
  }

  Future<void> rejectOffer(String requestId) async {
    try {
      final requestDoc = await firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId)
          .get();

      final data = requestDoc.data() ?? {};
      final String brokerId = (data["brokerId"] ?? data["broker_id"] ?? "").toString();
      final String orderNo = (data["orderNo"] ?? requestId).toString();

      final updatePayload = {
        "status": "rejected",
        "rejected_at": FieldValue.serverTimestamp(),
        "updated_at": FieldValue.serverTimestamp(),
      };

      final batch = firestore.batch();

      // 1. User request
      final userReqRef = firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId);
      batch.set(userReqRef, updatePayload, SetOptions(merge: true));

      // 2. Broker incoming request
      if (brokerId.isNotEmpty) {
        final brokerReqRef = firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(requestId);
        batch.set(brokerReqRef, updatePayload, SetOptions(merge: true));
      }

      // 3. Central root Orders document
      final orderRef = firestore.collection("Orders").doc(requestId);
      batch.set(orderRef, updatePayload, SetOptions(merge: true));

      await batch.commit();

      if (brokerId.isNotEmpty) {
        // Notify Broker of quote rejection
        try {
          final String notifId = "quote_rej_${requestId}_$userId";
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: brokerId,
            type: NotificationTypes.requestRejected,
            title: 'Quote Declined',
            body: 'Shipper $userName has declined your quote for Order #$orderNo.',
            notificationId: notifId,
            orderId: requestId,
            orderNo: orderNo,
            senderId: userId,
            senderName: userName,
            receiverRole: 'Broker',
          );
        } catch (e, stack) {
          AppLogger.error("Failed to send quote rejection notification", e, stack, "UserCubit");
        }
      }

      if (!isClosed) {
        emit(UserLoadedState(userName, userId));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserErrorState(e.toString()));
      }
    }
  }

  Future<void> stopListening() async {
    await _offerListener?.cancel();
    _offerListener = null;
    _isListening = false;
  }

  @override
  Future<void> close() async {
    await _offerListener?.cancel();

    return super.close();
  }
}
