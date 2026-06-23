import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/userstate.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserInitialState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  String userName = '';
  String userId ='';
  Future<void> fetchUserData() async {
    try {
      emit(UserLoadingState());
      userId= _auth.currentUser!.uid;
      DocumentSnapshot userDoc = await firebaseFirestore
          .collection('User')
          .doc(userId)
          .get();
       userName = userDoc['name'];
       

      emit(UserLoadedState(userName,userId));
    } catch (e) {
      emit(UserErrorState("Failed to fetch user data"));
    }
  }
}
