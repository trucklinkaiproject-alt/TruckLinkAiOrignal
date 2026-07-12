// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetailState.dart';
// // class OrderDetailCubit extends Cubit<OrderDetailState> {
// //   OrderDetailCubit() : super(OrderDetailInitialState());

// //   final FirebaseFirestore firestore = FirebaseFirestore.instance;

// //   Future<void> fetchOrderDetails(
// //   String userID, {
// //   String? status,
// // }) async {
// //   emit(OrderDetailLoadingState());

// //   try {
// //     Query<Map<String, dynamic>> query = firestore
// //         .collection("User")
// //         .doc(userID)
// //         .collection("Requests");

// //     if (status != null) {
// //       query = query.where("status", isEqualTo: status);
// //     }

// //     final snapshot = await query.get();

// //     emit(
// //       OrderDetailLoadedState(
// //         snapshot.docs.map((doc) {
// //           return {
// //             ...doc.data(),
// //             "id": doc.id,
// //           };
// //         }).toList(),
// //       ),
// //     );
// //   } catch (e) {
// //     emit(OrderDetailErrorState(e.toString()));
// //   }
// // }
// // }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetailState.dart';

// class OrderDetailCubit extends Cubit<OrderDetailState> {
//   OrderDetailCubit() : super(OrderDetailInitialState());

//   final FirebaseFirestore firestore = FirebaseFirestore.instance;

//   Future<void> fetchOrderDetails(
//     String userID, {
//     String? status,
//   }) async {
//     if (isClosed) return;
//     emit(OrderDetailLoadingState());

//     try {
//       Query<Map<String, dynamic>> query = firestore
//           .collection("User")
//           .doc(userID)
//           .collection("Requests");

//       if (status != null) {
//         query = query.where("status", isEqualTo: status);
//       }

//       final snapshot = await query.get();

//       // The cubit may have been closed (e.g. user navigated away) while
//       // this Future was awaiting Firestore — guard before emitting.
//       if (isClosed) return;

//       emit(
//         OrderDetailLoadedState(
//           snapshot.docs.map((doc) {
//             return {
//               ...doc.data(),
//               "id": doc.id,
//             };
//           }).toList(),
//         ),
//       );
//     } catch (e) {
//       if (isClosed) return;
//       emit(OrderDetailErrorState(e.toString()));
//     }
//   }
// }

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetailState.dart';

class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit() : super(OrderDetailInitialState());

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  void fetchOrderDetails(
    String userID, {
    String? status,
  }) {
    if (isClosed) return;

    emit(OrderDetailLoadingState());

    // Cancel any existing listener before starting a new one
    _subscription?.cancel();

    Query<Map<String, dynamic>> query = firestore
        .collection("User")
        .doc(userID)
        .collection("Requests");

    if (status != null) {
      query = query.where("status", isEqualTo: status);
    }

    _subscription = query.snapshots().listen(
      (snapshot) {
        if (isClosed) return;

        emit(
          OrderDetailLoadedState(
            snapshot.docs.map((doc) {
              return {
                ...doc.data(),
                "id": doc.id,
              };
            }).toList(),
          ),
        );
      },
      onError: (e) {
        if (!isClosed) {
          emit(OrderDetailErrorState(e.toString()));
        }
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}