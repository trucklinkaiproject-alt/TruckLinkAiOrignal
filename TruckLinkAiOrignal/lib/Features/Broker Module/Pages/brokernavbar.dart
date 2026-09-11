import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerDriverNetworkPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerHomePage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerOrderPage.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/Pages/brokerProfilePage.dart';

class BrokerBottomNavBar extends StatefulWidget {
  const BrokerBottomNavBar({super.key});

  @override
  State<BrokerBottomNavBar> createState() => _BrokerBottomNavBarState();
}

class _BrokerBottomNavBarState extends State<BrokerBottomNavBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BrokerHomePage(),
    BrokerOrderPage(),
    BrokerDriversNetworkPage(),
    BrokerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_alt_rounded),
                  label: "Orders",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.drive_eta_rounded),
                  label: "Drivers",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  label: "Profile",
                ),
              ],
              iconSize: 24,
              selectedItemColor: Appcolors.secondaryPurple,
              unselectedItemColor: const Color(0xFF8E8E93),
              selectedLabelStyle: const TextStyle(
                color: Appcolors.secondaryPurple,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              showUnselectedLabels: true,
              backgroundColor: Colors.white,
              elevation: 8,
              type: BottomNavigationBarType.fixed,
              enableFeedback: false,
            ),
          ),
        ),
      ),
    );
  }
}

