

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trucklinkai_orignal/Core/Services/fcmTokenService.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/userBloc/usercubit.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverBloc/driverCubit.dart';
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

     
      Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': selectedRole,
        'uid': userCredential.user!.uid,
      };

      if (selectedRole == 'Driver') {
        userData.addAll({
          'driver_id': userCredential.user!.uid,
          'broker_id': null,
          'driver_latitude': null,
          'driver_longitude': null,
          'vehicle_type': null,
          'vehicle_available': false,
          'driver_rating': 0.0,
          'total_trips': 0,
          'completed_trips': 0,
          'cancelled_trips': 0,
        });
      }

      if (selectedRole == 'Broker') {
        // Initialize all AI training feature fields for new Broker accounts.
        // These are maintained automatically by the system — never manually edited.
        userData.addAll({
          'broker_id': userCredential.user!.uid,
          'broker_rating': 0.0,
          'acceptance_rate': 0.0,
          'completion_rate': 0.0,
          'cancellation_rate': 0.0,
          'total_requests': 0,
          'accepted_requests': 0,
          'completed_requests': 0,
          'cancelled_requests': 0,
        });
      }

      await firebaseFirestore
          .collection(selectedRole)
          .doc(userCredential.user!.uid)
          .set(userData);

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

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Refresh currentUser state to verify email verification status
      final user = userCredential.user;
      if (user != null) {
        await user.reload();
        final refreshedUser = _auth.currentUser;
        if (refreshedUser != null && !refreshedUser.emailVerified) {
          await _auth.signOut();
          emit(AuthEmailNotVerified(email));
          return;
        }
      }

      // Register device FCM token upon successful login
      if (user != null) {
        try {
          await FcmTokenService().registerToken(uid: user.uid, role: role);
        } catch (_) {}
      }

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
        emit(AuthEmailVerified(email));
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
      final userCubit = context.read<UserCubit>();
      final driverCubit = context.read<DriverCubit>();
      emit(AuthLoading());
      try {
        await userCubit.stopListening();
      } catch (_) {}
      try {
        driverCubit.stopListening();
      } catch (_) {}

      // Clean up current device FCM token
      final currentUid = _auth.currentUser?.uid;
      final roleToClean = selectedRole;
      if (currentUid != null && currentUid.isNotEmpty && roleToClean.isNotEmpty) {
        try {
          await FcmTokenService().removeCurrentDeviceToken(uid: currentUid, role: roleToClean);
        } catch (_) {}
      } else if (currentUid != null && currentUid.isNotEmpty) {
        for (final r in ['User', 'Broker', 'Driver']) {
          try {
            await FcmTokenService().removeCurrentDeviceToken(uid: currentUid, role: r);
          } catch (_) {}
        }
      }

      selectedRole = '';
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure("An unknown error occurred"));
    }
  }
}
