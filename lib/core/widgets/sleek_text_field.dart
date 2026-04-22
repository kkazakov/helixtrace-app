import 'package:flutter/material.dart';

class SleekTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final VoidCallback? onToggleVisibility;
  final bool obsecureTextState;

  const SleekTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onToggleVisibility,
    required this.obsecureTextState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: theme.textTheme.bodyMedium?.color ?? const Color(0xFF7B7B9B),
            ),
            suffixIcon: obscureText && onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obsecureTextState
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: theme.textTheme.bodyMedium?.color ?? const Color(0xFF7B7B9B),
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
