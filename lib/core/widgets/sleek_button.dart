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
          baseColor: colorScheme.onPrimary.withValues(alpha: 0.4),
          highlightColor: colorScheme.onPrimary,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    } else {
      buttonContent = Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isOutlined ? colorScheme.primary : colorScheme.onPrimary,
        ),
      );
    }

    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: onPressed != null
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
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
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      ),
      child: buttonContent,
    );
  }
}