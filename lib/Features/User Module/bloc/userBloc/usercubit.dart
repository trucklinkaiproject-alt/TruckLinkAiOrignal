// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/userstate.dart';

// // class UserCubit extends Cubit<UserState> {
// //   UserCubit() : super(UserInitialState());

// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //   final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
// //   String userName = '';
// //   String userId ='';
// //   Future<void> fetchUserData() async {
// //     try {
// //       emit(UserLoadingState());
// //       userId= _auth.currentUser!.uid;
// //       DocumentSnapshot userDoc = await firebaseFirestore
// //           .collection('User')
// //           .doc(userId)
// //           .get();
// //        userName = userDoc['name'];

// //       emit(UserLoadedState(userName,userId));
// //     } catch (e) {
// //       emit(UserErrorState("Failed to fetch user data"));
// //     }
// //   }
// // }

// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Features/User Module/bloc/userBloc/userstate.dart';

// class UserCubit extends Cubit<UserState> {
//   UserCubit() : super(UserInitialState());

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;

//   String userName = "";
//   String userId = "";

//   StreamSubscription<QuerySnapshot>? _offerListener;

//   Future<void> fetchUserData() async {
//     try {
//       emit(UserLoadingState());

//       userId = _auth.currentUser!.uid;

//       final userDoc =
//           await firestore.collection("User").doc(userId).get();

//       userName = userDoc["name"];

//       emit(UserLoadedState(userName, userId));

//       listenBrokerOffers();
//     } catch (e) {
//       emit(UserErrorState(e.toString()));
//     }
//   }

//   /// Listen all offers made to this user
//   void listenBrokerOffers() {
//     _offerListener?.cancel();

//     _offerListener = firestore
//         .collection("User")
//       .doc(userId)
//       .collection("Requests")
//       .where("status", isEqualTo: "fare_offered")
//       .snapshots()
//         .listen((snapshot) {
//       if (snapshot.docs.isEmpty) return;

//       final data = snapshot.docs.first.data();

//       emit(BrokerOfferState({
//         ...data,
//         "requestId": snapshot.docs.first.id,
//       }));
//     });
//   }

//   Future<void> acceptOffer(String requestId) async {
//     await firestore.collection("User").doc(userId).collection("Requests").doc(requestId).update({
//       "status": "accepted",
//     });

//     emit(UserLoadedState(userName, userId));
//   }

//   Future<void> rejectOffer(String requestId) async {
//     await firestore.collection("User").doc(userId).collection("Requests").doc(requestId).update({
//       "status": "rejected",
//     });
//     // await  firestore
//     //     .collection("Broker")
//     //     .doc(brokerId)
//     //     .collection("IncomingRequests")
//     //     .doc(widget.orderReqData["orderId"])
//     //     .update({"brokerOffer": amount, "status": "fare_offered"});

//     emit(UserLoadedState(userName, userId));
//   }

//   @override
//   Future<void> close() {
//     _offerListener?.cancel();
//     return super.close();
//   }
// }

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

  /// Listen for broker offers
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

  /// Accept broker offer
  Future<void> acceptOffer(String requestId) async {
    try {
      await firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId)
          .update({"status": "accepted"});


          await firestore
          .collectionGroup("IncomingRequests")
          .where(FieldPath.documentId, isEqualTo: requestId)
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.update({"status": "accepted"});
            }
          });

      if (!isClosed) {
        emit(UserLoadedState(userName, userId));
      }
    } catch (e) {
      if (!isClosed) {
        emit(UserErrorState(e.toString()));
      }
    }
  }

  /// Reject broker offer
  Future<void> rejectOffer(String requestId) async {
    try {
      await firestore
          .collection("User")
          .doc(userId)
          .collection("Requests")
          .doc(requestId)
          .update({"status": "rejected"});

      await firestore
          .collectionGroup("IncomingRequests")
          .where(FieldPath.documentId, isEqualTo: requestId)
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.update({"status": "rejected"});
            }
          });

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
