import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'mossy_button.dart';

/// Friendly error display using warm nature tones, comforting messaging,
/// and an actionable retry button.
class ErrorDisplay extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryText;
  final VoidCallback? onSecondary;
  final String? secondaryText;
  final IconData? icon;
  final Widget? iconWidget;
  final bool isCompact;
  final EdgeInsetsGeometry padding;

  const ErrorDisplay({
    super.key,
    this.title = 'A fallen branch blocked the trail',
    this.message,
    this.onRetry,
    this.retryText = 'Try Again',
    this.onSecondary,
    this.secondaryText,
    this.icon,
    this.iconWidget,
    this.isCompact = false,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
  });

  /// Compact inline banner or list tile error widget.
  const ErrorDisplay.compact({
    super.key,
    this.title = 'Unable to load content',
    this.message,
    this.onRetry,
    this.retryText = 'Retry',
    this.onSecondary,
    this.secondaryText,
    this.icon = Icons.refresh_rounded,
    this.iconWidget,
    this.padding = AppSpacing.cardPadding,
  }) : isCompact = true;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.peach.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppColors.peach,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.priority_high_rounded,
                size: 20.0,
                color: AppColors.error,
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      message!,
                      style: GoogleFonts.nunito(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (onRetry != null) ...[
              AppSpacing.gapW8,
              IconButton(
                onPressed: onRetry,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.darkGreen,
                ),
                tooltip: retryText,
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Warm circular badge
            Container(
              width: 90.0,
              height: 90.0,
              decoration: BoxDecoration(
                color: AppColors.peach.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: AppShadows.softList,
              ),
              child: Center(
                child: iconWidget ??
                    Icon(
                      icon ?? Icons.forest_outlined,
                      size: 44.0,
                      color: AppColors.error,
                    ),
              ),
            ),
            AppSpacing.gapH24,
            Text(
              title,
              style: GoogleFonts.quicksand(
                fontSize: 22.0,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGreen,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              AppSpacing.gapH8,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360.0),
                child: Text(
                  message!,
                  style: GoogleFonts.nunito(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (onRetry != null) ...[
              AppSpacing.gapH24,
              MossyButton.primary(
                text: retryText,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: onRetry,
              ),
            ],
            if (onSecondary != null && secondaryText != null) ...[
              AppSpacing.gapH8,
              MossyButton.text(
                text: secondaryText!,
                onPressed: onSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
