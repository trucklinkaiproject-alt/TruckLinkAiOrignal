import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class HomeQuickContainer extends StatelessWidget {
  const HomeQuickContainer({super.key, required this.text1, required this.icn});
  final String text1;
  final Icon icn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 60,

      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 0.7,
            blurRadius: 1,
            offset: Offset(0, 1), // changes position of shadow
          ),
        ],
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(icn.icon, color: Appcolors.primaryBlue, size: 30),

          Text(text1, style: TextStyle(color: Appcolors.primaryBlue,fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
