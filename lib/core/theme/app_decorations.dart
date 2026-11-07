import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_colors.dart';
import 'app_shadows.dart';

/// Reusable BoxDecoration presets for cards, surfaces, chips, and overlays.
class AppDecorations {
  AppDecorations._();

  /// Default clean card decoration with subtle border and soft organic shadow.
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.cardSurface,
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.subtleBorder,
      width: 1.0,
    ),
    boxShadow: AppShadows.softList,
  );

  /// Elevated card with prominent presence for primary cards / banners.
  static BoxDecoration elevatedCardDecoration = BoxDecoration(
    color: AppColors.cardSurface,
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.subtleBorder,
      width: 1.0,
    ),
    boxShadow: AppShadows.mediumList,
  );

  /// Flat surface container with a gentle border, ideal on cream canvas.
  static BoxDecoration surfaceDecoration = BoxDecoration(
    color: AppColors.surfaceCream,
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.border,
      width: 1.0,
    ),
  );

  /// Frosted glass appearance with subtle transparency and border.
  static BoxDecoration glassDecoration = BoxDecoration(
    color: AppColors.white.withValues(alpha: 0.85),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.white.withValues(alpha: 0.6),
      width: 1.5,
    ),
    boxShadow: AppShadows.softList,
  );

  /// Colored accent card decorations
  static BoxDecoration sageCardDecoration = BoxDecoration(
    color: AppColors.sageGreen.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.sageGreen.withValues(alpha: 0.3),
      width: 1.0,
    ),
    boxShadow: AppShadows.sageCardShadowList,
  );

  static BoxDecoration mintCardDecoration = BoxDecoration(
    color: AppColors.mintGreen.withValues(alpha: 0.35),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.sageGreen.withValues(alpha: 0.2),
      width: 1.0,
    ),
    boxShadow: AppShadows.mintCardShadowList,
  );

  static BoxDecoration lavenderCardDecoration = BoxDecoration(
    color: AppColors.lavender.withValues(alpha: 0.4),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.lavender,
      width: 1.0,
    ),
    boxShadow: AppShadows.lavenderCardShadowList,
  );

  static BoxDecoration peachCardDecoration = BoxDecoration(
    color: AppColors.peach.withValues(alpha: 0.35),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.peach,
      width: 1.0,
    ),
    boxShadow: AppShadows.peachCardShadowList,
  );

  static BoxDecoration yellowCardDecoration = BoxDecoration(
    color: AppColors.butterYellow.withValues(alpha: 0.3),
    borderRadius: BorderRadius.circular(AppConstants.cardRadius),
    border: Border.all(
      color: AppColors.butterYellow.withValues(alpha: 0.6),
      width: 1.0,
    ),
    boxShadow: AppShadows.yellowCardShadowList,
  );

  /// Badge/chip rounded decoration
  static BoxDecoration badgeDecoration({
    Color backgroundColor = AppColors.mintGreen,
    Color? borderColor,
    double radius = AppConstants.chipRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null ? Border.all(color: borderColor, width: 1.0) : null,
    );
  }

  /// Pill button or badge decoration
  static BoxDecoration pillDecoration({
    Color backgroundColor = AppColors.mintGreen,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(100.0),
      border: borderColor != null ? Border.all(color: borderColor, width: 1.0) : null,
    );
  }

  /// Bottom sheet modal decoration
  static BoxDecoration bottomSheetDecoration = const BoxDecoration(
    color: AppColors.cream,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppConstants.bottomSheetRadius),
      topRight: Radius.circular(AppConstants.bottomSheetRadius),
    ),
    boxShadow: AppShadows.strongList,
  );
}
