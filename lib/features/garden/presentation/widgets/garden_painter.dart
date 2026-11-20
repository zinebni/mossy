import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A touch-spawned celebration particle on the garden canvas.
class GardenTapParticle {
  final Offset position;
  final Color color;
  final double size;
  final double vx;
  final double vy;
  final double createdAt; // time in seconds
  final String symbol;

  const GardenTapParticle({
    required this.position,
    required this.color,
    required this.size,
    required this.vx,
    required this.vy,
    required this.createdAt,
    required this.symbol,
  });
}

/// CustomPainter rendering a blossoming botanical sanctuary that levels up
/// from a humble Moss Patch to a breathtaking Botanical Wonderland.
///
/// Features smooth 60fps animations:
/// - Swaying grass blades, ferns, and wildflowers
/// - Drifting clouds and pulsating warm sunbeams
/// - Fluttering butterflies with animated flapping wings
/// - Concentric pond water ripples and floating lotus pads
/// - Falling blossom petals and rising golden firefly sparkles
/// - Grand archways, sparkling fountain streams, and rainbow mist
/// - Animated breathing & blinking Mossy sanctuary mascot
class GardenPainter extends CustomPainter {
  final int level;
  final double animationValue; // continuous time in seconds (e.g. controller.value * 2 * pi or elapsed)
  final List<GardenTapParticle> touchParticles;

