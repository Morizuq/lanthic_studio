import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_border_radius.dart';
import '../tokens/app_responsive.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonPadding = context.responsive<EdgeInsets>(
      mobile: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      tablet: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.m + 2,
      ),
      desktop: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.l,
      ),
    );

    final double fontSize = context.responsive<double>(
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        disabledBackgroundColor: theme.colorScheme.primary.withValues(alpha: 0.5),
        disabledForegroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
        padding: buttonPadding,
        shape: const RoundedRectangleBorder(
          borderRadius: AppBorderRadius.allM,
        ),
        elevation: 0,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? SizedBox(
                height: fontSize + 4,
                width: fontSize + 4,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: fontSize + 2),
                    AppSpacing.hXS,
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
