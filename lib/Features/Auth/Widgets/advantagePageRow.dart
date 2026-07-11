// import 'package:flutter/material.dart';

// class AdvantagesPageRow extends StatelessWidget {
//   const AdvantagesPageRow({super.key, required this.text, required this.clr});
//   final String text;
//   final Color clr;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               border: Border.all(width: 1, color: clr),
//               borderRadius: BorderRadius.circular(25),
//             ),
//             child: Icon(Icons.offline_bolt_sharp, color: clr, size: 27),
//           ),
//           SizedBox(width: 30),
//           Text(
            
//             text,
//             style: TextStyle(
//               fontSize: 16,
//               color: clr.withOpacity(0.7),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
    
//   }
// }

import 'package:flutter/material.dart';

class AdvantagesPageRow extends StatelessWidget {
  const AdvantagesPageRow({
    super.key,
    required this.text,
    required this.clr,
  });

  final String text;
  final Color clr;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final iconSize =
        (screenWidth * 0.025).clamp(24.0, 32.0);

    final textSize =
        (screenWidth * 0.016).clamp(14.0, 20.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: iconSize + 8,
            height: iconSize + 8,
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
                color: clr,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.offline_bolt_sharp,
              color: clr,
              size: iconSize,
            ),
          ),

          SizedBox(
            width: screenWidth * 0.03,
          ),

          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: textSize,
                color: clr.withValues(alpha: 0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
