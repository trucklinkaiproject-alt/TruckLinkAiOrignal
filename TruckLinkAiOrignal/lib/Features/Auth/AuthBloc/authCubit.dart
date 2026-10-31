

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Core/Services/fcmTokenService.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerBloc/brokerCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverNetworkBloc/brokerDriverNetworkCubit.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverRequestsBloc/brokerDriverRequestsCubit.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/Services/driverLocationService.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/bloc/driverBloc/driverCubit.dart';
import 'package:trucklinkai_orignal/Features/Driver%20Module/bloc/driverOffersBloc/driverOffersCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerCubit.dart';
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

      // 1.12: Validate role is one of User, Broker, Driver
      if (!['User', 'Broker', 'Driver'].contains(selectedRole)) {
        emit(AuthFailure("Invalid role selected. Must be User, Broker, or Driver."));
        return;
      }

      // 1.8: Password policy - minimum 8 characters
      if (password.length < 8) {
        emit(AuthFailure("Password must be at least 8 characters long."));
        return;
      }

      // 1.8: Email format validation
      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
      if (!emailRegex.hasMatch(email.trim())) {
        emit(AuthFailure("Please enter a valid email address."));
        return;
      }

      // 1.8: Phone validation (at least 10 digits)
      final phoneDigits = phone.replaceAll(RegExp(r'\D'), '');
      if (phoneDigits.length < 10) {
        emit(AuthFailure("Please enter a valid phone number (at least 10 digits)."));
        return;
      }

      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email.trim(), password: password);

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

      // 1.7: Sign in FIRST, then verify role — never query Firestore before auth.
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        emit(AuthFailure("Authentication failed. Please try again."));
        return;
      }

      // Refresh to get current emailVerified status
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await _auth.signOut();
        emit(AuthEmailNotVerified(email));
        return;
      }

      // Verify role doc exists for this UID
      final roleDoc = await firebaseFirestore
          .collection(role)
          .doc(user.uid)
          .get();

      if (!roleDoc.exists) {
        await _auth.signOut();
        emit(AuthFailure("No account found for this role. Please check your selection."));
        return;
      }

      // 1.6: Check blocked status
      final roleData = roleDoc.data() ?? {};
      final status = (roleData['status'] ?? '').toString().toLowerCase();
      if (status == 'blocked') {
        await _auth.signOut();
        emit(AuthFailure("Your account has been suspended. Please contact support."));
        return;
      }

      selectedRole = role;

      // Register device FCM token upon successful login
      try {
        await FcmTokenService().registerToken(uid: user.uid, role: role);
      } catch (_) {}

      emit(AuthSuccess(role: role));
    } on FirebaseAuthException catch (e) {
      // Use a generic message to avoid leaking whether the email exists
      emit(AuthFailure(e.code == 'user-not-found' || e.code == 'wrong-password'
          ? "Invalid email or password."
          : (e.message ?? "An unknown error occurred")));
    } catch (e) {
      emit(AuthFailure("An unknown error occurred"));
    }
  }

  /// Resends the email verification link using the already signed-in user.
  /// No password needed — the user was just signed up and is still authenticated.
  Future<void> resendVerificationEmail() async {
    try {
      emit(AuthLoading());
      final user = _auth.currentUser;
      if (user == null) {
        emit(AuthFailure("Session expired. Please sign up again."));
        return;
      }
      await user.sendEmailVerification();
      emit(AuthVerificationEmailSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? "Failed to resend verification email"));
    } catch (e) {
      emit(AuthFailure("Failed to resend verification email"));
    }
  }

  /// Checks email verification status using the already signed-in user.
  /// No password needed — the user is still authenticated from signUp.
  Future<void> checkEmailVerified({
    required String role,
  }) async {
    try {
      emit(AuthLoading());
      final user = _auth.currentUser;
      if (user == null) {
        emit(AuthFailure("Session expired. Please sign up again."));
        return;
      }
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        await _auth.signOut(); // sign out — user must log in properly
        emit(AuthEmailVerified(refreshedUser.email ?? ''));
      } else {
        emit(AuthEmailNotVerified(user.email ?? ''));
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

      // 1. Capture cubit references synchronously before any async gap
      final userCubit = context.read<UserCubit>();
      final driverCubit = context.read<DriverCubit>();
      final brokerCubit = context.read<BrokerCubit>();
      final driverOffersCubit = context.read<DriverOffersCubit>();
      final getBrokerCubit = context.read<GetBrokerCubit>();
      final brokerDriverRequestsCubit = context.read<BrokerDriverRequestsCubit>();
      final brokerDriverNetworkCubit = context.read<BrokerDriverNetworkCubit>();

      // Cancel subscriptions and reset state across eager cubits (Phase 3.3)
      try {
        await userCubit.stopListening();
      } catch (e) {
        AppLogger.warn("Failed to stop UserCubit: $e", "AuthCubit");
      }

      try {
        driverCubit.stopListening();
      } catch (e) {
        AppLogger.warn("Failed to stop DriverCubit: $e", "AuthCubit");
      }

      try {
        await brokerCubit.stopListening();
      } catch (e) {
        AppLogger.warn("Failed to stop BrokerCubit: $e", "AuthCubit");
      }

      try {
        driverOffersCubit.stopListening();
      } catch (e) {
        AppLogger.warn("Failed to stop DriverOffersCubit: $e", "AuthCubit");
      }

      try {
        getBrokerCubit.stopListening();
      } catch (e) {
        AppLogger.warn("Failed to stop GetBrokerCubit: $e", "AuthCubit");
      }

      try {
        brokerDriverRequestsCubit.stopListening();
      } catch (e) {
        AppLogger.warn("Failed to stop BrokerDriverRequestsCubit: $e", "AuthCubit");
      }

      try {
        brokerDriverNetworkCubit.stopListening();
      } catch (e) {
        AppLogger.warn("Failed to stop BrokerDriverNetworkCubit: $e", "AuthCubit");
      }

      try {
        DriverLocationService().stopTracking();
      } catch (e) {
        AppLogger.warn("Failed to stop DriverLocationService tracking: $e", "AuthCubit");
      }

      // 2. Clean up current device FCM token
      final currentUid = _auth.currentUser?.uid;
      final roleToClean = selectedRole;
      if (currentUid != null && currentUid.isNotEmpty && roleToClean.isNotEmpty) {
        try {
          await FcmTokenService().removeCurrentDeviceToken(uid: currentUid, role: roleToClean);
        } catch (e) {
          AppLogger.warn("Failed to remove FCM token: $e", "AuthCubit");
        }
      } else if (currentUid != null && currentUid.isNotEmpty) {
        for (final r in ['User', 'Broker', 'Driver']) {
          try {
            await FcmTokenService().removeCurrentDeviceToken(uid: currentUid, role: r);
          } catch (e) {
            AppLogger.warn("Failed to remove FCM token for $r: $e", "AuthCubit");
          }
        }
      }

      selectedRole = '';
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e, stack) {
      AppLogger.error("Logout failed", e, stack, "AuthCubit");
      emit(AuthFailure("An unknown error occurred"));
    }
  }
}
