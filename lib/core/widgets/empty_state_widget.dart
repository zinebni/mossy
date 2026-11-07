import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import 'mossy_button.dart';

/// An attractive, nature-themed empty state display with playful styling,
/// customizable illustration/icon, title, subtitle, and primary/secondary actions.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? iconWidget;
  final String? actionText;
  final VoidCallback? onAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final EdgeInsetsGeometry padding;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconWidget,
    this.actionText,
    this.onAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.iconBackgroundColor,
    this.iconColor,
  });

  /// Factory for empty search results.
  factory EmptyStateWidget.noResults({
    Key? key,
    String title = 'No nature discoveries found',
    String subtitle = 'Try adjusting your search terms or explore a different area on the trail.',
    String? actionText = 'Clear Search',
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.search_off_rounded,
      iconBackgroundColor: AppColors.butterYellow.withValues(alpha: 0.35),
      iconColor: AppColors.darkGreen,
      title: title,
      subtitle: subtitle,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Factory for empty saved / bookmarks.
  factory EmptyStateWidget.noFavorites({
    Key? key,
    String title = 'Your field journal is empty',
    String subtitle = 'Save fascinating flora, fauna, and mushrooms you encounter along the way.',
    String? actionText = 'Start Exploring',
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.bookmark_border_rounded,
      iconBackgroundColor: AppColors.lavender.withValues(alpha: 0.5),
      iconColor: AppColors.darkGreen,
      title: title,
      subtitle: subtitle,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Factory for empty explorations / hikes.
  factory EmptyStateWidget.noExplorations({
    Key? key,
    String title = 'No expeditions yet',
    String subtitle = 'Step outside and let Mossy guide your next outdoor exploration.',
    String? actionText = 'Plan an Expedition',
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.explore_outlined,
      iconBackgroundColor: AppColors.mintGreen.withValues(alpha: 0.45),
      iconColor: AppColors.darkGreen,
      title: title,
      subtitle: subtitle,
      actionText: actionText,
      onAction: onAction,
    );
  }

  /// Factory for offline state.
  factory EmptyStateWidget.offline({
    Key? key,
    String title = 'You are deep in the woods',
    String subtitle = 'Offline mode is active. You can still view cached species and field guides.',
    String? actionText = 'Retry Connection',
    VoidCallback? onAction,
  }) {
    return EmptyStateWidget(
      key: key,
      icon: Icons.wifi_off_rounded,
      iconBackgroundColor: AppColors.peach.withValues(alpha: 0.45),
      iconColor: AppColors.darkGreen,
      title: title,
      subtitle: subtitle,
      actionText: actionText,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconBg =
        iconBackgroundColor ?? AppColors.mintGreen.withValues(alpha: 0.45);
    final effectiveIconColor = iconColor ?? AppColors.sageGreen;

    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Playful organic icon container
            Container(
              width: 96.0,
              height: 96.0,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                shape: BoxShape.circle,
                boxShadow: AppShadows.softList,
              ),
              child: Center(
                child: iconWidget ??
                    Icon(
                      icon ?? Icons.park_outlined,
                      size: 46.0,
                      color: effectiveIconColor,
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
            if (subtitle != null) ...[
              AppSpacing.gapH8,
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380.0),
                child: Text(
                  subtitle!,
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
            if (actionText != null && onAction != null) ...[
              AppSpacing.gapH24,
              MossyButton.primary(
                text: actionText!,
                onPressed: onAction,
              ),
            ],
            if (secondaryActionText != null && onSecondaryAction != null) ...[
              AppSpacing.gapH8,
              MossyButton.text(
                text: secondaryActionText!,
                onPressed: onSecondaryAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
