

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