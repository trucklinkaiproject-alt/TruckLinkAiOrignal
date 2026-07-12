

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';
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

  Future<void> sendPasswordResetEmail({required String email}) async {
  try {
    emit(AuthLoading());
    await _auth.sendPasswordResetEmail(email: email);
    emit(AuthPasswordResetEmailSent());
  } on FirebaseAuthException catch (e) {
    emit(AuthFailure(e.message ?? "Failed to send reset email"));
  } catch (e) {
    emit(AuthFailure("Failed to send reset email"));
  }
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

      await userCredential.user?.sendEmailVerification();

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

      await _auth.signOut();

      emit(AuthEmailNotVerified(email));
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

      if (role.isEmpty) {
        emit(AuthFailure("Please select a role"));
        return;
      }

      final snapshot = await firebaseFirestore
          .collection(role)
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        emit(AuthFailure("No user found with this role"));
        return;
      }

       await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // await userCredential.user?.reload();
      // final refreshedUser = _auth.currentUser;

      // if (refreshedUser != null && !refreshedUser.emailVerified) {
      //   await _auth.signOut();
      //   emit(AuthEmailNotVerified(email));
      //   return;
      // }

      emit(AuthSuccess(role: role));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? "An unknown error occurred"));
    } catch (e) {
      emit(AuthFailure("An unknown error occurred"));
    }
  }

  Future<void> resendVerificationEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();
      await _auth.signOut();

      emit(AuthVerificationEmailSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? "Failed to resend verification email"));
    } catch (e) {
      emit(AuthFailure("Failed to resend verification email"));
    }
  }


  Future<void> checkEmailVerified({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      emit(AuthLoading());

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        emit(AuthSuccess(role: role));
      } else {
        await _auth.signOut();
        emit(AuthEmailNotVerified(email));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? "An unknown error occurred"));
    } catch (e) {
      emit(AuthFailure("An unknown error occurred"));
    }
  }

Future<void> cancelSignUp({
  required String email,
  required String password,
}) async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user?.uid;

    if (uid != null && selectedRole.isNotEmpty) {
      await firebaseFirestore.collection(selectedRole).doc(uid).delete();
    }

    await userCredential.user?.delete();

    emit(AuthInitial());
  } on FirebaseAuthException catch (e) {
    emit(AuthFailure(e.message ?? "Failed to cancel signup"));
  } catch (e) {
    emit(AuthFailure("Failed to cancel signup"));
  }
}
  Future<void> logOut(BuildContext context) async {
    try {
      emit(AuthLoading());
      await context.read<UserCubit>().stopListening();
      await _auth.signOut();
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure("An unknown error occurred"));
    }
  }
}
