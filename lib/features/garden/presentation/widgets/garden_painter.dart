import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// CustomPainter that draws a charming botanical garden scene.
/// Level 1–10 progressively adds more plant life and elements.
class GardenPainter extends CustomPainter {
  final int level;
  const GardenPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFD9E8CF), Color(0xFFF7F3E9)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Ground
    final groundPaint = Paint()..color = const Color(0xFF8C6D58).withAlpha(80);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), const Radius.circular(0)), groundPaint);

    // Grass
    final grassPaint = Paint()..color = AppColors.mintGreen.withAlpha(180)..strokeWidth = 3..style = PaintingStyle.stroke;
    final random = math.Random(42);
    final grassCount = 20 + level * 5;
    for (int i = 0; i < grassCount; i++) {
      final x = random.nextDouble() * w;
      final baseY = h * 0.7;
      final height = 15.0 + random.nextDouble() * 20;
      final path = Path()
        ..moveTo(x, baseY)
        ..quadraticBezierTo(x + (random.nextDouble() - 0.5) * 10, baseY - height / 2, x + (random.nextDouble() - 0.5) * 8, baseY - height);
      canvas.drawPath(path, grassPaint);
    }

    // Level-based elements
    if (level >= 2) _drawMossPatches(canvas, size);
    if (level >= 3) _drawFlowers(canvas, size, count: 3 + level);
    if (level >= 4) _drawBush(canvas, size, x: w * 0.15, y: h * 0.68);
    if (level >= 5) _drawBush(canvas, size, x: w * 0.75, y: h * 0.65);
    if (level >= 6) _drawTree(canvas, size, x: w * 0.8, y: h * 0.6, scale: 0.5);
    if (level >= 7) _drawTree(canvas, size, x: w * 0.2, y: h * 0.55, scale: 0.7);
    if (level >= 8) _drawPond(canvas, size);
    if (level >= 9) _drawBirds(canvas, size);
    if (level >= 10) _drawSun(canvas, size);

    // Mossy mascot silhouette (small, decorative)
    _drawMascotSilhouette(canvas, size);
  }

  void _drawMossPatches(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.sageGreen.withAlpha(100);
    final r = math.Random(99);
    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.1 + r.nextDouble() * 0.8);
      final y = size.height * (0.72 + r.nextDouble() * 0.1);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 30 + r.nextDouble() * 20, height: 10 + r.nextDouble() * 6), paint);
    }
  }

  void _drawFlowers(Canvas canvas, Size size, {required int count}) {
    final r = math.Random(123);
    final stemPaint = Paint()..color = AppColors.sageGreen..strokeWidth = 2..style = PaintingStyle.stroke;
    final colors = [AppColors.peach, AppColors.butterYellow, AppColors.lavender, const Color(0xFFFF9EAA), Colors.white];
    for (int i = 0; i < count; i++) {
      final x = size.width * (0.05 + r.nextDouble() * 0.9);
      final baseY = size.height * 0.7;
      final stemH = 25.0 + r.nextDouble() * 20;
      final petalR = 5.0 + r.nextDouble() * 4;
      final centerY = baseY - stemH;
      // Stem
      canvas.drawLine(Offset(x, baseY), Offset(x, centerY), stemPaint);
      // Petals
      final petalPaint = Paint()..color = colors[i % colors.length];
      for (int p = 0; p < 6; p++) {
        final angle = p * math.pi / 3;
        canvas.drawCircle(Offset(x + math.cos(angle) * petalR, centerY + math.sin(angle) * petalR), petalR, petalPaint);
      }
      // Center
      canvas.drawCircle(Offset(x, centerY), petalR * 0.5, Paint()..color = AppColors.butterYellow);
    }
  }

  void _drawBush(Canvas canvas, Size size, {required double x, required double y}) {
    final paint = Paint()..color = AppColors.sageGreen.withAlpha(200);
    canvas.drawCircle(Offset(x, y), 22, paint);
    canvas.drawCircle(Offset(x + 18, y + 5), 16, paint);
    canvas.drawCircle(Offset(x - 15, y + 5), 16, paint);
    canvas.drawCircle(Offset(x + 5, y - 15), 14, paint);
  }

  void _drawTree(Canvas canvas, Size size, {required double x, required double y, required double scale}) {
    final trunkPaint = Paint()..color = const Color(0xFF8C6D58);
    final leafPaint = Paint()..color = AppColors.sageGreen.withAlpha(220);
    final w = 10.0 * scale;
    final h = 40.0 * scale;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + h / 2), width: w, height: h), Radius.circular(w / 2)), trunkPaint);
    canvas.drawCircle(Offset(x, y - 10 * scale), 30 * scale, leafPaint);
    canvas.drawCircle(Offset(x - 15 * scale, y + 5 * scale), 20 * scale, leafPaint);
    canvas.drawCircle(Offset(x + 15 * scale, y + 5 * scale), 20 * scale, leafPaint);
  }

  void _drawPond(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFCDE3E8).withAlpha(180);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.78), width: 90, height: 30), paint);
  }

  void _drawBirds(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.sageGreen.withAlpha(160)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (final pos in [Offset(size.width * 0.3, size.height * 0.2), Offset(size.width * 0.5, size.height * 0.15)]) {
      final path = Path()
        ..moveTo(pos.dx - 8, pos.dy)
        ..quadraticBezierTo(pos.dx - 4, pos.dy - 4, pos.dx, pos.dy)
        ..quadraticBezierTo(pos.dx + 4, pos.dy - 4, pos.dx + 8, pos.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.butterYellow.withAlpha(120);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.12), 20, paint);
  }

  void _drawMascotSilhouette(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.sageGreen.withAlpha(60);
    final x = size.width * 0.5;
    final y = size.height * 0.68;
    // Simple blob
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 24, height: 20), paint);
    // Eyes
    canvas.drawCircle(Offset(x - 5, y - 2), 2, Paint()..color = Colors.white.withAlpha(180));
    canvas.drawCircle(Offset(x + 5, y - 2), 2, Paint()..color = Colors.white.withAlpha(180));
  }

  @override
  bool shouldRepaint(GardenPainter oldDelegate) => oldDelegate.level != level;
}
