// import 'package:flutter/material.dart';
// import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

// class HomeQuickContainer extends StatelessWidget {
//   const HomeQuickContainer({super.key, required this.text1, required this.icn});
//   final String text1;
//   final Icon icn;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 140,
//       height: 60,

//       decoration: BoxDecoration(
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.3),
//             spreadRadius: 0.7,
//             blurRadius: 1,
//             offset: Offset(0, 1), // changes position of shadow
//           ),
//         ],
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           Icon(icn.icon, color: Appcolors.primaryBlue, size: 30),

//           Text(text1, style: TextStyle(color: Appcolors.primaryBlue,fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class HomeQuickContainer extends StatelessWidget {
  const HomeQuickContainer({
    super.key,
    required this.text1,
    required this.icn,
  });

  final String text1;
  final Icon icn;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1000;

    final double boxWidth =
        isMobile ? 140 : isTablet ? 180 : 220;

    final double boxHeight =
        isMobile ? 70 : isTablet ? 85 : 100;

    final double iconSize =
        isMobile ? 28 : isTablet ? 34 : 40;

    final double textSize =
        isMobile ? 13 : isTablet ? 15 : 17;

    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.25),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icn.icon,
            color: Appcolors.primaryBlue,
            size: iconSize,
          ),

          const SizedBox(height: 5),

          Text(
            text1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Appcolors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: textSize,
            ),
          ),
        ],
      ),
    );
  }
}
