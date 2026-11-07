import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum MascotVariant {
  happy,
  backpack,
  wateringCan,
  curious,
  celebrating,
}

/// Custom-drawn adorable Mossy mascot widget.
/// Mossy is a friendly little moss ball with a leafy sprout, big eyes, and warm smile.
class MossyMascot extends StatelessWidget {
  final double size;
  final MascotVariant variant;
  final String? speechBubble;

  const MossyMascot({
    super.key,
    this.size = 100,
    this.variant = MascotVariant.happy,
    this.speechBubble,
  });

  @override
  Widget build(BuildContext context) {
    Widget mascotWidget = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MossyPainter(variant: variant),
      ),
    );

    if (speechBubble == null) {
      return mascotWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            speechBubble!,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        mascotWidget,
      ],
    );
  }
}

class _MossyPainter extends CustomPainter {
  final MascotVariant variant;

  _MossyPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.58);
    final radius = size.width * 0.36;

    // Soft ground shadow
    final shadowPaint = Paint()
      ..color = AppColors.darkText.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.94),
        width: radius * 1.8,
        height: radius * 0.4,
      ),
      shadowPaint,
    );

    // Draw backpack behind body if backpack variant
    if (variant == MascotVariant.backpack) {
      _drawBackpack(canvas, center, radius);
    }

    // Body (fuzzy moss ball gradient)
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 0.9,
        colors: const [
          Color(0xFF9EBA93),
          AppColors.sageGreen,
          Color(0xFF6E8865),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, bodyPaint);

    // Fluffy texture puffs around edge
    final puffPaint = Paint()
      ..color = AppColors.sageGreen.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 14; i++) {
      final angle = (i * 2 * math.pi) / 14;
      final puffX = center.dx + (radius + 2) * math.cos(angle);
      final puffY = center.dy + (radius + 2) * math.sin(angle);
      canvas.drawCircle(Offset(puffX, puffY), radius * 0.22, puffPaint);
    }

    // Sprout antenna / leaf on head
    _drawSprout(canvas, center, radius);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = AppColors.peach.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.52, center.dy + radius * 0.15),
      radius * 0.2,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.52, center.dy + radius * 0.15),
      radius * 0.2,
      cheekPaint,
    );

    // Eyes
    final eyePaint = Paint()
      ..color = AppColors.darkText
      ..style = PaintingStyle.fill;
    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final leftEye = Offset(center.dx - radius * 0.32, center.dy - radius * 0.05);
    final rightEye = Offset(center.dx + radius * 0.32, center.dy - radius * 0.05);
    final eyeRadius = radius * 0.14;

    if (variant == MascotVariant.celebrating) {
      // Happy squint curves
      final winkPaint = Paint()
        ..color = AppColors.darkText
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: leftEye, radius: eyeRadius * 1.2),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        winkPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: rightEye, radius: eyeRadius * 1.2),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        winkPaint,
      );
    } else {
      // Big expressive eyes
      canvas.drawCircle(leftEye, eyeRadius, eyePaint);
      canvas.drawCircle(rightEye, eyeRadius, eyePaint);

      // Eye shines
      canvas.drawCircle(
        Offset(leftEye.dx - eyeRadius * 0.35, leftEye.dy - eyeRadius * 0.35),
        eyeRadius * 0.42,
        shinePaint,
      );
      canvas.drawCircle(
        Offset(rightEye.dx - eyeRadius * 0.35, rightEye.dy - eyeRadius * 0.35),
        eyeRadius * 0.42,
        shinePaint,
      );
    }

    // Smile
    final smilePaint = Paint()
      ..color = AppColors.darkText
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final mouthRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.25),
      width: radius * 0.45,
      height: radius * 0.3,
    );
    canvas.drawArc(mouthRect, 0.1, math.pi - 0.2, false, smilePaint);

    // Watering can accessory
    if (variant == MascotVariant.wateringCan) {
      _drawWateringCan(canvas, center, radius);
    }
  }

  void _drawSprout(Canvas canvas, Offset center, double radius) {
    final sproutPaint = Paint()
      ..color = const Color(0xFF6A9A4A)
      ..style = PaintingStyle.fill;

    // Small stem
    final stemPaint = Paint()
      ..color = const Color(0xFF537C39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final stemStart = Offset(center.dx, center.dy - radius * 0.95);
    final stemEnd = Offset(center.dx - 2, center.dy - radius * 1.35);
    canvas.drawLine(stemStart, stemEnd, stemPaint);

    // Left leaf
    final leafPath = Path();
    leafPath.moveTo(stemEnd.dx, stemEnd.dy);
    leafPath.quadraticBezierTo(
      stemEnd.dx - radius * 0.35,
      stemEnd.dy - radius * 0.25,
      stemEnd.dx - radius * 0.45,
      stemEnd.dy + radius * 0.05,
    );
    leafPath.quadraticBezierTo(
      stemEnd.dx - radius * 0.15,
      stemEnd.dy + radius * 0.1,
      stemEnd.dx,
      stemEnd.dy,
    );
    leafPath.close();
    canvas.drawPath(leafPath, sproutPaint);

    // Right leaf
    final rightLeaf = Path();
    rightLeaf.moveTo(stemEnd.dx, stemEnd.dy);
    rightLeaf.quadraticBezierTo(
      stemEnd.dx + radius * 0.35,
      stemEnd.dy - radius * 0.15,
      stemEnd.dx + radius * 0.4,
      stemEnd.dy + radius * 0.15,
    );
    rightLeaf.quadraticBezierTo(
      stemEnd.dx + radius * 0.15,
      stemEnd.dy + radius * 0.15,
      stemEnd.dx,
      stemEnd.dy,
    );
    rightLeaf.close();
    canvas.drawPath(rightLeaf, sproutPaint);
  }

  void _drawBackpack(Canvas canvas, Offset center, double radius) {
    final packPaint = Paint()
      ..color = const Color(0xFFB5704D)
      ..style = PaintingStyle.fill;
    final pocketPaint = Paint()
      ..color = const Color(0xFF8F5134)
      ..style = PaintingStyle.fill;

    // Backpack behind right side
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx + radius * 0.4,
        center.dy - radius * 0.4,
        radius * 0.6,
        radius * 0.85,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, packPaint);

    // Backpack flap
    final flap = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx + radius * 0.45,
        center.dy - radius * 0.1,
        radius * 0.5,
        radius * 0.4,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(flap, pocketPaint);
  }

  void _drawWateringCan(Canvas canvas, Offset center, double radius) {
    final canPaint = Paint()
      ..color = const Color(0xFF67B0D1)
      ..style = PaintingStyle.fill;

    // Can body
    final canRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        center.dx + radius * 0.45,
        center.dy + radius * 0.1,
        radius * 0.55,
        radius * 0.45,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(canRect, canPaint);

    // Spout
    final spoutPaint = Paint()
      ..color = const Color(0xFF4C98BD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final spoutStart = Offset(center.dx + radius * 0.95, center.dy + radius * 0.4);
    final spoutEnd = Offset(center.dx + radius * 1.3, center.dy + radius * 0.15);
    canvas.drawLine(spoutStart, spoutEnd, spoutPaint);

    // Water droplet
    final dropPaint = Paint()
      ..color = const Color(0xFF8FD8F8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(spoutEnd.dx + 4, spoutEnd.dy + 8),
      3.5,
      dropPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MossyPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
