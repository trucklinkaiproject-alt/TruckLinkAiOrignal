import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Core/Services/fcmTokenService.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationNavigationService.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/roleSelectionPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokernavbar.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/transporterHomePage.dart';

import '../../Auth/Pages/logInPage.dart';
import '../../User Module/Widgets/shipperbottomnavbar.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    checkUser();
  }

  Future<void> checkUser() async {
    try {
      final splashDelay = Future.delayed(const Duration(milliseconds: 1500));

      // 1. Retrieve existing authenticated user from Firebase Auth persistence
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        user = await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(
              const Duration(seconds: 2),
              onTimeout: () => FirebaseAuth.instance.currentUser,
            );
      }

      await splashDelay;
      if (!mounted) return;

      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RoleSelectionPage(),
          ),
        );
        return;
      }

      // Check email verification if required
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const LogInPage(),
            ),
          );
        }
        return;
      }

      final uid = user.uid;

      // 2. Query Firestore role collections in parallel to quickly determine role
      final results = await Future.wait([
        FirebaseFirestore.instance.collection("User").doc(uid).get(),
        FirebaseFirestore.instance.collection("Broker").doc(uid).get(),
        FirebaseFirestore.instance.collection("Driver").doc(uid).get(),
      ]);

      final userDoc = results[0];
      final brokerDoc = results[1];
      final driverDoc = results[2];

      if (!mounted) return;

      if (userDoc.exists) {
        FcmTokenService().registerToken(uid: uid, role: 'User');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ShipperBottomNavBar(),
          ),
        ).then((_) {
          NotificationNavigationService().processPendingNotification();
        });
        return;
      }

      if (brokerDoc.exists) {
        FcmTokenService().registerToken(uid: uid, role: 'Broker');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BrokerBottomNavBar(),
          ),
        ).then((_) {
          NotificationNavigationService().processPendingNotification();
        });
        return;
      }

      if (driverDoc.exists) {
        FcmTokenService().registerToken(uid: uid, role: 'Driver');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TransporterHomePage(),
          ),
        ).then((_) {
          NotificationNavigationService().processPendingNotification();
        });
        return;
      }

      // If auth account has no associated role document, sign out and go to RoleSelectionPage
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
              "assets/Images/TruckLink AI.png",
              width: 120,
            ),

            const SizedBox(height: 20),

            const Text(
              "TruckLink AI",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(color: Appcolors.primaryBlue,),
          ],
        ),
      ),
    );
  }
}