import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'mascot_expression.dart';
import 'mossy_mascot.dart';

/// Available accessories for Mossy across different app features.
enum MascotAccessory {
  none,
  magnifyingGlass, // For Explore & Searching
  book, // For Learn & Field Notes
  partyHat, // For Achievements & Celebrating
  wateringCan, // For Garden & Growth
  backpack, // For Adventures & Quests
}

/// Renders the Mossy mascot equipped with themed, custom-drawn accessories.
class MascotWithAccessory extends StatelessWidget {
  final MascotExpression expression;
  final MascotAccessory accessory;
  final double size;
  final bool animate;
  final VoidCallback? onTap;
  final Color? bodyColor;

  const MascotWithAccessory({
    super.key,
    this.expression = MascotExpression.happy,
    this.accessory = MascotAccessory.none,
    this.size = 160.0,
    this.animate = true,
    this.onTap,
    this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    if (accessory == MascotAccessory.none) {
      return MossyMascot(
        expression: expression,
        size: size,
        animate: animate,
        onTap: onTap,
        bodyColor: bodyColor,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Backpack is drawn behind or side-aligned
          if (accessory == MascotAccessory.backpack)
            Positioned(
              left: size * 0.04,
              top: size * 0.42,
              child: _AccessoryBackpack(size: size * 0.38),
            ),

          // Central Mascot
          MossyMascot(
            expression: expression,
            size: size,
            animate: animate,
            onTap: onTap,
            bodyColor: bodyColor,
          ),

          // Party Hat sits on top of head
          if (accessory == MascotAccessory.partyHat)
            Positioned(
              top: size * 0.02,
              child: _AccessoryPartyHat(size: size * 0.35),
            ),

          // Magnifying Glass held on the right
          if (accessory == MascotAccessory.magnifyingGlass)
            Positioned(
              right: size * 0.02,
              bottom: size * 0.12,
              child: _AccessoryMagnifyingGlass(size: size * 0.44),
            ),

          // Nature Field Guide Book in front
          if (accessory == MascotAccessory.book)
            Positioned(
              right: size * 0.08,
              bottom: size * 0.08,
              child: _AccessoryBook(size: size * 0.42),
            ),

          // Watering Can on the right
          if (accessory == MascotAccessory.wateringCan)
            Positioned(
              right: size * 0.02,
              bottom: size * 0.10,
              child: _AccessoryWateringCan(size: size * 0.46),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// CUSTOM ACCESSORY PAINTERS & WIDGETS
// ==========================================

class _AccessoryMagnifyingGlass extends StatelessWidget {
  final double size;
  const _AccessoryMagnifyingGlass({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MagnifyingGlassPainter(),
      ),
    );
  }
}

class _MagnifyingGlassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60.0;
    canvas.save();
    canvas.translate(size.width * 0.45, size.height * 0.45);
    canvas.rotate(0.35);

    // 1. Wooden handle
    final handlePaint = Paint()
      ..color = const Color(0xFF8B6B4D)
      ..style = PaintingStyle.fill;
    final handleOutline = Paint()
      ..color = const Color(0xFF5A4430)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s;

    final handlePath = Path();
    handlePath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-3.5 * s, 12 * s, 7 * s, 26 * s),
        Radius.circular(3.5 * s),
      ),
    );
    canvas.drawPath(handlePath, handlePaint);
    canvas.drawPath(handlePath, handleOutline);

    // Ferrule (golden connector)
    final ferrulePaint = Paint()..color = AppColors.butterYellow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-4 * s, 10 * s, 8 * s, 4 * s),
        Radius.circular(1.5 * s),
      ),
      ferrulePaint,
    );

    // 2. Brass rim
    final rimPaint = Paint()
      ..color = AppColors.butterYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * s;

    final rimDark = Paint()
      ..color = const Color(0xFFC79E47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;

    final glassCenter = Offset(0, -6 * s);
    const glassRadius = 16.0;
    canvas.drawCircle(glassCenter, glassRadius * s, rimPaint);
    canvas.drawCircle(glassCenter, (glassRadius + 2.0) * s, rimDark);

    // 3. Glass lens (translucent mint/sky blue)
    final glassFill = Paint()
      ..color = AppColors.mintGreen.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(glassCenter, (glassRadius - 1.5) * s, glassFill);

    // 4. Little botanical leaf viewed inside the glass lens
    final leafPaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.fill;
    final leafPath = Path();
    leafPath.moveTo(glassCenter.dx - 3 * s, glassCenter.dy + 3 * s);
    leafPath.quadraticBezierTo(
      glassCenter.dx - 6 * s,
      glassCenter.dy - 5 * s,
      glassCenter.dx,
      glassCenter.dy - 6 * s,
    );
    leafPath.quadraticBezierTo(
      glassCenter.dx + 4 * s,
      glassCenter.dy - 1 * s,
      glassCenter.dx - 3 * s,
      glassCenter.dy + 3 * s,
    );
    canvas.drawPath(leafPath, leafPaint);

    // 5. Glass highlight / reflection glare
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round;

    final glarePath = Path();
    glarePath.addArc(
      Rect.fromCircle(center: glassCenter, radius: (glassRadius - 5.0) * s),
      -2.4,
      1.3,
    );
    canvas.drawPath(glarePath, glarePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccessoryBook extends StatelessWidget {
  final double size;
  const _AccessoryBook({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BookPainter(),
      ),
    );
  }
}

class _BookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 50.0;
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.15);

    // Field guide book cover (Lavender & Sage)
    final coverRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 34 * s, height: 42 * s),
      Radius.circular(4 * s),
    );

    // Drop shadow
    final shadowPaint = Paint()
      ..color = AppColors.darkText.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(coverRect.shift(Offset(2 * s, 3 * s)), shadowPaint);

    // Lavender cover
    final coverPaint = Paint()
      ..color = AppColors.lavender
      ..style = PaintingStyle.fill;
    canvas.drawRRect(coverRect, coverPaint);

    // Book spine stripe
    final spinePaint = Paint()..color = AppColors.sageGreen;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(-17 * s, -21 * s, 6 * s, 42 * s),
        topLeft: Radius.circular(4 * s),
        bottomLeft: Radius.circular(4 * s),
      ),
      spinePaint,
    );

    // Cream inner page edge
    final pagesPaint = Paint()..color = AppColors.creamBackground;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(14 * s, -19 * s, 3 * s, 38 * s),
        topRight: Radius.circular(2 * s),
        bottomRight: Radius.circular(2 * s),
      ),
      pagesPaint,
    );

    // Botanical emblem on cover: tiny gold leaf
    final emblemPaint = Paint()
      ..color = AppColors.butterYellow
      ..style = PaintingStyle.fill;
    final leafEmblem = Path();
    leafEmblem.moveTo(2 * s, 5 * s);
    leafEmblem.quadraticBezierTo(-4 * s, -4 * s, 2 * s, -7 * s);
    leafEmblem.quadraticBezierTo(8 * s, -2 * s, 2 * s, 5 * s);
    canvas.drawPath(leafEmblem, emblemPaint);

    // Bookmark ribbon dangling at bottom
    final ribbonPaint = Paint()
      ..color = AppColors.peach
      ..style = PaintingStyle.fill;
    final ribbonPath = Path();
    ribbonPath.moveTo(0, 18 * s);
    ribbonPath.lineTo(4 * s, 28 * s);
    ribbonPath.lineTo(2 * s, 26 * s);
    ribbonPath.lineTo(0, 28 * s);
    ribbonPath.close();
    canvas.drawPath(ribbonPath, ribbonPaint);

    // Book outline
    final outlinePaint = Paint()
      ..color = AppColors.darkText.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;
    canvas.drawRRect(coverRect, outlinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccessoryPartyHat extends StatelessWidget {
  final double size;
  const _AccessoryPartyHat({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PartyHatPainter(),
      ),
    );
  }
}

