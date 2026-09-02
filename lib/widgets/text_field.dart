import 'package:flutter/material.dart';

class TextFieldInput extends StatelessWidget {
  final TextEditingController textEditingController;
  final bool obscureText;
  final String hintText;
  final IconData? icon;
  final Widget? suffixIcon;

  const TextFieldInput({
    super.key,
    required this.textEditingController,
    this.obscureText = false,
    required this.hintText,
    this.icon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        obscureText: obscureText,
        controller: textEditingController,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle:
              const TextStyle(color: Colors.black45, fontSize: 18),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.black)
              : null,
          suffixIcon: suffixIcon, // ✅ added here
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.grey,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(width: 2, color: Colors.red),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}