import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'authState.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  String selectedRole = '';

  Future<void> getRoleName(String roleName) async {
    selectedRole = roleName;
    emit(AuthRoleName(roleName));
  }

  Future<void> signUp({
    required String email,
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      //await userCredential.user!.updateDisplayName(name);
      print("selected role: $selectedRole");
      await firebaseFirestore
          .collection(selectedRole)
          .doc(userCredential.user!.uid)
          .set({
            'name': name,
            'email': email,
            'phone': phone,
            'role': selectedRole,
            'uid': userCredential.user!.uid,
          });

      emit(AuthSuccess(role: selectedRole));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? "Auth error"));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> logIn({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      emit(AuthLoading());
      if (role.isNotEmpty) {
        final snapshot = await firebaseFirestore
            .collection(role)
            .where('email', isEqualTo: email)
            .get();

        if (snapshot.docs.isEmpty) {
          emit(AuthFailure("No user found with this role"));
          return;
        }
      } else {
        emit(AuthFailure("Please select a role"));
        return;
      }
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      emit(AuthSuccess(role: role));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? "An unknown error occurred"));
    } catch (e) {
      emit(AuthFailure("An unknown error occurred"));
    }
  }

  Future<void> logOut() async {
    try {
      emit(AuthLoading());
      await _auth.signOut();
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure("An unknown error occurred"));
    }
  }
}
