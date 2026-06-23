import 'package:flutter/material.dart';

class AdvantagesPageRow extends StatelessWidget {
  const AdvantagesPageRow({super.key, required this.text, required this.clr});
  final String text;
  final Color clr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              border: Border.all(width: 1, color: clr),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(Icons.offline_bolt_sharp, color: clr, size: 27),
          ),
          SizedBox(width: 30),
          Text(
            
            text,
            style: TextStyle(
              fontSize: 16,
              color: clr.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    
  }
}