class _PartyHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 50.0;
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.7);
    canvas.rotate(0.08); // jaunty tilt

    // Cone shape
    final conePath = Path();
    conePath.moveTo(0, -32 * s); // Top tip
    conePath.lineTo(16 * s, 4 * s); // Bottom right
    conePath.quadraticBezierTo(0, 8 * s, -16 * s, 4 * s); // Curved base
    conePath.close();

    // Cone fill (Pastel Peach base)
    final conePaint = Paint()
      ..color = AppColors.peach
      ..style = PaintingStyle.fill;
    canvas.drawPath(conePath, conePaint);

    // Decorative striped pattern (Lavender and Butter Yellow stripes)
    canvas.save();
    canvas.clipPath(conePath);

    final stripeLavender = Paint()..color = AppColors.lavender;
    final stripeYellow = Paint()..color = AppColors.butterYellow;

    canvas.drawRect(Rect.fromLTWH(-20 * s, -18 * s, 40 * s, 7 * s), stripeLavender);
    canvas.drawRect(Rect.fromLTWH(-20 * s, -5 * s, 40 * s, 6 * s), stripeYellow);
    canvas.restore();

    // Outline
    final outline = Paint()
      ..color = AppColors.darkText.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s;
    canvas.drawPath(conePath, outline);

    // Fluffy Pom-Pom at the top
    final pomPom = Paint()..color = AppColors.butterYellow;
    canvas.drawCircle(Offset(0, -32 * s), 5.5 * s, pomPom);
    canvas.drawCircle(
      Offset(-1 * s, -33 * s),
      2.0 * s,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccessoryWateringCan extends StatelessWidget {
  final double size;
  const _AccessoryWateringCan({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WateringCanPainter(),
      ),
    );
  }
}

