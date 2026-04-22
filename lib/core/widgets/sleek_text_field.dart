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
  final bool enabled;

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
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(
                icon,
                size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              suffixIcon: obscureText && onToggleVisibility != null
                  ? IconButton(
                      icon: Icon(
                        obsecureTextState
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}