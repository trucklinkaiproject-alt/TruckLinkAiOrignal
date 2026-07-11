// import 'package:flutter/material.dart';

// class ShipperHomeBox extends StatelessWidget {
//   const ShipperHomeBox({
//     super.key,
//     required this.text1,
//      this.text2,
//     required this.icn,
//     required this.clr,
//     required this.ctnclr,
//     this.onTap,
//   });
//   final String text1;
//   final String? text2;
//   final Icon icn;
//   final Color clr;
//   final Color ctnclr;
//   final VoidCallback? onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         width: 140,
//         height: 110,
        
      
//         decoration: BoxDecoration(
//           boxShadow: [BoxShadow(
//             color: Colors.grey.withOpacity(0.5),
//             spreadRadius: 2,
//             blurRadius: 5,
//             offset: Offset(0, 3), // changes position of shadow
//           ),],
//           color: ctnclr,
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icn.icon, color: icn.color, size: 30),
            
//             Text(text1, style: TextStyle(color: clr)),
//             if (text2 != null) Text(text2!, style: TextStyle(color: clr)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class ShipperHomeBox extends StatelessWidget {
  const ShipperHomeBox({
    super.key,
    required this.text1,
    this.text2,
    required this.icn,
    required this.clr,
    required this.ctnclr,
    this.onTap,
  });

  final String text1;
  final String? text2;
  final Icon icn;
  final Color clr;
  final Color ctnclr;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool isMobile = width < 600;
    final bool isTablet = width >= 600 && width < 1000;

    final double boxWidth =
        isMobile ? 140 : isTablet ? 180 : 220;

    final double boxHeight =
        isMobile ? 110 : isTablet ? 130 : 150;

    final double iconSize =
        isMobile ? 30 : isTablet ? 38 : 45;

    final double textSize =
        isMobile ? 14 : isTablet ? 16 : 18;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: boxWidth,
        height: boxHeight,
        decoration: BoxDecoration(
          color: ctnclr,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icn.icon,
              color: icn.color,
              size: iconSize,
            ),

            SizedBox(height: boxHeight * 0.08),

            Text(
              text1,
              style: TextStyle(
                color: clr,
                fontSize: textSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (text2 != null)
              Text(
                text2!,
                style: TextStyle(
                  color: clr,
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}