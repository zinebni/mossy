import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../../shared/widgets/mascot/mascot_with_accessory.dart';

/// The four distinct stages of the onboarding process.
enum OnboardingStep {
  discover,
  learn,
  adventure,
  garden,
}

/// Rich vector & layered composition for the onboarding illustration area.
/// Pairs custom organic botanical backgrounds with themed Mossy mascot accessories.
class OnboardingIllustration extends StatelessWidget {
  final OnboardingStep step;

  const OnboardingIllustration({
    super.key,
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final mascotSize = math.min(w * 0.48, h * 0.44).clamp(130.0, 190.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Abstract botanical backdrop painter
            Positioned.fill(
              child: CustomPaint(
                painter: _BotanicalBackdropPainter(step: step),
              ),
            ),

            // 2. Animated botanical accent elements
            ..._buildAccentElements(step, w, h),

            // 3. Central Mascot with themed accessory and spring bounce entrance
            Positioned(
              child: _buildMascot(step, mascotSize)
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 650.ms,
                    curve: Curves.elasticOut,
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMascot(OnboardingStep step, double size) {
    switch (step) {
      case OnboardingStep.discover:
        return MascotWithAccessory(
          expression: MascotExpression.searching,
          accessory: MascotAccessory.magnifyingGlass,
          size: size,
        );
      case OnboardingStep.learn:
        return MascotWithAccessory(
          expression: MascotExpression.curious,
          accessory: MascotAccessory.book,
          size: size,
        );
      case OnboardingStep.adventure:
        return MascotWithAccessory(
          expression: MascotExpression.excited,
          accessory: MascotAccessory.backpack,
          size: size,
        );
      case OnboardingStep.garden:
        return MascotWithAccessory(
          expression: MascotExpression.celebrating,
          accessory: MascotAccessory.wateringCan,
          size: size,
        );
    }
  }

  List<Widget> _buildAccentElements(OnboardingStep step, double w, double h) {
    switch (step) {
      case OnboardingStep.discover:
        return [
          Positioned(
            left: w * 0.12,
            top: h * 0.18,
            child: _PollenSparkle(color: AppColors.butterYellow, size: 14)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -8, duration: 2200.ms),
          ),
          Positioned(
            right: w * 0.14,
            top: h * 0.22,
            child: _PollenSparkle(color: AppColors.sageGreen, size: 18)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: 10, duration: 2500.ms),
          ),
          Positioned(
            left: w * 0.20,
            bottom: h * 0.18,
            child: _PollenSparkle(color: AppColors.mintGreen, size: 12)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 1800.ms),
          ),
        ];

      case OnboardingStep.learn:
        return [
          Positioned(
            right: w * 0.18,
            top: h * 0.16,
            child: _InsightStar(color: AppColors.butterYellow, size: 24)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.15, 1.15), duration: 2000.ms),
          ),
          Positioned(
            left: w * 0.16,
            top: h * 0.24,
            child: _PollenSparkle(color: AppColors.lavender, size: 16)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -10, duration: 2800.ms),
          ),
          Positioned(
            right: w * 0.12,
            bottom: h * 0.20,
            child: _InsightStar(color: AppColors.peach, size: 18)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.1, 1.1), duration: 1900.ms),
          ),
        ];

      case OnboardingStep.adventure:
        return [
          Positioned(
            left: w * 0.15,
            top: h * 0.16,
            child: _BadgeSparkle(color: AppColors.butterYellow, size: 22)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -0.05, end: 0.05, duration: 2400.ms),
          ),
          Positioned(
            right: w * 0.18,
            top: h * 0.20,
            child: _PollenSparkle(color: AppColors.peach, size: 16)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: 8, duration: 2100.ms),
          ),
        ];

      case OnboardingStep.garden:
        return [
          Positioned(
            left: w * 0.14,
            top: h * 0.18,
            child: _PollenSparkle(color: AppColors.butterYellow, size: 20)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.2, 1.2), duration: 2200.ms),
          ),
          Positioned(
            right: w * 0.14,
            top: h * 0.18,
            child: _PollenSparkle(color: AppColors.mintGreen, size: 18)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -10, duration: 2600.ms),
          ),
        ];
    }
  }
}