  const GardenPainter({
    required this.level,
    this.animationValue = 0.0,
    this.touchParticles = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final t = animationValue;

    // 1. Sky & Atmosphere
    _drawSky(canvas, size, t);

    // 2. Distant Hills (rolling green backdrop)
    _drawRollingHills(canvas, size, t);

    // 3. Ground & Earth layers
    _drawGround(canvas, size);

    // 4. Velvet Moss Carpets & Stepping Stones (Level >= 2)
    if (level >= 2) {
      _drawMossPatches(canvas, size, t);
      _drawSteppingStones(canvas, size);
    }

    // 5. Pond & Water Lilies (Level >= 7)
    if (level >= 7) {
      _drawPond(canvas, size, t);
    }

    // 6. Cobblestone Path & Wooden Bridge (Level >= 6)
    if (level >= 6) {
      _drawCobblestonePath(canvas, size);
    }
    if (level >= 8) {
      _drawWoodenBridge(canvas, size);
    }

    // 7. Swaying Grass & Flora
    _drawSwayingGrass(canvas, size, t);

    // 8. Wildflowers & Ferns (Level >= 3)
    if (level >= 3) {
      _drawWildflowers(canvas, size, t);
    }
    if (level >= 4) {
      _drawFernClusters(canvas, size, t);
      _drawWoodenBench(canvas, size);
    }

    // 9. Shrubs & Trees (Level >= 5, 6, 7, 9)
    if (level >= 5) {
      _drawFloweringBush(canvas, size, x: w * 0.82, y: h * 0.66, t: t, flowerColor: AppColors.peach);
    }
    if (level >= 6) {
      _drawFloweringBush(canvas, size, x: w * 0.12, y: h * 0.69, t: t, flowerColor: const Color(0xFFFF9EAA));
      _drawSaplingTree(canvas, size, x: w * 0.88, y: h * 0.58, scale: 0.65, t: t);
    }
    if (level >= 7) {
      _drawSaplingTree(canvas, size, x: w * 0.18, y: h * 0.54, scale: 0.85, t: t);
    }
    if (level >= 9) {
      _drawAncientOakCanopy(canvas, size, t);
    }

    // 10. Grand Fountain & Botanical Shrine (Level 10)
    if (level >= 10) {
      _drawGrandFountain(canvas, size, t);
      _drawRainbowMist(canvas, size, t);
    }

    // 11. Animated Mossy Sanctuary Mascot
    _drawAnimatedMossyMascot(canvas, size, t);

    // 12. Animated Fluttering Butterflies (Level >= 4)
    if (level >= 4) {
      _drawButterflies(canvas, size, t);
    }

    // 13. Falling Petals & Rising Fireflies (Level >= 8, 9)
    if (level >= 5) {
      _drawFallingPetals(canvas, size, t);
    }
    if (level >= 9) {
      _drawFireflies(canvas, size, t);
    }

    // 14. Interactive Touch Tap Particles
    _drawTouchParticles(canvas, size, t);
  }

  void _drawSky(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // Palette warms and enriches with higher levels
    final List<Color> skyColors;
    if (level >= 9) {
      // Twilight / enchanted wonderland palette
      skyColors = [const Color(0xFFC8E6C9), const Color(0xFFFFE0B2), const Color(0xFFF9F7F1)];
    } else if (level >= 5) {
      // Bright vibrant sunny day
      skyColors = [const Color(0xFFD4EAD6), const Color(0xFFFFF3CD), const Color(0xFFFBF9F3)];
    } else {
      // Gentle soft morning
      skyColors = [const Color(0xFFE2EFE0), const Color(0xFFF7F5EB)];
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Animated Sun / Sunbeams (Level >= 3)
    final sunX = w * 0.18;
    final sunY = h * 0.16;
    final sunPulse = 1.0 + 0.06 * math.sin(t * 1.5);
    final sunRadius = (level >= 10 ? 32.0 : (level >= 5 ? 24.0 : 18.0)) * sunPulse;

    // Outer glow
    final sunGlow = Paint()
      ..color = const Color(0xFFFFE082).withAlpha(level >= 10 ? 80 : 50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius * 1.8, sunGlow);

    // Sun core
    final sunPaint = Paint()..color = const Color(0xFFFFF176).withAlpha(190);
    canvas.drawCircle(Offset(sunX, sunY), sunRadius, sunPaint);

    // Drifting Fluffy Clouds
    _drawDriftingClouds(canvas, size, t);
  }

  void _drawDriftingClouds(Canvas canvas, Size size, double t) {
    final cloudPaint = Paint()..color = Colors.white.withAlpha(160);
    final w = size.width;

    final clouds = [
      {'baseX': w * 0.1, 'y': size.height * 0.12, 'speed': 6.0, 'scale': 0.8},
      {'baseX': w * 0.55, 'y': size.height * 0.08, 'speed': 8.5, 'scale': 1.1},
      {'baseX': w * 0.85, 'y': size.height * 0.16, 'speed': 5.0, 'scale': 0.7},
    ];

    for (final c in clouds) {
      final bx = c['baseX']!;
      final cy = c['y']!;
      final spd = c['speed']!;
      final sc = c['scale']!;

      final cx = (bx + t * spd) % (w + 120) - 60;

      canvas.drawCircle(Offset(cx, cy), 14 * sc, cloudPaint);
      canvas.drawCircle(Offset(cx - 12 * sc, cy + 3 * sc), 10 * sc, cloudPaint);
      canvas.drawCircle(Offset(cx + 12 * sc, cy + 3 * sc), 11 * sc, cloudPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + 8 * sc), width: 36 * sc, height: 12 * sc), cloudPaint);
    }
  }

  void _drawRollingHills(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    // Distant hill
    final hillPaint1 = Paint()..color = const Color(0xFFBACDB5).withAlpha(130);
    final path1 = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.35, h * 0.52, w * 0.75, h * 0.65)
      ..quadraticBezierTo(w * 0.9, h * 0.68, w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path1, hillPaint1);