class _WateringCanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 60.0;
    canvas.save();
    canvas.translate(size.width * 0.45, size.height * 0.55);
    canvas.rotate(-0.08);

    final canColor = AppColors.mintGreen;
    final canAccent = AppColors.sageGreen;
    final outlinePaint = Paint()
      ..color = AppColors.darkText.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s
      ..strokeCap = StrokeCap.round;

    // 1. Can Body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 4 * s), width: 28 * s, height: 24 * s),
      Radius.circular(6 * s),
    );
    canvas.drawRRect(bodyRect, Paint()..color = canColor);
    canvas.drawRRect(bodyRect, outlinePaint);

    // Decorative band
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, 4 * s), width: 28 * s, height: 5 * s),
        Radius.circular(2 * s),
      ),
      Paint()..color = canAccent.withValues(alpha: 0.5),
    );

    // 2. Handle
    final handlePath = Path();
    handlePath.moveTo(-12 * s, -4 * s);
    handlePath.cubicTo(-22 * s, -14 * s, -24 * s, 14 * s, -13 * s, 12 * s);
    final handlePaint = Paint()
      ..color = canAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(handlePath, handlePaint);
    canvas.drawPath(handlePath, outlinePaint);

    // 3. Long Spout
    final spoutPath = Path();
    spoutPath.moveTo(10 * s, 6 * s);
    spoutPath.lineTo(24 * s, -10 * s);
    spoutPath.lineTo(22 * s, -14 * s);
    spoutPath.lineTo(8 * s, -2 * s);
    spoutPath.close();
    canvas.drawPath(spoutPath, Paint()..color = canColor);
    canvas.drawPath(spoutPath, outlinePaint);

    // Rose head (sprinkler tip)
    final rosePath = Path();
    rosePath.moveTo(20 * s, -18 * s);
    rosePath.lineTo(26 * s, -8 * s);
    final rosePaint = Paint()
      ..color = AppColors.butterYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(rosePath, rosePaint);

    // 4. Little water droplets falling
    final dropPaint = Paint()..color = const Color(0xFF8AC4E8);
    canvas.drawCircle(Offset(28 * s, -4 * s), 1.8 * s, dropPaint);
    canvas.drawCircle(Offset(32 * s, 2 * s), 2.2 * s, dropPaint);
    canvas.drawCircle(Offset(29 * s, 9 * s), 1.5 * s, dropPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccessoryBackpack extends StatelessWidget {
  final double size;
  const _AccessoryBackpack({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BackpackPainter(),
      ),
    );
  }
}

class _BackpackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 50.0;
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.1);

    final packColor = AppColors.peach;
    final flapColor = const Color(0xFFE4AA8A);
    final bedrollColor = AppColors.mintGreen;

    final outline = Paint()
      ..color = AppColors.darkText.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * s
      ..strokeCap = StrokeCap.round;

    // 1. Bedroll strapped to top
    final bedrollRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, -18 * s), width: 30 * s, height: 10 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(bedrollRect, Paint()..color = bedrollColor);
    canvas.drawRRect(bedrollRect, outline);

    // Bedroll straps
    final strapPaint = Paint()
      ..color = AppColors.sageGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s;
    canvas.drawLine(Offset(-7 * s, -23 * s), Offset(-7 * s, -13 * s), strapPaint);
    canvas.drawLine(Offset(7 * s, -23 * s), Offset(7 * s, -13 * s), strapPaint);

    // 2. Main Backpack Body
    final packRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, 3 * s), width: 28 * s, height: 32 * s),
      Radius.circular(8 * s),
    );
    canvas.drawRRect(packRect, Paint()..color = packColor);
    canvas.drawRRect(packRect, outline);

    // 3. Top Flap
    final flapPath = Path();
    flapPath.moveTo(-13 * s, -10 * s);
    flapPath.lineTo(13 * s, -10 * s);
    flapPath.quadraticBezierTo(14 * s, 4 * s, 0, 5 * s);
    flapPath.quadraticBezierTo(-14 * s, 4 * s, -13 * s, -10 * s);
    flapPath.close();
    canvas.drawPath(flapPath, Paint()..color = flapColor);
    canvas.drawPath(flapPath, outline);

    // Brass buckle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, 4 * s), width: 5 * s, height: 4 * s),
        Radius.circular(1.2 * s),
      ),
      Paint()..color = AppColors.butterYellow,
    );

    // Small daisy pin on the flap
    final pinCenter = Offset(6 * s, -2 * s);
    final petalPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 5; i++) {
      final angle = i * (2 * math.pi / 5);
      canvas.drawCircle(
        pinCenter + Offset(math.cos(angle) * 2.2 * s, math.sin(angle) * 2.2 * s),
        1.2 * s,
        petalPaint,
      );
    }
    canvas.drawCircle(pinCenter, 1.2 * s, Paint()..color = AppColors.butterYellow);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
