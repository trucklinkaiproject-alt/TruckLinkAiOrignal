import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        .snapshots()
        .listen(
          (snapshot) {
            if (isClosed) return;

            if (snapshot.docs.isEmpty) return;

            final doc = snapshot.docs.first;

            emit(BrokerOfferState({...doc.data(), "requestId": doc.id}));
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

      final String brokerId = requestDoc["brokerId"] as String;

      await firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId)
          .update({"status": "accepted"});

      await firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(requestId)
          .update({"status": "accepted"});

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
      await firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId)
          .update({"status": "rejected"});

          final requestDoc = await firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId)
          .get();

      final String brokerId = requestDoc["brokerId"] as String;
       await firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(requestId)
          .update({"status": "rejected"});

     
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
