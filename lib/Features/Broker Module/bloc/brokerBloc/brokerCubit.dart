import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerStates.dart';

class BrokerCubit extends Cubit<BrokerState> {
  BrokerCubit() : super(BrokerInitialState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  String userName = '';
  String userId ='';
  Future<void> fetchUserData() async {
    try {
      emit(BrokerLoadingState());
      userId= _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await firebaseFirestore
          .collection('Broker')
          .doc(userId)
          .get();
       userName = userDoc['name'];
       

      emit(BrokerLoadedState(userName,userId));
    } catch (e) {
      emit(BrokerErrorState("Failed to fetch user data"));
    }
  }
}
