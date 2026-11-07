import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'mascot_expression.dart';

/// CustomPainter that renders the adorable Mossy mascot.
/// Features a soft organic moss-blob body, expressive face,
/// rosy cheeks, leaf sprouts, and texture stippling.
class MascotPainter extends CustomPainter {
  final MascotExpression expression;
  final double blinkProgress;
  final double breatheScale;
  final double wobbleAngle;
  final double bounceOffset;
  final double sparklePhase;
  final Color? bodyColor;

  const MascotPainter({
    required this.expression,
    this.blinkProgress = 0.0,
    this.breatheScale = 1.0,
    this.wobbleAngle = 0.0,
    this.bounceOffset = 0.0,
    this.sparklePhase = 0.0,
    this.bodyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final baseSize = math.min(size.width, size.height);
    final scale = baseSize / 160.0; // Normalized to 160x160 base coordinates

    canvas.save();

    // Center and apply bounce & wobble transform
    final center = Offset(size.width / 2, size.height / 2 + bounceOffset);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(wobbleAngle);
    canvas.scale(breatheScale, 2.0 - breatheScale); // Gentle squash and stretch
    canvas.translate(-80.0 * scale, -80.0 * scale);

    // 1. Draw soft drop shadow beneath Mossy
    _drawShadow(canvas, scale);

    // 2. Draw arms (drawn behind or in front depending on expression)
    if (expression == MascotExpression.celebrating) {
      _drawCelebrationArms(canvas, scale);
    } else {
      _drawRestingArms(canvas, scale);
    }

    // 3. Draw organic moss blob body
    _drawBody(canvas, scale);

    // 4. Draw moss texture dots
    _drawTextureDots(canvas, scale);

    // 5. Draw head leaf sprouts
    _drawLeafSprouts(canvas, scale);

    // 6. Draw rosy cheeks
    _drawCheeks(canvas, scale);

    // 7. Draw eyes based on expression & blinking
    _drawEyes(canvas, scale);

    // 8. Draw mouth based on expression
    _drawMouth(canvas, scale);

    // 9. Draw expression-specific particles (sparkles for excited/celebrating)
    if (expression == MascotExpression.excited ||
        expression == MascotExpression.celebrating) {
      _drawSparkles(canvas, scale);
    }

    canvas.restore();
  }

  void _drawShadow(Canvas canvas, double s) {
    final shadowPaint = Paint()
      ..color = AppColors.darkText.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(80 * s, 142 * s),
        width: 100 * s,
        height: 18 * s,
      ),
      shadowPaint,
    );
  }

  void _drawBody(Canvas canvas, double s) {
    final primary = bodyColor ?? AppColors.sageGreen;
    final shadowColor = AppColors.mascotBodyShadow;
    final highlightColor = AppColors.mascotBodyHighlight;

    // Organic blob path (pear-dumpling shape with soft curves)
    final path = Path();
    path.moveTo(80 * s, 36 * s); // Top center of head

    // Top-right slope to right shoulder
    path.cubicTo(106 * s, 36 * s, 126 * s, 54 * s, 128 * s, 76 * s);
    // Right shoulder down to right cheek/belly bulge
    path.cubicTo(130 * s, 92 * s, 138 * s, 108 * s, 134 * s, 124 * s);
    // Right belly to bottom curve
    path.cubicTo(130 * s, 138 * s, 114 * s, 144 * s, 98 * s, 144 * s);
    // Bottom base (slight organic flatten)
    path.cubicTo(88 * s, 144 * s, 72 * s, 144 * s, 62 * s, 144 * s);
    // Bottom left to left belly bulge
    path.cubicTo(46 * s, 144 * s, 30 * s, 138 * s, 26 * s, 124 * s);
    // Left belly up to left shoulder
    path.cubicTo(22 * s, 108 * s, 30 * s, 92 * s, 32 * s, 76 * s);
    // Left shoulder to top of head
    path.cubicTo(34 * s, 54 * s, 54 * s, 36 * s, 80 * s, 36 * s);
    path.close();

    // Body gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [highlightColor, primary, shadowColor],
      stops: const [0.0, 0.55, 1.0],
    );

    final bodyPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(20 * s, 30 * s, 120 * s, 120 * s))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, bodyPaint);

    // Soft outline for crispness
    final outlinePaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s;

    canvas.drawPath(path, outlinePaint);
  }

  void _drawTextureDots(Canvas canvas, double s) {
    final dotPaintDark = Paint()
      ..color = AppColors.mascotTexture.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final dotPaintLight = Paint()
      ..color = AppColors.mascotBodyHighlight.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    // Organic stipples suggesting moss velvety texture
    final dots = [
      // x, y, radius, isLight
      [42.0, 58.0, 2.2, true],
      [48.0, 64.0, 1.8, false],
      [36.0, 72.0, 2.5, false],
      [38.0, 84.0, 2.0, true],
      [32.0, 98.0, 2.4, false],
      [36.0, 114.0, 2.8, true],
      [46.0, 128.0, 2.0, false],
      [118.0, 58.0, 2.0, true],
      [122.0, 70.0, 2.6, false],
      [126.0, 88.0, 2.2, true],
      [124.0, 106.0, 2.8, false],
      [116.0, 122.0, 2.4, true],
      [106.0, 132.0, 2.0, false],
      [68.0, 44.0, 1.6, true],
      [92.0, 44.0, 1.6, false],
    ];

    for (final dot in dots) {
      final x = (dot[0] as double) * s;
      final y = (dot[1] as double) * s;
      final r = (dot[2] as double) * s;
      final isLight = dot[3] as bool;
      canvas.drawCircle(Offset(x, y), r, isLight ? dotPaintLight : dotPaintDark);
    }
  }

  void _drawLeafSprouts(Canvas canvas, double s) {
    // Two cute sprout leaves sprouting from head center (80, 36)
    final sproutPaint = Paint()
      ..color = AppColors.mascotSprout
      ..style = PaintingStyle.fill;

    final sproutOutline = Paint()
      ..color = AppColors.mascotBodyShadow.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round;

    final sproutLight = Paint()
      ..color = AppColors.mascotSproutLight
      ..style = PaintingStyle.fill;

    // Tiny stem base
    final stemPath = Path();
    stemPath.moveTo(80 * s, 38 * s);
    stemPath.quadraticBezierTo(80 * s, 28 * s, 78 * s, 25 * s);
    canvas.drawPath(stemPath, sproutOutline);

    // Left Leaf (leaning slightly left)
    canvas.save();
    canvas.translate(78 * s, 25 * s);
    canvas.rotate(-0.35 + math.sin(sparklePhase * math.pi * 2) * 0.08);

    final leftLeaf = Path();
    leftLeaf.moveTo(0, 0);
    leftLeaf.cubicTo(-14 * s, -4 * s, -16 * s, -20 * s, 0, -22 * s);
    leftLeaf.cubicTo(10 * s, -16 * s, 8 * s, -4 * s, 0, 0);
    leftLeaf.close();

    canvas.drawPath(leftLeaf, sproutPaint);
    // Leaf highlight
    final leftHighlight = Path();
    leftHighlight.moveTo(0, 0);
    leftHighlight.cubicTo(-8 * s, -3 * s, -10 * s, -14 * s, 0, -18 * s);
    leftHighlight.cubicTo(2 * s, -12 * s, 2 * s, -4 * s, 0, 0);
    canvas.drawPath(leftHighlight, sproutLight);
    canvas.drawPath(leftLeaf, sproutOutline);
    canvas.restore();

    // Right Leaf (leaning slightly right, slightly smaller)
    canvas.save();
    canvas.translate(81 * s, 27 * s);
    canvas.rotate(0.38 - math.sin(sparklePhase * math.pi * 2) * 0.08);

    final rightLeaf = Path();
    rightLeaf.moveTo(0, 0);
    rightLeaf.cubicTo(-6 * s, -4 * s, -8 * s, -16 * s, 0, -18 * s);
    rightLeaf.cubicTo(12 * s, -15 * s, 10 * s, -3 * s, 0, 0);
    rightLeaf.close();

    canvas.drawPath(rightLeaf, sproutPaint);
    canvas.drawPath(rightLeaf, sproutOutline);
    canvas.restore();
  }

  void _drawCheeks(Canvas canvas, double s) {
    final cheekPaint = Paint()
      ..color = AppColors.mascotCheek.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    // Left cheek
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(46 * s, 92 * s),
        width: 14 * s,
        height: 10 * s,
      ),
      cheekPaint,
    );

    // Right cheek
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(114 * s, 92 * s),
        width: 14 * s,
        height: 10 * s,
      ),
      cheekPaint,
    );
  }

  void _drawRestingArms(Canvas canvas, double s) {
    final armPaint = Paint()
      ..color = (bodyColor ?? AppColors.sageGreen)
      ..style = PaintingStyle.fill;

    final armOutline = Paint()
      ..color = AppColors.mascotBodyShadow.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s;

    // Cute little mossy nubs resting at the sides
    // Left arm
    final leftArm = Path();
    leftArm.moveTo(33 * s, 92 * s);
    leftArm.cubicTo(22 * s, 96 * s, 24 * s, 114 * s, 36 * s, 110 * s);
    canvas.drawPath(leftArm, armPaint);
    canvas.drawPath(leftArm, armOutline);

    // Right arm
    final rightArm = Path();
    rightArm.moveTo(127 * s, 92 * s);
    rightArm.cubicTo(138 * s, 96 * s, 136 * s, 114 * s, 124 * s, 110 * s);
    canvas.drawPath(rightArm, armPaint);
    canvas.drawPath(rightArm, armOutline);
  }

  void _drawCelebrationArms(Canvas canvas, double s) {
    final armPaint = Paint()
      ..color = (bodyColor ?? AppColors.sageGreen)
      ..style = PaintingStyle.fill;

    final armOutline = Paint()
      ..color = AppColors.mascotBodyShadow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round;

    // Left arm raised up joyfully \ (^_^)/
    final leftArm = Path();
    leftArm.moveTo(34 * s, 84 * s);
    leftArm.cubicTo(18 * s, 68 * s, 12 * s, 48 * s, 22 * s, 42 * s);
    leftArm.cubicTo(28 * s, 38 * s, 38 * s, 54 * s, 38 * s, 76 * s);
    leftArm.close();
    canvas.drawPath(leftArm, armPaint);
    canvas.drawPath(leftArm, armOutline);

    // Right arm raised up joyfully
    final rightArm = Path();
    rightArm.moveTo(126 * s, 84 * s);
    rightArm.cubicTo(142 * s, 68 * s, 148 * s, 48 * s, 138 * s, 42 * s);
    rightArm.cubicTo(132 * s, 38 * s, 122 * s, 54 * s, 122 * s, 76 * s);
    rightArm.close();
    canvas.drawPath(rightArm, armPaint);
    canvas.drawPath(rightArm, armOutline);
  }

  void _drawEyes(Canvas canvas, double s) {
    // If blinking (blinkProgress > 0.8), draw closed sleeping/blinking line
    if (blinkProgress > 0.8) {
      _drawBlinkingEyes(canvas, s);
      return;
    }

    switch (expression) {
      case MascotExpression.happy:
        _drawHappyEyes(canvas, s);
        break;
      case MascotExpression.curious:
        _drawCuriousEyes(canvas, s);
        break;
      case MascotExpression.excited:
        _drawSparkleEyes(canvas, s);
        break;
      case MascotExpression.sleepy:
        _drawSleepyEyes(canvas, s);
        break;
      case MascotExpression.surprised:
        _drawSurprisedEyes(canvas, s);
        break;
      case MascotExpression.thinking:
        _drawThinkingEyes(canvas, s);
        break;
      case MascotExpression.celebrating:
        _drawSparkleEyes(canvas, s);
        break;
      case MascotExpression.searching:
        _drawSearchingEyes(canvas, s);
        break;
    }
  }

  void _drawHappyEyes(Canvas canvas, double s) {
    // ^_^ style curved happy closed eyes
    final eyePaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * s
      ..strokeCap = StrokeCap.round;

    // Left eye curve ^
    final leftPath = Path();
    leftPath.moveTo(54 * s, 81 * s);
    leftPath.quadraticBezierTo(64 * s, 68 * s, 74 * s, 81 * s);
    canvas.drawPath(leftPath, eyePaint);

    // Right eye curve ^
    final rightPath = Path();
    rightPath.moveTo(86 * s, 81 * s);
    rightPath.quadraticBezierTo(96 * s, 68 * s, 106 * s, 81 * s);
    canvas.drawPath(rightPath, eyePaint);
  }

  void _drawCuriousEyes(Canvas canvas, double s) {
    // O.o style: left eye big & round looking up-right, right eye slightly squinted with raised brow
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.fill;
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s;

    // Left eye (Big round eye)
    final leftCenter = Offset(62 * s, 76 * s);
    final leftRadius = 12.0 * s;
    canvas.drawCircle(leftCenter, leftRadius, whitePaint);
    canvas.drawCircle(leftCenter, leftRadius, strokePaint);
    // Pupil looking up and right
    final leftPupil = Offset(65 * s, 74 * s);
    canvas.drawCircle(leftPupil, 7.0 * s, pupilPaint);
    canvas.drawCircle(Offset(63 * s, 72 * s), 2.2 * s, glintPaint);
    canvas.drawCircle(Offset(67 * s, 76 * s), 1.2 * s, glintPaint);

    // Right eye (Smaller inquisitive squint)
    final rightCenter = Offset(97 * s, 77 * s);
    final rightRadius = 8.5 * s;
    canvas.drawCircle(rightCenter, rightRadius, whitePaint);
    canvas.drawCircle(rightCenter, rightRadius, strokePaint);
    final rightPupil = Offset(99 * s, 76 * s);
    canvas.drawCircle(rightPupil, 5.0 * s, pupilPaint);
    canvas.drawCircle(Offset(97.5 * s, 74.5 * s), 1.6 * s, glintPaint);

    // Raised curious eyebrow above right eye
    final browPaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    final browPath = Path();
    browPath.moveTo(90 * s, 66 * s);
    browPath.quadraticBezierTo(98 * s, 63 * s, 106 * s, 67 * s);
    canvas.drawPath(browPath, browPaint);
  }

  void _drawSparkleEyes(Canvas canvas, double s) {
    // ★★ Sparkle eyes for excited / celebrating
    _drawSparkleStar(canvas, Offset(64 * s, 76 * s), 12.0 * s, AppColors.mascotEyeDark);
    _drawSparkleStar(canvas, Offset(96 * s, 76 * s), 12.0 * s, AppColors.mascotEyeDark);

    // Golden / white twinkles in the center of stars
    _drawSparkleStar(canvas, Offset(64 * s, 76 * s), 5.5 * s, AppColors.butterYellow);
    _drawSparkleStar(canvas, Offset(96 * s, 76 * s), 5.5 * s, AppColors.butterYellow);

    final glintPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(62 * s, 74 * s), 2.0 * s, glintPaint);
    canvas.drawCircle(Offset(94 * s, 74 * s), 2.0 * s, glintPaint);
  }

  void _drawSparkleStar(Canvas canvas, Offset center, double r, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy - r);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawSleepyEyes(Canvas canvas, double s) {
    // — — closed peaceful eyes with slight droop
    final eyePaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * s
      ..strokeCap = StrokeCap.round;

    final leftPath = Path();
    leftPath.moveTo(52 * s, 79 * s);
    leftPath.quadraticBezierTo(63 * s, 83 * s, 73 * s, 79 * s);
    canvas.drawPath(leftPath, eyePaint);

    final rightPath = Path();
    rightPath.moveTo(87 * s, 79 * s);
    rightPath.quadraticBezierTo(97 * s, 83 * s, 108 * s, 79 * s);
    canvas.drawPath(rightPath, eyePaint);
  }

  void _drawSurprisedEyes(Canvas canvas, double s) {
    // O O big round open eyes
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.fill;
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s;

    // Both eyes large and wide
    for (final cx in [63.0 * s, 97.0 * s]) {
      final center = Offset(cx, 75 * s);
      canvas.drawCircle(center, 12.5 * s, whitePaint);
      canvas.drawCircle(center, 12.5 * s, strokePaint);
      // Centered pupil
      canvas.drawCircle(center, 6.5 * s, pupilPaint);
      // Sparkle glints
      canvas.drawCircle(Offset(cx - 2.5 * s, 72.5 * s), 2.2 * s, glintPaint);
      canvas.drawCircle(Offset(cx + 2.5 * s, 77.5 * s), 1.2 * s, glintPaint);
    }
  }

  void _drawThinkingEyes(Canvas canvas, double s) {
    // One eye glancing sideways/up, other eye squinting thoughtfully
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.fill;
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s;

    // Left eye glancing upper-right
    final leftCenter = Offset(63 * s, 76 * s);
    canvas.drawCircle(leftCenter, 11.0 * s, whitePaint);
    canvas.drawCircle(leftCenter, 11.0 * s, strokePaint);
    final leftPupil = Offset(67 * s, 72 * s);
    canvas.drawCircle(leftPupil, 6.0 * s, pupilPaint);
    canvas.drawCircle(Offset(65.5 * s, 70.5 * s), 2.0 * s, glintPaint);

    // Right eye slightly squinted
    final squintPaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * s
      ..strokeCap = StrokeCap.round;
    final rightSquint = Path();
    rightSquint.moveTo(88 * s, 76 * s);
    rightSquint.quadraticBezierTo(97 * s, 72 * s, 106 * s, 77 * s);
    canvas.drawPath(rightSquint, squintPaint);

    // Eyebrow tilted in contemplation
    final browPath = Path();
    browPath.moveTo(56 * s, 64 * s);
    browPath.quadraticBezierTo(64 * s, 61 * s, 72 * s, 64 * s);
    canvas.drawPath(browPath, squintPaint);
  }

  void _drawSearchingEyes(Canvas canvas, double s) {
    // Eyes looking downward intently
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pupilPaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.fill;
    final glintPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s;

    for (final cx in [63.0 * s, 97.0 * s]) {
      final center = Offset(cx, 76 * s);
      canvas.drawCircle(center, 11.0 * s, whitePaint);
      canvas.drawCircle(center, 11.0 * s, strokePaint);
      // Pupil directed down and towards bottom center/right
      final pupilCenter = Offset(cx + 1.5 * s, 80 * s);
      canvas.drawCircle(pupilCenter, 6.0 * s, pupilPaint);
      canvas.drawCircle(Offset(cx, 78 * s), 2.0 * s, glintPaint);
    }
  }

  void _drawBlinkingEyes(Canvas canvas, double s) {
    final blinkPaint = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * s
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(54 * s, 78 * s), Offset(72 * s, 78 * s), blinkPaint);
    canvas.drawLine(Offset(88 * s, 78 * s), Offset(106 * s, 78 * s), blinkPaint);
  }

  void _drawMouth(Canvas canvas, double s) {
    final mouthStroke = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * s
      ..strokeCap = StrokeCap.round;

    final mouthFill = Paint()
      ..color = AppColors.mascotEyeDark
      ..style = PaintingStyle.fill;

    final tonguePaint = Paint()
      ..color = AppColors.peach
      ..style = PaintingStyle.fill;

    switch (expression) {
      case MascotExpression.happy:
        // Sweet curved smile ᴗ
        final path = Path();
        path.moveTo(72 * s, 94 * s);
        path.quadraticBezierTo(80 * s, 102 * s, 88 * s, 94 * s);
        canvas.drawPath(path, mouthStroke);
        break;

      case MascotExpression.curious:
        // Subtle inquisitive smirk/smile
        final path = Path();
        path.moveTo(73 * s, 95 * s);
        path.quadraticBezierTo(81 * s, 97 * s, 88 * s, 93 * s);
        canvas.drawPath(path, mouthStroke);
        break;

      case MascotExpression.excited:
      case MascotExpression.celebrating:
        // Big open joyful smile with pink tongue!
        final openMouth = Path();
        openMouth.moveTo(70 * s, 93 * s);
        openMouth.quadraticBezierTo(80 * s, 93 * s, 90 * s, 93 * s);
        openMouth.cubicTo(89 * s, 107 * s, 71 * s, 107 * s, 70 * s, 93 * s);
        openMouth.close();

        canvas.drawPath(openMouth, mouthFill);

        // Tongue
        canvas.save();
        canvas.clipPath(openMouth);
        canvas.drawCircle(Offset(80 * s, 103 * s), 6.5 * s, tonguePaint);
        canvas.restore();
        canvas.drawPath(openMouth, mouthStroke);
        break;

      case MascotExpression.sleepy:
      case MascotExpression.surprised:
        // Small cute round 'o' mouth
        final r = expression == MascotExpression.surprised ? 5.5 * s : 4.0 * s;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(80 * s, 96 * s),
            width: r * 1.6,
            height: r * 2.0,
          ),
          mouthFill,
        );
        break;

      case MascotExpression.thinking:
        // Small thoughtful pursed line ~
        final path = Path();
        path.moveTo(73 * s, 96 * s);
        path.quadraticBezierTo(77 * s, 94 * s, 81 * s, 96 * s);
        path.quadraticBezierTo(85 * s, 98 * s, 88 * s, 95 * s);
        canvas.drawPath(path, mouthStroke);
        break;

      case MascotExpression.searching:
        // Small concentrated smile
        final path = Path();
        path.moveTo(74 * s, 96 * s);
        path.quadraticBezierTo(80 * s, 99 * s, 86 * s, 96 * s);
        canvas.drawPath(path, mouthStroke);
        break;
    }
  }

  void _drawSparkles(Canvas canvas, double s) {
    // Twinkling decorative mini-stars floating near Mossy
    final offsets = [
      Offset(24 * s, 42 * s),
      Offset(136 * s, 44 * s),
      Offset(20 * s, 80 * s),
      Offset(140 * s, 82 * s),
    ];

    for (int i = 0; i < offsets.length; i++) {
      final phase = (sparklePhase + i * 0.25) % 1.0;
      final sizeFactor = (math.sin(phase * math.pi) * 0.5 + 0.5);
      final r = 4.5 * s * sizeFactor;
      if (r > 1.0) {
        _drawSparkleStar(canvas, offsets[i], r, AppColors.butterYellow);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MascotPainter oldDelegate) {
    return oldDelegate.expression != expression ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.breatheScale != breatheScale ||
        oldDelegate.wobbleAngle != wobbleAngle ||
        oldDelegate.bounceOffset != bounceOffset ||
        oldDelegate.sparklePhase != sparklePhase ||
        oldDelegate.bodyColor != bodyColor;
  }
}
