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

  @override
  Future<void> close() {
    _incomingReqSubscription?.cancel();
    return super.close();
  }
}