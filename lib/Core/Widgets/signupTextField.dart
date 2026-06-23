import 'package:flutter/material.dart';

class SignUpTextField extends StatelessWidget {
  const SignUpTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText, this.type,
  });
  final String hintText;
  final TextEditingController controller;
  final bool? obscureText;
  final TextInputType? type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      margin: EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
        ),
        obscureText: obscureText ?? false,
        keyboardType: type,
      ),
    );
  }
}
