import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Standard scaffold wrapper for the Mossy app.
///
/// Automatically enforces the cream background, provides safe area options,
/// consistent padding, and optional decorative background styling.
class MossyScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool safeArea;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final EdgeInsetsGeometry? padding;
  final bool? resizeToAvoidBottomInset;
  final Widget? drawer;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool showBackgroundGradients;

  const MossyScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.safeArea = true,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.padding,
    this.resizeToAvoidBottomInset,
    this.drawer,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.showBackgroundGradients = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    if (safeArea) {
      content = SafeArea(
        top: safeAreaTop,
        bottom: safeAreaBottom,
        child: content,
      );
    }

    if (showBackgroundGradients) {
      content = Stack(
        children: [
          // Soft ambient corner blobs
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mintGreen.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.peach.withValues(alpha: 0.25),
              ),
            ),
          ),
          content,
        ],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.cream,
      appBar: appBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      drawer: drawer,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
