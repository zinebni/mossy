import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// A signature nature-styled card widget with rounded corners and organic shadows.
class MossyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const MossyCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.borderRadius,
    this.border,
    this.shadow,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  /// Mint-tinted variant of MossyCard.
  factory MossyCard.mint({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding = AppSpacing.cardPadding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return MossyCard(
      key: key,
      padding: padding,
      margin: margin,
      color: AppColors.mintGreen.withValues(alpha: 0.3),
      border: Border.all(
        color: AppColors.sageGreen.withValues(alpha: 0.25),
        width: 1.0,
      ),
      shadow: AppShadows.mintCardShadowList,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Lavender-tinted variant of MossyCard.
  factory MossyCard.lavender({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding = AppSpacing.cardPadding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return MossyCard(
      key: key,
      padding: padding,
      margin: margin,
      color: AppColors.lavender.withValues(alpha: 0.35),
      border: Border.all(
        color: AppColors.lavender,
        width: 1.0,
      ),
      shadow: AppShadows.lavenderCardShadowList,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Peach-tinted variant of MossyCard.
  factory MossyCard.peach({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding = AppSpacing.cardPadding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return MossyCard(
      key: key,
      padding: padding,
      margin: margin,
      color: AppColors.peach.withValues(alpha: 0.35),
      border: Border.all(
        color: AppColors.peach,
        width: 1.0,
      ),
      shadow: AppShadows.peachCardShadowList,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Butter yellow-tinted variant of MossyCard.
  factory MossyCard.yellow({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding = AppSpacing.cardPadding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return MossyCard(
      key: key,
      padding: padding,
      margin: margin,
      color: AppColors.butterYellow.withValues(alpha: 0.3),
      border: Border.all(
        color: AppColors.butterYellow.withValues(alpha: 0.5),
        width: 1.0,
      ),
      shadow: AppShadows.yellowCardShadowList,
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Surface cream flat variant of MossyCard.
  factory MossyCard.surface({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding = AppSpacing.cardPadding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return MossyCard(
      key: key,
      padding: padding,
      margin: margin,
      color: AppColors.surfaceCream,
      border: Border.all(
        color: AppColors.border,
        width: 1.0,
      ),
      shadow: const [],
      onTap: onTap,
      width: width,
      height: height,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppConstants.cardRadius);
    final cardColor = color ?? AppColors.cardSurface;
    final cardBorder = border ??
        Border.all(
          color: AppColors.subtleBorder,
          width: 1.0,
        );

    final cardShadows = shadow ??
        (elevation != null
            ? [
                BoxShadow(
                  color: const Color(0x142D3B2D),
                  blurRadius: elevation! * 4,
                  offset: Offset(0, elevation!),
                ),
              ]
            : AppShadows.softList);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: AppColors.sageGreen.withValues(alpha: 0.12),
          highlightColor: AppColors.sageGreen.withValues(alpha: 0.06),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: effectiveRadius,
        border: cardBorder,
        boxShadow: cardShadows,
      ),
      clipBehavior: clipBehavior,
      child: content,
    );
  }
}
