import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerState.dart';

class GetBrokerCubit extends Cubit<GetBrokerState> {
  GetBrokerCubit() : super(GetBrokerInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String,dynamic>> brokers = [];
  Map<String,dynamic> selectedBroker ={};

  Future<void> fetchAllBroker() async {
    try {
      emit(GetBrokerLoadingState());

      QuerySnapshot snapshot = await _firestore.collection("Broker").get();

      brokers = await snapshot.docs
          .map((doc) => {"id": doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      
      emit(GetBrokerLoadedState());
    } catch (e) {
      emit(GetBrokerErrorState(e.toString()));
    }
  }

  
}
