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

  final List<Widget> _pages = [
    BrokerHomePage(),
    BrokerOrderPage(),
    BrokerDriversNetworkPage(),
    BrokerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),

              BottomNavigationBarItem(
                icon: Icon(Icons.drive_eta_rounded),
                label: "Drivers",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: "Profile",
              ),
            ],
            iconSize: 25,
            selectedItemColor: Appcolors.secondaryPurple,
            unselectedItemColor: const Color.fromARGB(255, 130, 130, 130),
            selectedLabelStyle: TextStyle(
              color: Appcolors.secondaryPurple,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(color: Colors.black),
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            enableFeedback: false,
          ),
        ),
      ),
    );
  }
}
