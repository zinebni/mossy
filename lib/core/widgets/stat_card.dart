import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'mossy_card.dart';

/// A stat display card with an icon, numeric value, descriptive label,
/// and optional trend indicator. Ideal for Home and Profile screens.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final String? trend;
  final bool isPositiveTrend;
  final VoidCallback? onTap;
  final double? width;
  final Color? backgroundColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.iconBackgroundColor,
    this.trend,
    this.isPositiveTrend = true,
    this.onTap,
    this.width,
    this.backgroundColor,
  });

  /// Factory preset for flora/plants stats.
  factory StatCard.mint({
    Key? key,
    required String label,
    required String value,
    IconData icon = Icons.eco_rounded,
    String? trend,
    VoidCallback? onTap,
    double? width,
  }) {
    return StatCard(
      key: key,
      label: label,
      value: value,
      icon: icon,
      iconColor: AppColors.deepSage,
      iconBackgroundColor: AppColors.mintGreen,
      trend: trend,
      onTap: onTap,
      width: width,
    );
  }

  /// Factory preset for badges/discoveries stats.
  factory StatCard.lavender({
    Key? key,
    required String label,
    required String value,
    IconData icon = Icons.military_tech_rounded,
    String? trend,
    VoidCallback? onTap,
    double? width,
  }) {
    return StatCard(
      key: key,
      label: label,
      value: value,
      icon: icon,
      iconColor: const Color(0xFF6B4C8A),
      iconBackgroundColor: AppColors.lavender,
      trend: trend,
      onTap: onTap,
      width: width,
    );
  }

  /// Factory preset for trail/distance stats.
  factory StatCard.peach({
    Key? key,
    required String label,
    required String value,
    IconData icon = Icons.hiking_rounded,
    String? trend,
    VoidCallback? onTap,
    double? width,
  }) {
    return StatCard(
      key: key,
      label: label,
      value: value,
      icon: icon,
      iconColor: const Color(0xFFB05634),
      iconBackgroundColor: AppColors.peach,
      trend: trend,
      onTap: onTap,
      width: width,
    );
  }

  /// Factory preset for points/energy stats.
  factory StatCard.yellow({
    Key? key,
    required String label,
    required String value,
    IconData icon = Icons.wb_sunny_rounded,
    String? trend,
    VoidCallback? onTap,
    double? width,
  }) {
    return StatCard(
      key: key,
      label: label,
      value: value,
      icon: icon,
      iconColor: const Color(0xFF9E7B15),
      iconBackgroundColor: AppColors.butterYellow,
      trend: trend,
      onTap: onTap,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIconBg =
        iconBackgroundColor ?? AppColors.mintGreen.withValues(alpha: 0.5);
    final effectiveIconColor = iconColor ?? AppColors.sageGreen;

    return MossyCard(
      onTap: onTap,
      width: width,
      color: backgroundColor ?? AppColors.cardSurface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Center(
                  child: iconWidget ??
                      Icon(
                        icon ?? Icons.park_rounded,
                        size: 22.0,
                        color: effectiveIconColor,
                      ),
                ),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: isPositiveTrend
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositiveTrend
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14.0,
                        color: isPositiveTrend
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 3.0),
                      Text(
                        trend!,
                        style: GoogleFonts.nunito(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: isPositiveTrend
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          AppSpacing.gapH12,
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGreen,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3.0),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
