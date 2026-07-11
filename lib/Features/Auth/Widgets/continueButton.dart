// import 'package:flutter/material.dart';

// class ContinueButton extends StatelessWidget {
//   const ContinueButton({super.key, required this.text, required this.clr, required this.onTap});
//   final String text;
//   final Color clr;
//   final VoidCallback?onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         height: 50,
//         margin: EdgeInsets.symmetric(horizontal: 20),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: clr,
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Text(text,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20),),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class ContinueButton extends StatelessWidget {
  const ContinueButton({
    super.key,
    required this.text,
    required this.clr,
    required this.onTap,
  });

  final String text;
  final Color clr;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: screenWidth < 600 ? 50 : 60,
        margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: clr,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (screenWidth * 0.018).clamp(16.0, 22.0),
          ),
        ),
      ),
    );
  }
}