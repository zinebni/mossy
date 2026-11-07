import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

/// A nature-crafted AppBar for Mossy with friendly rounded back button,
/// optional subtitle, organic typography, and transparent/cream backgrounds.
class MossyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const MossyAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.centerTitle = true,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.systemOverlayStyle,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final effectiveShowBack = showBackButton && canPop;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && effectiveShowBack) {
      effectiveLeading = Center(
        child: Container(
          margin: const EdgeInsets.only(left: 16.0),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.softList,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              splashColor: AppColors.sageGreen.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18.0,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null && title != null) {
      effectiveTitle = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title!,
            style: GoogleFonts.quicksand(
              fontSize: 19.0,
              fontWeight: FontWeight.w700,
              color: AppColors.darkGreen,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2.0),
            Text(
              subtitle!,
              style: GoogleFonts.nunito(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      );
    }

    return AppBar(
      title: effectiveTitle,
      centerTitle: centerTitle,
      leading: effectiveLeading,
      leadingWidth: effectiveShowBack ? 56.0 : null,
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: 8.0),
            ]
          : null,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: systemOverlayStyle ??
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
      bottom: bottom,
    );
  }
}
