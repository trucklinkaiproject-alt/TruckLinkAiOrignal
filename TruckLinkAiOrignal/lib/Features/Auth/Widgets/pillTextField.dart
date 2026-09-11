import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class PillTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool filled;
  final Widget? suffixIcon;
  final bool isPassword;

  const PillTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.filled = false,
    this.suffixIcon,
    this.isPassword = false,
  });

  @override
  State<PillTextField> createState() => _PillTextFieldState();
}

class _PillTextFieldState extends State<PillTextField> {
  late bool _obscured;
  final FocusNode _iconFocusNode =
      FocusNode(skipTraversal: true, canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword ? true : widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant PillTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isPassword && oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  void dispose() {
    _iconFocusNode.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    final currentOffset = widget.controller.selection.baseOffset;
    final textLength = widget.controller.text.length;

    setState(() {
      _obscured = !_obscured;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final safeOffset = (currentOffset >= 0 && currentOffset <= textLength)
          ? currentOffset
          : textLength;
      widget.controller.selection = TextSelection.collapsed(offset: safeOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffix = widget.suffixIcon;

    if (widget.isPassword && effectiveSuffix == null) {
      effectiveSuffix = IconButton(
        focusNode: _iconFocusNode,
        icon: Icon(
          _obscured
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey[600],
          size: 20,
        ),
        onPressed: _toggleVisibility,
      );
    }

    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscured,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: widget.filled ? Colors.white70 : Colors.grey[400],
        ),
        filled: true,
        fillColor: widget.filled ? Colors.grey[400] : Colors.white,
        suffixIcon: effectiveSuffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: widget.filled
              ? BorderSide.none
              : BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Appcolors.primaryBlue, width: 1.6),
        ),
      ),
    );
  }
}