// ==========================================
// CUSTOM BOTANICAL BACKGROUND PAINTER
// ==========================================

class _BotanicalBackdropPainter extends CustomPainter {
  final OnboardingStep step;

  const _BotanicalBackdropPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (step) {
      case OnboardingStep.discover:
        _paintDiscoverBackground(canvas, w, h);
        break;
      case OnboardingStep.learn:
        _paintLearnBackground(canvas, w, h);
        break;
      case OnboardingStep.adventure:
        _paintAdventureBackground(canvas, w, h);
        break;
      case OnboardingStep.garden:
        _paintGardenBackground(canvas, w, h);
        break;
    }
  }

  void _paintDiscoverBackground(Canvas canvas, double w, double h) {
    // 1. Soft layered circular glow
    final glowPaint = Paint()
      ..color = AppColors.mintGreen.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.38, glowPaint);

    final innerGlow = Paint()
      ..color = AppColors.butterYellow.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.44, h * 0.48), w * 0.28, innerGlow);

    // 2. Large Monstera / Leaf silhouette on the left
    final leafPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(w * 0.05, h * 0.85);
    leafPath.cubicTo(w * 0.02, h * 0.55, w * 0.25, h * 0.35, w * 0.32, h * 0.40);
    leafPath.cubicTo(w * 0.35, h * 0.60, w * 0.20, h * 0.82, w * 0.05, h * 0.85);
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    // 3. Daisy / Wildflower outline on the right
    final flowerStroke = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final flowerCenter = Offset(w * 0.82, h * 0.42);
    for (int i = 0; i < 8; i++) {
      final angle = i * (2 * math.pi / 8);
      final petalCenter = flowerCenter +
          Offset(math.cos(angle) * 16, math.sin(angle) * 16);
      canvas.drawCircle(petalCenter, 8, flowerStroke);
    }
    canvas.drawCircle(
      flowerCenter,
      7,
      Paint()..color = AppColors.butterYellow.withValues(alpha: 0.6),
    );

    // 4. Botanical fern sprig arcs at bottom right
    final fernPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fernStem = Path();
    fernStem.moveTo(w * 0.95, h * 0.88);
    fernStem.quadraticBezierTo(w * 0.78, h * 0.75, w * 0.72, h * 0.60);
    canvas.drawPath(fernStem, fernPaint);

    for (double t = 0.2; t <= 0.9; t += 0.2) {
      final p = Offset(w * (0.95 - t * 0.22), h * (0.88 - t * 0.28));
      canvas.drawLine(p, p + const Offset(-12, -8), fernPaint);
      canvas.drawLine(p, p + const Offset(10, -10), fernPaint);
    }
  }

  void _paintLearnBackground(Canvas canvas, double w, double h) {
    // 1. Lavender & Butter Yellow soft organic halo
    final halo1 = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.38, halo1);

    final halo2 = Paint()
      ..color = AppColors.butterYellow.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.56, h * 0.46), w * 0.26, halo2);

    // 2. Botanical specimen card outline in background
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.26, h * 0.42), width: 70, height: 95),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = AppColors.surfaceWhite.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = AppColors.lavender.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Mini leaf inside card
    final cardLeaf = Path();
    cardLeaf.moveTo(w * 0.26, h * 0.48);
    cardLeaf.quadraticBezierTo(w * 0.22, h * 0.38, w * 0.26, h * 0.35);
    cardLeaf.quadraticBezierTo(w * 0.30, h * 0.38, w * 0.26, h * 0.48);
    canvas.drawPath(cardLeaf, Paint()..color = AppColors.sageGreen.withValues(alpha: 0.4));

    // 3. Orbiting knowledge ring
    final orbitPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.54), width: w * 0.85, height: h * 0.45),
      orbitPaint,
    );
  }

  void _paintAdventureBackground(Canvas canvas, double w, double h) {
    // 1. Warm peach and mint backdrop
    final blobPaint = Paint()
      ..color = AppColors.peach.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.52), w * 0.38, blobPaint);

    final mintBlob = Paint()
      ..color = AppColors.mintGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.40, h * 0.44), w * 0.25, mintBlob);

    // 2. Rolling nature adventure trail hills
    final hillPath = Path();
    hillPath.moveTo(0, h * 0.80);
    hillPath.quadraticBezierTo(w * 0.3, h * 0.70, w * 0.6, h * 0.76);
    hillPath.quadraticBezierTo(w * 0.85, h * 0.82, w, h * 0.72);
    hillPath.lineTo(w, h);
    hillPath.lineTo(0, h);
    hillPath.close();

    final hillPaint = Paint()
      ..color = AppColors.mintGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawPath(hillPath, hillPaint);

    // 3. Dashed adventure quest trail
    final trailPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final trailPath = Path();
    trailPath.moveTo(w * 0.15, h * 0.76);
    trailPath.quadraticBezierTo(w * 0.35, h * 0.64, w * 0.5, h * 0.72);
    trailPath.quadraticBezierTo(w * 0.7, h * 0.80, w * 0.88, h * 0.68);

    // Draw dashed trail
    _drawDashedPath(canvas, trailPath, trailPaint, 5, 4);

    // 4. Little mountain peaks in the distant backdrop
    final peakPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final peakPath = Path();
    peakPath.moveTo(w * 0.65, h * 0.55);
    peakPath.lineTo(w * 0.78, h * 0.38);
    peakPath.lineTo(w * 0.92, h * 0.55);
    peakPath.close();
    canvas.drawPath(peakPath, peakPaint);
  }

  void _paintGardenBackground(Canvas canvas, double w, double h) {
    // 1. Lush Garden glow (Mint and butter yellow)
    final gardenGlow = Paint()
      ..color = AppColors.mintGreen.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.50), w * 0.39, gardenGlow);

    final sunGlow = Paint()
      ..color = AppColors.butterYellow.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.36), w * 0.24, sunGlow);

    // 2. Garden planter / mound arc
    final gardenMound = Path();
    gardenMound.moveTo(w * 0.1, h * 0.82);
    gardenMound.cubicTo(w * 0.3, h * 0.72, w * 0.7, h * 0.72, w * 0.9, h * 0.82);
    gardenMound.lineTo(w * 0.86, h * 0.88);
    gardenMound.cubicTo(w * 0.7, h * 0.82, w * 0.3, h * 0.82, w * 0.14, h * 0.88);
    gardenMound.close();

    final moundPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(gardenMound, moundPaint);

    // 3. Blooming little flowers sprouting from the soil
    _drawSproutingFlower(canvas, Offset(w * 0.24, h * 0.75), AppColors.peach);
    _drawSproutingFlower(canvas, Offset(w * 0.76, h * 0.75), AppColors.lavender);
  }

  void _drawSproutingFlower(Canvas canvas, Offset stemBase, Color petalColor) {
    // Tiny green stem
    final stemPaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(stemBase, stemBase + const Offset(0, -18), stemPaint);

    // Tiny side leaf
    final leafPaint = Paint()..color = AppColors.mintGreen;
    canvas.drawOval(
      Rect.fromCenter(
        center: stemBase + const Offset(4, -8),
        width: 8,
        height: 4,
      ),
      leafPaint,
    );

    // Flower blossom petals
    final blossomCenter = stemBase + const Offset(0, -22);
    final flowerPaint = Paint()..color = petalColor;
    canvas.drawCircle(blossomCenter + const Offset(-4, -2), 4, flowerPaint);
    canvas.drawCircle(blossomCenter + const Offset(4, -2), 4, flowerPaint);
    canvas.drawCircle(blossomCenter + const Offset(0, -5), 4, flowerPaint);
    canvas.drawCircle(
      blossomCenter,
      3,
      Paint()..color = AppColors.butterYellow,
    );
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        final extract = metric.extractPath(distance, next);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BotanicalBackdropPainter oldDelegate) {
    return oldDelegate.step != step;
  }
}

// ==========================================
// DECORATIVE ACCENT SHAPES
// ==========================================

class _PollenSparkle extends StatelessWidget {
  final Color color;
  final double size;

  const _PollenSparkle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.75),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _InsightStar extends StatelessWidget {
  final Color color;
  final double size;

  const _InsightStar({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: color,
    );
  }
}

class _BadgeSparkle extends StatelessWidget {
  final Color color;
  final double size;

  const _BadgeSparkle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.explore_rounded,
      size: size,
      color: color,
    );
  }
}
