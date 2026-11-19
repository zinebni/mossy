import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/discovery_rarity.dart';

/// Small pill showing a rarity tier (emoji + label).
class RarityBadge extends StatelessWidget {
  final DiscoveryRarity rarity;
  final bool isFr;
  final bool compact;
  final VoidCallback? onTap;

  const RarityBadge({
    super.key,
    required this.rarity,
    this.isFr = false,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: rarity.softColor,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: rarity.color.withAlpha(150)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rarity.emoji, style: TextStyle(fontSize: compact ? 10 : 13)),
          SizedBox(width: compact ? 3 : 5),
          Text(
            rarity.label(isFr),
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
              color: rarity.color,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}

/// Subtle border + glow for rare+ cards. Returns the base shadow only for
/// lower tiers so the cozy look is preserved.
class RarityFrame {
  RarityFrame._();

  static Border? border(DiscoveryRarity r) {
    if (!r.showsBadge) return null;
    final width = r.index >= DiscoveryRarity.rare.index ? 1.6 : 1.0;
    return Border.all(color: r.color.withAlpha(r.isCelebratory ? 200 : 110), width: width);
  }

  static List<BoxShadow> shadows(DiscoveryRarity r, List<BoxShadow> base) {
    if (!r.isCelebratory) return base;
    return [
      ...base,
      BoxShadow(color: r.color.withAlpha(70), blurRadius: 14, spreadRadius: 0.5),
    ];
  }
}

/// Short (~1.8s), gentle, non-blocking sparkle/fireworks celebration.
/// Use [RarityCelebration.show] to play it above the current screen.
class RarityCelebration extends StatefulWidget {
  final DiscoveryRarity rarity;
  final bool isFr;
  final VoidCallback? onDone;

  const RarityCelebration({
    super.key,
    required this.rarity,
    this.isFr = false,
    this.onDone,
  });

  /// Plays the celebration in the root overlay. No-op for tiers below rare.
  static void show(BuildContext context, DiscoveryRarity rarity, {bool isFr = false}) {
    if (!rarity.isCelebratory) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => RarityCelebration(
        rarity: rarity,
        isFr: isFr,
        onDone: () => WidgetsBinding.instance.addPostFrameCallback((_) => remove()),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<RarityCelebration> createState() => _RarityCelebrationState();
}

class _RarityCelebrationState extends State<RarityCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Burst> _bursts;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    final tier = widget.rarity.index - DiscoveryRarity.rare.index; // 0..2
    final burstCount = 3 + tier;
    final palette = <Color>[
      widget.rarity.color,
      Colors.white,
      const Color(0xFFFFD166),
      const Color(0xFFFF8FB1),
    ];
    _bursts = List.generate(burstCount, (i) {
      return _Burst(
        center: Offset(0.2 + rnd.nextDouble() * 0.6, 0.18 + rnd.nextDouble() * 0.3),
        start: (i * 0.14).clamp(0.0, 0.5),
        particles: List.generate(14, (j) {
          final angle = (j / 14) * math.pi * 2 + rnd.nextDouble() * 0.3;
          return _Particle(
            angle: angle,
            distance: 50 + rnd.nextDouble() * 55,
            size: 2.5 + rnd.nextDouble() * 3,
            color: palette[rnd.nextInt(palette.length)],
            star: rnd.nextBool(),
          );
        }),
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone?.call();
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rarity;
    final text = widget.isFr
        ? '${r.emoji} Trouvaille ${r.label(true).toLowerCase()} ! ${r.emoji}'
        : '${r.emoji} ${r.label(false)} find! ${r.emoji}';

    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _FireworksPainter(_controller, _bursts),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 56,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    final t = _controller.value;
                    final opacity = t < 0.15
                        ? t / 0.15
                        : t > 0.8
                            ? ((1 - t) / 0.2).clamp(0.0, 1.0)
                            : 1.0;
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(scale: 0.9 + 0.1 * opacity, child: child),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(240),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: r.color, width: 1.5),
                      boxShadow: [BoxShadow(color: r.color.withAlpha(80), blurRadius: 16)],
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: r.color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final bool star;
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.star,
  });
}

class _Burst {
  final Offset center; // fractions of the screen
  final double start; // 0..1 of the whole animation
  final List<_Particle> particles;
  const _Burst({required this.center, required this.start, required this.particles});
}

class _FireworksPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Burst> bursts;

  _FireworksPainter(this.animation, this.bursts) : super(repaint: animation);

  static const double _burstLength = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final b in bursts) {
      final local = ((t - b.start) / _burstLength).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final eased = Curves.easeOutCubic.transform(local);
      final alpha = (1 - local * local).clamp(0.0, 1.0);
      final origin = Offset(b.center.dx * size.width, b.center.dy * size.height);

      for (final p in b.particles) {
        final pos = origin +
            Offset(
              math.cos(p.angle) * p.distance * eased,
              math.sin(p.angle) * p.distance * eased + 26 * local * local, // gentle gravity
            );
        paint.color = p.color.withValues(alpha: alpha);
        if (p.star) {
          _drawStar(canvas, pos, p.size * 2.2 * (1 - local * 0.4), paint);
        } else {
          canvas.drawCircle(pos, p.size * (1 - local * 0.5), paint);
        }
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? r : r * 0.35;
      final a = (math.pi / 4) * i - math.pi / 2;
      final pt = Offset(c.dx + math.cos(a) * radius, c.dy + math.sin(a) * radius);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) => false;
}
