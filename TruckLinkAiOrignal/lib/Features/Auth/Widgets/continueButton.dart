
import 'package:flutter/material.dart';

class ContinueButton extends StatelessWidget {
  const ContinueButton({
    super.key,
    required this.text,
    required this.clr,
    required this.onTap,
    this.isLoading = false,
  });

  final String text;
  final Color clr;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
        child: isLoading
            ? SizedBox(
                height: screenWidth < 600 ? 22 : 26,
                width: screenWidth < 600 ? 22 : 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.6),
                  ),
                ),
              )
            : Text(
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