    // Mid hill
    final hillPaint2 = Paint()..color = const Color(0xFFA5C49E).withAlpha(150);
    final path2 = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.25, h * 0.60, w * 0.55, h * 0.67)
      ..quadraticBezierTo(w * 0.85, h * 0.58, w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path2, hillPaint2);
  }

  void _drawGround(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Deep rich earth base
    final earthPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8D735C), Color(0xFF6B5441)],
      ).createShader(Rect.fromLTWH(0, h * 0.68, w, h * 0.32));

    final groundPath = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.3, h * 0.68, w * 0.6, h * 0.70)
      ..quadraticBezierTo(w * 0.85, h * 0.71, w, h * 0.69)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(groundPath, earthPaint);

    // Soft humus layer
    final humusPaint = Paint()..color = const Color(0xFF7A614A).withAlpha(110);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.74, w, h * 0.26), humusPaint);
  }

  void _drawMossPatches(Canvas canvas, Size size, double t) {
    final mossPaint = Paint()..color = const Color(0xFF73A96E).withAlpha(180);
    final lightMossPaint = Paint()..color = const Color(0xFF90C289).withAlpha(160);

    final patches = [
      Offset(size.width * 0.15, size.height * 0.73),
      Offset(size.width * 0.38, size.height * 0.75),
      Offset(size.width * 0.62, size.height * 0.72),
      Offset(size.width * 0.84, size.height * 0.76),
      Offset(size.width * 0.48, size.height * 0.78),
    ];

    for (int i = 0; i < patches.length; i++) {
      final p = patches[i];
      final r = 18.0 + (i % 3) * 6;
      canvas.drawOval(Rect.fromCenter(center: p, width: r * 2.2, height: r * 0.9), mossPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(p.dx - 3, p.dy - 2), width: r * 1.5, height: r * 0.6), lightMossPaint);
    }
  }

  void _drawSteppingStones(Canvas canvas, Size size) {
    final stonePaint = Paint()..color = const Color(0xFFB0A89F);
    final shadowPaint = Paint()..color = const Color(0xFF6B5C52).withAlpha(90);

    final stones = [
      Offset(size.width * 0.25, size.height * 0.77),
      Offset(size.width * 0.32, size.height * 0.79),
      Offset(size.width * 0.40, size.height * 0.78),
      Offset(size.width * 0.47, size.height * 0.80),
      Offset(size.width * 0.55, size.height * 0.81),
    ];

    for (final st in stones) {
      canvas.drawOval(Rect.fromCenter(center: Offset(st.dx, st.dy + 2), width: 18, height: 10), shadowPaint);
      canvas.drawOval(Rect.fromCenter(center: st, width: 17, height: 9), stonePaint);
      // Highlight dot
      canvas.drawCircle(Offset(st.dx - 3, st.dy - 1), 2, Paint()..color = Colors.white.withAlpha(100));
    }
  }

  void _drawSwayingGrass(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;

    final grassCount = 28 + level * 6;
    final grassPaint = Paint()
      ..color = const Color(0xFF5E9C57).withAlpha(220)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final darkGrassPaint = Paint()
      ..color = const Color(0xFF4A8044).withAlpha(190)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rng = math.Random(555);

    for (int i = 0; i < grassCount; i++) {
      final x = (i / grassCount) * w + (rng.nextDouble() - 0.5) * 8;
      final baseY = h * 0.70 + (rng.nextDouble() * 12);
      final height = 14.0 + (rng.nextDouble() * 18);
      // Wind sway sinusoidal calculation
      final sway = math.sin(t * 2.2 + x * 0.04) * (5.0 + rng.nextDouble() * 4.0);

      final p = Path()
        ..moveTo(x, baseY)
        ..quadraticBezierTo(x + sway * 0.4, baseY - height * 0.5, x + sway, baseY - height);

      canvas.drawPath(p, (i % 2 == 0) ? grassPaint : darkGrassPaint);
    }
  }

  void _drawWildflowers(Canvas canvas, Size size, double t) {
    final w = size.width;
    final h = size.height;
    final count = 4 + level * 2;
    final rng = math.Random(789);

    final colors = [
      const Color(0xFFFF85A1), // soft pink
      const Color(0xFFFFD166), // golden yellow
      const Color(0xFF06D6A0), // sea mint
      const Color(0xFFB388EB), // purple lilac
      const Color(0xFFFF9F1C), // orange
      Colors.white,
    ];

    final stemPaint = Paint()
      ..color = const Color(0xFF538D4E)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final x = (rng.nextDouble() * 0.9 + 0.05) * w;
      final baseY = h * 0.70 + rng.nextDouble() * 10;
      final stemH = 22.0 + rng.nextDouble() * 20;
      final petalR = 4.5 + rng.nextDouble() * 3.5;

      final sway = math.sin(t * 2.0 + x * 0.05) * 4.5;
      final flowerX = x + sway;
      final flowerY = baseY - stemH;

      // Stem
      canvas.drawLine(Offset(x, baseY), Offset(flowerX, flowerY), stemPaint);

      // Petals
      final flowerColor = colors[i % colors.length];
      final petalPaint = Paint()..color = flowerColor;
      final petalCount = 5 + (i % 3);

      for (int p = 0; p < petalCount; p++) {
        final angle = (p * 2 * math.pi / petalCount) + (t * 0.5);
        final px = flowerX + math.cos(angle) * petalR;
        final py = flowerY + math.sin(angle) * petalR;
        canvas.drawCircle(Offset(px, py), petalR * 0.65, petalPaint);
      }

      // Flower core
      canvas.drawCircle(Offset(flowerX, flowerY), petalR * 0.5, Paint()..color = const Color(0xFFFFD166));
    }
  }

  void _drawFernClusters(Canvas canvas, Size size, double t) {
    final fernPaint = Paint()
      ..color = const Color(0xFF388E3C).withAlpha(200)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final clusters = [
      Offset(size.width * 0.08, size.height * 0.69),
      Offset(size.width * 0.72, size.height * 0.68),
    ];

    for (final c in clusters) {
      for (int f = -2; f <= 2; f++) {
        final sway = math.sin(t * 1.8 + f) * 3.0;
        final path = Path()
          ..moveTo(c.dx, c.dy)
          ..quadraticBezierTo(c.dx + f * 7 + sway, c.dy - 16, c.dx + f * 12 + sway, c.dy - 28);
        canvas.drawPath(path, fernPaint);
      }
    }
  }

  void _drawWoodenBench(Canvas canvas, Size size) {
    final x = size.width * 0.38;
    final y = size.height * 0.72;
    final woodPaint = Paint()..color = const Color(0xFF795548);
    final darkWood = Paint()..color = const Color(0xFF4E342E);

    // Bench legs
    canvas.drawRect(Rect.fromLTWH(x - 16, y + 6, 4, 12), darkWood);
    canvas.drawRect(Rect.fromLTWH(x + 12, y + 6, 4, 12), darkWood);
    // Bench seat
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, y + 2, 40, 5), const Radius.circular(2)), woodPaint);
    // Bench backrest
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, y - 10, 40, 5), const Radius.circular(2)), woodPaint);
    canvas.drawRect(Rect.fromLTWH(x - 16, y - 8, 3, 10), darkWood);
    canvas.drawRect(Rect.fromLTWH(x + 13, y - 8, 3, 10), darkWood);
  }

  void _drawCobblestonePath(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pathPaint = Paint()..color = const Color(0xFFBDBDBD).withAlpha(120);

    for (int i = 0; i < 7; i++) {
      final cx = w * 0.58 + math.sin(i * 0.6) * 16;
      final cy = h * 0.72 + i * 7.0;
      canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 14 + (i % 2) * 4, height: 6), pathPaint);
    }
  }

  void _drawPond(Canvas canvas, Size size, double t) {
    final cx = size.width * 0.52;
    final cy = size.height * 0.78;
    final w = size.width * 0.32;
    final h = 34.0;

    // Pond water bed
    final pondPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF81D4FA), Color(0xFF29B6F6)],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h), pondPaint);

    // Concentric Animated Water Ripples
    final ripplePhase = (t * 1.5) % 1.0;
    final rippleRadius = 10.0 + ripplePhase * 24.0;
    final rippleAlpha = ((1.0 - ripplePhase) * 160).clamp(0, 255).toInt();
    final ripplePaint = Paint()
      ..color = Colors.white.withAlpha(rippleAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: rippleRadius * 2.2, height: rippleRadius * 0.7), ripplePaint);

    // Floating Lily Pad & Pink Lotus
    final padX = cx - w * 0.22;
    final padY = cy - 2;
    final padPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.drawCircle(Offset(padX, padY), 7, padPaint);
    // Lotus flower
    canvas.drawCircle(Offset(padX, padY - 2), 3.5, Paint()..color = const Color(0xFFFF4081));
    canvas.drawCircle(Offset(padX, padY - 2), 1.5, Paint()..color = const Color(0xFFFFEB3B));
  }

  void _drawWoodenBridge(Canvas canvas, Size size) {
    final cx = size.width * 0.52;
    final cy = size.height * 0.76;
    final w = size.width * 0.22;

    final bridgePaint = Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 3.5..style = PaintingStyle.stroke;
    final railPath = Path()
      ..moveTo(cx - w * 0.5, cy + 4)
      ..quadraticBezierTo(cx, cy - 8, cx + w * 0.5, cy + 4);
    canvas.drawPath(railPath, bridgePaint);

    // Planks
    final plankPaint = Paint()..color = const Color(0xFFA1887F);
    for (int i = 0; i <= 6; i++) {
      final px = cx - w * 0.45 + (i / 6.0) * (w * 0.9);
      final py = cy - 3 + math.sin(i * math.pi / 6.0) * -3;
      canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: 3, height: 8), plankPaint);
    }
  }

  void _drawFloweringBush(Canvas canvas, Size size, {
    required double x,
    required double y,
    required double t,
    required Color flowerColor,
  }) {
    final bushPaint = Paint()..color = const Color(0xFF43A047).withAlpha(220);
    final darkBush = Paint()..color = const Color(0xFF2E7D32).withAlpha(220);

    final sway = math.sin(t * 1.6 + x) * 2.5;

    canvas.drawCircle(Offset(x - 14 + sway, y + 4), 18, darkBush);
    canvas.drawCircle(Offset(x + 14 + sway, y + 4), 18, darkBush);
    canvas.drawCircle(Offset(x + sway, y - 6), 22, bushPaint);

    // Flower buds
    final flPaint = Paint()..color = flowerColor;
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5;
      final bx = x + math.cos(angle) * 12 + sway;
      final by = y - 4 + math.sin(angle) * 10;
      canvas.drawCircle(Offset(bx, by), 3.5, flPaint);
    }
  }

  void _drawSaplingTree(Canvas canvas, Size size, {
    required double x,
    required double y,
    required double scale,
    required double t,
  }) {
    final trunkPaint = Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 9.0 * scale..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = const Color(0xFF4CAF50).withAlpha(230);
    final topLeafPaint = Paint()..color = const Color(0xFF81C784).withAlpha(230);

    final trunkH = 50.0 * scale;
    final sway = math.sin(t * 1.5 + x) * (4.0 * scale);

    // Trunk
    canvas.drawLine(Offset(x, y + trunkH), Offset(x + sway * 0.4, y), trunkPaint);

    // Foliage puffs
    final leafR = 30.0 * scale;
    canvas.drawCircle(Offset(x - 14 * scale + sway, y - 6 * scale), leafR * 0.85, leafPaint);
    canvas.drawCircle(Offset(x + 14 * scale + sway, y - 6 * scale), leafR * 0.85, leafPaint);
    canvas.drawCircle(Offset(x + sway, y - 22 * scale), leafR, topLeafPaint);

    // Fruit / blossoms on tree
    final fruitPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(Offset(x - 8 * scale + sway, y - 10 * scale), 3 * scale, fruitPaint);
    canvas.drawCircle(Offset(x + 10 * scale + sway, y - 16 * scale), 3 * scale, fruitPaint);
    canvas.drawCircle(Offset(x + 2 * scale + sway, y - 26 * scale), 3 * scale, fruitPaint);
  }

  void _drawAncientOakCanopy(Canvas canvas, Size size, double t) {
    final x = size.width * 0.85;
    final y = size.height * 0.48;
    final sway = math.sin(t * 1.2) * 4.0;

    final trunkPaint = Paint()..color = const Color(0xFF4E342E)..strokeWidth = 16.0..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, size.height * 0.72), Offset(x + sway * 0.3, y), trunkPaint);

    // Lush ancient canopy
    final canopyPaint = Paint()..color = const Color(0xFF2E7D32).withAlpha(240);
    final highCanopy = Paint()..color = const Color(0xFF66BB6A).withAlpha(220);

    canvas.drawCircle(Offset(x - 30 + sway, y - 10), 40, canopyPaint);
    canvas.drawCircle(Offset(x + 25 + sway, y - 8), 36, canopyPaint);
    canvas.drawCircle(Offset(x + sway, y - 36), 46, highCanopy);
  }

  void _drawGrandFountain(Canvas canvas, Size size, double t) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.67;

    final stonePaint = Paint()..color = const Color(0xFFCFD8DC);
    final darkStone = Paint()..color = const Color(0xFF90A4AE);

    // Fountain pedestal & tiered basin
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 10), width: 18, height: 16), darkStone);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 48, height: 14), stonePaint);

    // Water jets
    final jetPaint = Paint()
      ..color = const Color(0xFF80D8FF).withAlpha(210)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final waterArcH = 22.0 + math.sin(t * 4.0) * 3.0;

    // Center spout
    final jet1 = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(cx - 10, cy - waterArcH, cx - 18, cy + 4);
    final jet2 = Path()
      ..moveTo(cx, cy)
      ..quadraticBezierTo(cx + 10, cy - waterArcH, cx + 18, cy + 4);

    canvas.drawPath(jet1, jetPaint);
    canvas.drawPath(jet2, jetPaint);

    // Water droplets
    final dropPaint = Paint()..color = Colors.white.withAlpha(230);
    canvas.drawCircle(Offset(cx - 14, cy - waterArcH * 0.6), 2, dropPaint);
    canvas.drawCircle(Offset(cx + 14, cy - waterArcH * 0.6), 2, dropPaint);
  }

  void _drawRainbowMist(Canvas canvas, Size size, double t) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.46;
    final r = 60.0;

    final rainbowColors = [
      const Color(0xFFFF5252).withAlpha(50),
      const Color(0xFFFFD740).withAlpha(50),
      const Color(0xFF69F0AE).withAlpha(50),
      const Color(0xFF40C4FF).withAlpha(50),
      const Color(0xFFE040FB).withAlpha(50),
    ];

    for (int i = 0; i < rainbowColors.length; i++) {
      final p = Paint()
        ..color = rainbowColors[i]
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy), width: (r + i * 4) * 2, height: (r + i * 4) * 1.5),
        math.pi * 1.1,
        math.pi * 0.8,
        false,
        p,
      );
    }
  }

  void _drawAnimatedMossyMascot(Canvas canvas, Size size, double t) {
    final mx = size.width * 0.38;
    // Gentle breathing & bouncing rhythm
    final my = size.height * 0.68 + math.sin(t * 3.0) * 2.2;

    // Body
    final mascotPaint = Paint()..color = AppColors.sageGreen;
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my), width: 26, height: 22), mascotPaint);

    // Belly highlight
    final bellyPaint = Paint()..color = AppColors.mintGreen.withAlpha(160);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx, my + 3), width: 14, height: 11), bellyPaint);

    // Eyes: blink every 4 seconds
    final blinkPhase = (t * 0.8) % 3.0;
    final isBlinking = blinkPhase < 0.15;

    final eyePaint = Paint()..color = const Color(0xFF263238);
    if (isBlinking) {
      canvas.drawLine(Offset(mx - 6, my - 2), Offset(mx - 2, my - 2), eyePaint..strokeWidth = 1.5);
      canvas.drawLine(Offset(mx + 2, my - 2), Offset(mx + 6, my - 2), eyePaint..strokeWidth = 1.5);
    } else {
      canvas.drawCircle(Offset(mx - 4, my - 2), 2.2, eyePaint);
      canvas.drawCircle(Offset(mx + 4, my - 2), 2.2, eyePaint);
      // Eye sparkle
      canvas.drawCircle(Offset(mx - 4.8, my - 2.8), 0.8, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(mx + 3.2, my - 2.8), 0.8, Paint()..color = Colors.white);
    }

    // Cheerful rosy cheeks
    final cheekPaint = Paint()..color = const Color(0xFFFF85A1).withAlpha(150);
    canvas.drawCircle(Offset(mx - 7, my + 2), 2.0, cheekPaint);
    canvas.drawCircle(Offset(mx + 7, my + 2), 2.0, cheekPaint);

    // Cute green leaf on Mossy's head
    final leafStem = Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 1.6..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(mx, my - 11), Offset(mx + 1, my - 16), leafStem);
    canvas.drawOval(Rect.fromCenter(center: Offset(mx + 3, my - 16), width: 6, height: 3.5), Paint()..color = const Color(0xFF4CAF50));
  }

  void _drawButterflies(Canvas canvas, Size size, double t) {
    final w = size.width;
    final butterflies = [
      {'bx': w * 0.25, 'by': size.height * 0.58, 'spd': 1.2, 'c': const Color(0xFFFF9EAA)},
      {'bx': w * 0.70, 'by': size.height * 0.52, 'spd': 1.7, 'c': const Color(0xFF80D8FF)},
    ];

    for (final bf in butterflies) {
      final bx = bf['bx']! as double;
      final by = bf['by']! as double;
      final spd = bf['spd']! as double;
      final color = bf['c']! as Color;

      // Flight path
      final fx = bx + math.sin(t * spd) * 26.0;
      final fy = by + math.cos(t * spd * 1.5) * 12.0;

      // Wing flap animation
      final wingFlap = math.sin(t * 12.0).abs();
      final wingW = 7.0 * wingFlap;

      final wingPaint = Paint()..color = color.withAlpha(220);
      // Left wing
      canvas.drawOval(Rect.fromCenter(center: Offset(fx - wingW * 0.6, fy - 2), width: wingW, height: 7), wingPaint);
      // Right wing
      canvas.drawOval(Rect.fromCenter(center: Offset(fx + wingW * 0.6, fy - 2), width: wingW, height: 7), wingPaint);
      // Body
      canvas.drawRect(Rect.fromCenter(center: Offset(fx, fy), width: 1.5, height: 5), Paint()..color = const Color(0xFF37474F));
    }
  }

  void _drawFallingPetals(Canvas canvas, Size size, double t) {
    final w = size.width;
    final petalPaint = Paint()..color = const Color(0xFFFFCDD2).withAlpha(190);

    for (int i = 0; i < 6; i++) {
      final seed = i * 47.0;
      final px = (seed * 8 + t * 14.0 + math.sin(t * 2.0 + i) * 15.0) % w;
      final py = (seed * 5 + t * 24.0) % (size.height * 0.75);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate((t * 2.0 + i) % (2 * math.pi));
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 6, height: 3), petalPaint);
      canvas.restore();
    }
  }

  void _drawFireflies(Canvas canvas, Size size, double t) {
    final w = size.width;
    final fireflyPaint = Paint()
      ..color = const Color(0xFFFFF59D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 8; i++) {
      final seed = i * 31.0;
      final fx = (w * 0.15 + (seed * 11 + math.sin(t * 1.2 + i) * 35.0)) % (w * 0.85);
      final fy = size.height * 0.52 + math.cos(t * 1.4 + i) * 25.0 - (t * 8.0 + seed) % 60.0;

      final alpha = ((math.sin(t * 4.0 + i) + 1.0) * 110).clamp(30, 240).toInt();
      canvas.drawCircle(Offset(fx, fy), 2.2, fireflyPaint..color = const Color(0xFFFFF59D).withAlpha(alpha));
    }
  }

  void _drawTouchParticles(Canvas canvas, Size size, double t) {
    if (touchParticles.isEmpty) return;

    for (final p in touchParticles) {
      final age = t - p.createdAt;
      if (age < 0 || age > 1.2) continue;

      final progress = age / 1.2;
      final curX = p.position.dx + p.vx * age;
      final curY = p.position.dy + p.vy * age - (30.0 * progress);
      final alpha = ((1.0 - progress) * 255).clamp(0, 255).toInt();

      final textSpan = TextSpan(
        text: p.symbol,
        style: TextStyle(
          fontSize: (p.size * (1.0 + 0.3 * progress)).clamp(10.0, 36.0),
          color: p.color.withAlpha(alpha),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(curX - textPainter.width / 2, curY - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(GardenPainter oldDelegate) {
    return oldDelegate.level != level ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.touchParticles != touchParticles;
  }
}
