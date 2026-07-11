// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/getBrokerOrderDetail/getBrokerOrderDetailStates.dart';

// class GetBrokerOrderDetailCubit extends Cubit<GetBrokerOrderDetailState> {
//   GetBrokerOrderDetailCubit() : super(GetBrokerOrderDetailInitialState());

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<Map<String,dynamic>> orderDetails = [];

//   Future<void> fetchAllBrokerOrderDetails(String brokerId,String status) async {
//     try {
//       emit(GetBrokerOrderDetailLoadingState());

//       QuerySnapshot snapshot = await _firestore
//           .collection("Brokers").doc(brokerId).collection("IncomingRequests")
//           .where("status", isEqualTo: status)
//           .get();

//       orderDetails = await snapshot.docs
//           .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
//           .toList();

//       emit(GetBrokerOrderDetailLoadedState(orderDetails));
//     } catch (e) {
//       emit(GetBrokerOrderDetailErrorState(e.toString()));
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/getBrokerOrderDetail/getBrokerOrderDetailStates.dart';

class GetBrokerOrderDetailCubit extends Cubit<GetBrokerOrderDetailState> {
  GetBrokerOrderDetailCubit() : super(GetBrokerOrderDetailInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchAllBrokerOrderDetails(
    String brokerId,
    String? status,
  ) async {
    try {
      emit(GetBrokerOrderDetailLoadingState());

      Query query = _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests");
      

      // Only filter by status if one was actually provided ("All" tab passes null)
      if (status != null) {
        query = query.where("status", isEqualTo: status);
      }

      final snapshot = await query.get();

      final orderDetails = snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      emit(GetBrokerOrderDetailLoadedState(orderDetails));
    } catch (e) {
      emit(GetBrokerOrderDetailErrorState(e.toString()));
    }
  }
}
