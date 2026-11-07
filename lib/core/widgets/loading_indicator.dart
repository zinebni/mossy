import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

/// Themed loading widget featuring a pulsing, swaying nature leaf animation.
class LoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;
  final Color? color;
  final bool showBackgroundCircle;

  const LoadingIndicator({
    super.key,
    this.size = 54.0,
    this.message,
    this.color,
    this.showBackgroundCircle = true,
  });

  const LoadingIndicator.small({
    super.key,
    this.message,
    this.color,
  })  : size = 32.0,
        showBackgroundCircle = true;

  const LoadingIndicator.large({
    super.key,
    this.message = 'Looking closer...',
    this.color,
  })  : size = 72.0,
        showBackgroundCircle = true;

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.12).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? AppColors.sageGreen;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * math.pi,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: widget.showBackgroundCircle
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.mintGreen
                                    .withValues(alpha: _glowAnimation.value + 0.2),
                                AppColors.sageGreen
                                    .withValues(alpha: _glowAnimation.value * 0.4),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.sageGreen.withValues(
                                    alpha: _glowAnimation.value * 0.6),
                                blurRadius: widget.size * 0.35,
                                spreadRadius: widget.size * 0.05,
                              ),
                            ],
                          )
                        : null,
                    child: Center(
                      child: Icon(
                        Icons.eco_rounded,
                        size: widget.size * 0.58,
                        color: effectiveColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: GoogleFonts.quicksand(
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGreen,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full screen loading overlay with semi-transparent cream backdrop.
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({
    super.key,
    this.message = 'Looking closer...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream.withValues(alpha: 0.85),
      child: LoadingIndicator.large(message: message),
    );
  }
}
