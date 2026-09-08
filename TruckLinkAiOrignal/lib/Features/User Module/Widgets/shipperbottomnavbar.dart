// import 'package:flutter/material.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';
// import 'package:trucklinkai_orignal/Features/Shipper%20Module/Presentation/Pages/shipperalertpage.dart';
// import 'package:trucklinkai_orignal/Features/Shipper%20Module/Presentation/Pages/shipperhomePage.dart';
// import 'package:trucklinkai_orignal/Features/Shipper%20Module/Presentation/Pages/shipperorderpage.dart';
// import 'package:trucklinkai_orignal/Features/Shipper%20Module/Presentation/Pages/shipperprofilepage.dart';

// class ShipperBottomNavBar extends StatefulWidget {
//   const ShipperBottomNavBar({super.key});

//   @override
//   State<ShipperBottomNavBar> createState() => _ShipperBottomNavBarState();
// }

// class _ShipperBottomNavBarState extends State<ShipperBottomNavBar> {
//   int _currentIndex=  0;
//     final List<Widget> _pages = [
//       ShipperHomePage(),
//       ShipperOrderPage(),
//       Placeholder(),
//       ShipperAlertPage(),
//       ShipperProfilePage(),
//     ];
//   @override
//   Widget build(BuildContext context) {
    
//     return Scaffold(
//       body: _pages[_currentIndex],
//       bottomNavigationBar: BottomNavigationBar(
        
//   currentIndex: _currentIndex,
//   onTap: (index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   },
//   items: const [
//     BottomNavigationBarItem(
//         icon: Icon(Icons.home_outlined),
//         label: "Home"),
//     BottomNavigationBarItem(
//         icon: Icon(Icons.list),
//         label: "Orders"),
//     BottomNavigationBarItem(
//         icon: Icon(Icons.add_circle, size: 50,color: Appcolors.primaryBlue,),
//         label: ""),
//     BottomNavigationBarItem(
//         icon: Icon(Icons.notifications_none_outlined),
//         label: "Alerts"),
//     BottomNavigationBarItem(
//         icon: Icon(Icons.person_outline),
//         label: "Profile"),
//   ],
//   iconSize: 30,
//   selectedItemColor: Appcolors.primaryBlue,
//   unselectedItemColor: Colors.black,
//   selectedLabelStyle:
//       TextStyle(color: Appcolors.primaryBlue, fontWeight: FontWeight.bold,fontSize: 12),
//   unselectedLabelStyle: TextStyle(color: Colors.black),
//   showUnselectedLabels: true,
//   backgroundColor: Colors.white,
//   elevation: 0,
//   type: BottomNavigationBarType.fixed,
//   enableFeedback: false,
//   splashFactory: NoSplash.splashFactory,
// ),

//     );
//   }
// }
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

  final List<Widget> _pages = [
    ShipperHomePage(),
    ShipperOrderPage(),
    CreateOrderPage(),
    ShipperAlertPage(),
    ShipperProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,    // removes ripple color
          highlightColor: Colors.transparent, // removes tap highlight
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
            items:  [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.list), label: "Orders"),
              BottomNavigationBarItem(
                 icon: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Appcolors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 30, color: Colors.white),
                 ), label: "",),
              BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_none_outlined), label: "Alerts"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: "Profile"),
            ],
            iconSize: 25,
            selectedItemColor: Appcolors.primaryBlue,
            unselectedItemColor: Colors.black,
            selectedLabelStyle: TextStyle(
                color: Appcolors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 10),
            unselectedLabelStyle: TextStyle(color: Colors.black,fontSize: 10),
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
