import 'package:flutter/material.dart';

class SelectionPageButton extends StatelessWidget {
  const SelectionPageButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.clr,
    required this.icn, required this.onTap,
  });
  final String title;
  final String subtitle;
  final Color clr;
  final Icon icn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: clr,
      ),
      child: ListTile(
        onTap: onTap,
        title: Center(
          child: Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        subtitle: Center(
          child: Text(
            subtitle,
            style: TextStyle(color: const Color.fromARGB(255, 219, 219, 219)),
          ),
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Icon(icn.icon, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
