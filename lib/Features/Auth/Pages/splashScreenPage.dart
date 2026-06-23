import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Auth/Pages/roleSelectionPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokernavbar.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Pages/transporterHomePage.dart';

import '../../Auth/Pages/logInPage.dart';
import '../../User Module/Widgets/shipperbottomnavbar.dart';
// import BrokerHomePage
// import DriverHomePage

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
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionPage(),
        ),
      );
      return;
    }

    final uid = user.uid;

    // Check User Collection
    final userDoc = await FirebaseFirestore.instance
        .collection("User")
        .doc(uid)
        .get();

    if (userDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ShipperBottomNavBar(),
        ),
      );
      return;
    }

    // Check Broker Collection
    final brokerDoc = await FirebaseFirestore.instance
        .collection("Broker")
        .doc(uid)
        .get();

    if (brokerDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BrokerBottomNavBar(),
        ),
      );
      return;
    }

    // Check Driver Collection
    final driverDoc = await FirebaseFirestore.instance
        .collection("Driver")
        .doc(uid)
        .get();

    if (driverDoc.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TransporterHomePage(),
        ),
      );
      return;
    }

    // User authenticated but not found in Firestore
    await FirebaseAuth.instance.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LogInPage(),
      ),
    );
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