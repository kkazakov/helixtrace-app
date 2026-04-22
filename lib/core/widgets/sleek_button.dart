import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SleekButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const SleekButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buttonContent;

    if (isLoading) {
      buttonContent = SizedBox(
        height: 20,
        width: 20,
        child: Shimmer.fromColors(
          baseColor: colorScheme.primary.withValues(alpha: 0.3),
          highlightColor: colorScheme.primary,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    } else {
      buttonContent = Text(
        text,
        style: theme.textTheme.labelLarge,
      );
    }

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: theme.textTheme.labelLarge,
        ),
        child: buttonContent,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null || !isLoading
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: theme.textTheme.labelLarge,
      ),
      child: buttonContent,
    );
  }
}
