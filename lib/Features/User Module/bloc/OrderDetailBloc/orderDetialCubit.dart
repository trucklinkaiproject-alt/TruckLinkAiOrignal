import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/OrderDetailBloc/orderDetailState.dart';
class OrderDetailCubit extends Cubit<OrderDetailState> {
  OrderDetailCubit() : super(OrderDetailInitialState());

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> fetchOrderDetails(
  String userID, {
  String? status,
}) async {
  emit(OrderDetailLoadingState());

  try {
    Query<Map<String, dynamic>> query = firestore
        .collection("User")
        .doc(userID)
        .collection("Requests");

    if (status != null) {
      query = query.where("status", isEqualTo: status);
    }

    final snapshot = await query.get();

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
  } catch (e) {
    emit(OrderDetailErrorState(e.toString()));
  }
}
}