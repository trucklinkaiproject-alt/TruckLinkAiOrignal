
import 'package:flutter/material.dart';

class SignUpTextField extends StatefulWidget {
  const SignUpTextField({
    super.key,
    required this.hintText,
    required this.label,
    required this.controller,
    this.obscureText,
    this.type,
  });

  final String hintText;
  final String label;
  final TextEditingController controller;
  final bool? obscureText;
  final TextInputType? type;

  @override
  State<SignUpTextField> createState() => _SignUpTextFieldState();
}

class _SignUpTextFieldState extends State<SignUpTextField> {
  late bool _obscureText;
  final FocusNode _textFieldFocusNode = FocusNode();
  final FocusNode _iconFocusNode =
      FocusNode(skipTraversal: true, canRequestFocus: false);

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText ?? false;
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    _iconFocusNode.dispose();
    super.dispose();
  }

  void _toggleObscureText() {
    final currentOffset = widget.controller.selection.baseOffset;
    final textLength = widget.controller.text.length;

    setState(() {
      _obscureText = !_obscureText;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final safeOffset = (currentOffset >= 0 && currentOffset <= textLength)
          ? currentOffset
          : textLength;

      widget.controller.selection = TextSelection.collapsed(
        offset: safeOffset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isPasswordField = widget.obscureText == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _textFieldFocusNode,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              suffixIcon: isPasswordField
                  ? IconButton(
                      focusNode: _iconFocusNode,
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: _toggleObscureText,
                    )
                  : null,
            ),
            obscureText: _obscureText,
            keyboardType: widget.type,
          ),
        ),
      ],
    );
  }
}