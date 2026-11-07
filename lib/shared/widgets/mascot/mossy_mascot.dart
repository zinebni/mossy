import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'mascot_expression.dart';
import 'mascot_painter.dart';

/// Main Mossy mascot widget.
/// Renders the custom-drawn Mossy character with gentle organic idle animations,
/// breathing/pulsing, natural blinking, and tap interactivity.
class MossyMascot extends StatefulWidget {
  final MascotExpression expression;
  final double size;
  final bool animate;
  final bool enableBreathe;
  final bool enableWobble;
  final bool enableBlink;
  final VoidCallback? onTap;
  final Color? bodyColor;

  const MossyMascot({
    super.key,
    this.expression = MascotExpression.happy,
    this.size = 140.0,
    this.animate = true,
    this.enableBreathe = true,
    this.enableWobble = true,
    this.enableBlink = true,
    this.onTap,
    this.bodyColor,
  });

  @override
  State<MossyMascot> createState() => _MossyMascotState();
}

class _MossyMascotState extends State<MossyMascot>
    with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _idleController;
  late AnimationController _sparkleController;
  late AnimationController _tapBounceController;
  late AnimationController _blinkController;

  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();

    // 1. Gentle breathing animation (squash & stretch)
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.animate && widget.enableBreathe) {
      _breatheController.repeat(reverse: true);
    }

    // 2. Idle floating & wobble animation
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.animate && widget.enableWobble) {
      _idleController.repeat(reverse: true);
    }

    // 3. Sparkle rotation/twinkle for excited/celebrating
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animate) {
      _sparkleController.repeat();
    }

    // 4. Interactive tap bounce
    _tapBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 5. Periodic natural blink
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );

    if (widget.animate && widget.enableBlink) {
      _startPeriodicBlink();
    }
  }

  void _startPeriodicBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 3800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (widget.expression != MascotExpression.sleepy) {
        _blinkController.forward().then((_) {
          if (mounted) _blinkController.reverse();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant MossyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        if (widget.enableBreathe && !_breatheController.isAnimating) {
          _breatheController.repeat(reverse: true);
        }
        if (widget.enableWobble && !_idleController.isAnimating) {
          _idleController.repeat(reverse: true);
        }
        if (!_sparkleController.isAnimating) {
          _sparkleController.repeat();
        }
        _startPeriodicBlink();
      } else {
        _breatheController.stop();
        _idleController.stop();
        _sparkleController.stop();
        _blinkTimer?.cancel();
      }
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breatheController.dispose();
    _idleController.dispose();
    _sparkleController.dispose();
    _tapBounceController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.animate) {
      _tapBounceController.forward(from: 0.0);
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _breatheController,
            _idleController,
            _sparkleController,
            _tapBounceController,
            _blinkController,
          ]),
          builder: (context, child) {
            // Calculate animation curves
            final breatheValue = widget.animate && widget.enableBreathe
                ? 1.0 + (math.sin(_breatheController.value * math.pi) * 0.025)
                : 1.0;

            // Extra head tilt for curious expression
            final baseTilt = widget.expression == MascotExpression.curious ? 0.06 : 0.0;
            final wobbleAngle = widget.animate && widget.enableWobble
                ? baseTilt + (math.sin(_idleController.value * math.pi * 2) * 0.025)
                : baseTilt;

            // Subtle vertical bobbing
            final idleBounce = widget.animate && widget.enableWobble
                ? math.sin(_idleController.value * math.pi * 2) * (widget.size * 0.02)
                : 0.0;

            // Tap squish & bounce
            final tapProgress = _tapBounceController.value;
            final tapSquish = tapProgress > 0
                ? math.sin(tapProgress * math.pi) * 0.12
                : 0.0;

            return CustomPaint(
              size: Size(widget.size, widget.size),
              painter: MascotPainter(
                expression: widget.expression,
                blinkProgress: _blinkController.value,
                breatheScale: breatheValue - tapSquish,
                wobbleAngle: wobbleAngle,
                bounceOffset: idleBounce - (tapSquish * widget.size * 0.1),
                sparklePhase: _sparkleController.value,
                bodyColor: widget.bodyColor,
              ),
            );
          },
        ),
      ),
    );
  }
}
