import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/createorderpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperalertpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperhomePage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperorderpage.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Pages/shipperprofilepage.dart';

class ShipperBottomNavBar extends StatefulWidget {
  const ShipperBottomNavBar({super.key});

  @override
  State<ShipperBottomNavBar> createState() => _ShipperBottomNavBarState();
}

class _ShipperBottomNavBarState extends State<ShipperBottomNavBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ShipperHomePage(),
    ShipperOrderPage(),
    CreateOrderPage(),
    ShipperAlertPage(),
    ShipperProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: SizedBox(
            height: 65,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: "Home",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_outlined),
                  activeIcon: Icon(Icons.list_alt_rounded),
                  label: "Orders",
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      color: Appcolors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 28, color: Colors.white),
                  ),
                  label: "",
                ),
                BottomNavigationBarItem(
                  icon: StreamBuilder<QuerySnapshot>(
                    stream: currentUid.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection("User")
                            .doc(currentUid)
                            .collection("Notifications")
                            .where("is_read", isEqualTo: false)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      final int unreadCount = snapshot.data?.docs.length ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none_outlined),
                          if (unreadCount > 0)
                            Positioned(
                              top: -4,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  activeIcon: const Icon(Icons.notifications_rounded),
                  label: "Alerts",
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person_rounded),
                  label: "Profile",
                ),
              ],
              iconSize: 24,
              selectedItemColor: Appcolors.primaryBlue,
              unselectedItemColor: Colors.black87,
              selectedLabelStyle: const TextStyle(
                color: Appcolors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 10.5,
              ),
              unselectedLabelStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 10,
              ),
              showUnselectedLabels: true,
              backgroundColor: Colors.white,
              elevation: 4,
              type: BottomNavigationBarType.fixed,
              enableFeedback: false,
            ),
          ),
        ),
      ),
    );
  }
}
