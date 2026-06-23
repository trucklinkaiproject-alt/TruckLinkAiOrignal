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
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 110,
        
      
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),],
          color: ctnclr,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icn.icon, color: icn.color, size: 30),
            
            Text(text1, style: TextStyle(color: clr)),
            if (text2 != null) Text(text2!, style: TextStyle(color: clr)),
          ],
        ),
      ),
    );
  }
}
