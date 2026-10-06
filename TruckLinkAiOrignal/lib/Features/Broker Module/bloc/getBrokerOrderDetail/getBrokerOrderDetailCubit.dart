

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/getBrokerOrderDetail/getBrokerOrderDetailStates.dart';

class GetBrokerOrderDetailCubit extends Cubit<GetBrokerOrderDetailState> {
  GetBrokerOrderDetailCubit() : super(GetBrokerOrderDetailInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _subscription;

  void fetchAllBrokerOrderDetails(String brokerId, String? status) {
    emit(GetBrokerOrderDetailLoadingState());


    _subscription?.cancel();

    Query query = _firestore
        .collection("Broker")
        .doc(brokerId)
        .collection("IncomingRequests");


    if (status != null && status.isNotEmpty) {
      final s = status.toLowerCase();
      if (s == 'pending') {
        query = query.where("status", whereIn: ["pending", "Pending"]);
      } else if (s == 'accepted') {
        query = query.where("status", whereIn: ["accepted", "Accepted", "driver_offer_sent", "accepted_by_driver", "in_transit", "in_progress"]);
      } else if (s == 'completed' || s == 'delivered') {
        query = query.where("status", whereIn: ["completed", "Completed", "delivered", "Delivered"]);
      } else if (s == 'rejected' || s == 'cancelled') {
        query = query.where("status", whereIn: ["rejected", "Rejected", "cancelled", "Cancelled"]);
      } else {
        query = query.where("status", isEqualTo: status);
      }
    }

    _subscription = query.snapshots().listen(
      (snapshot) {
        final orderDetails = snapshot.docs
            .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();

        emit(GetBrokerOrderDetailLoadedState(orderDetails));
      },
      onError: (e) {
        emit(GetBrokerOrderDetailErrorState(e.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}