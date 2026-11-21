import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/sound_service.dart';
import '../models/discovery_rarity.dart';

/// Standout, playful badge showing a rarity tier (emoji + label + optional sparkle/XP).
/// Uses distinct gradient palettes per tier: friendly nature mint for Common,
/// vibrant emerald for Uncommon, sapphire shimmer for Rare, amethyst for Epic,
/// and radiant sun gold for Legendary.
class RarityBadge extends StatelessWidget {
  final DiscoveryRarity rarity;
  final bool isFr;
  final bool compact;
  final bool showXp;
  final VoidCallback? onTap;

  const RarityBadge({
    super.key,
    required this.rarity,
    this.isFr = false,
    this.compact = false,
    this.showXp = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCelebratory = rarity.isCelebratory;
    final isLegendary = rarity == DiscoveryRarity.legendary;
    final isEpic = rarity == DiscoveryRarity.epic;
    final isRare = rarity == DiscoveryRarity.rare;
    final isUncommon = rarity == DiscoveryRarity.uncommon;

    final List<Color> bgGradient = isLegendary
        ? [const Color(0xFFFFF6D8), const Color(0xFFFFE082)]
        : isEpic
            ? [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)]
            : isRare
                ? [const Color(0xFFE1F5FE), const Color(0xFFB3E5FC)]
                : isUncommon
                    ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                    : [const Color(0xFFF1F8F1), const Color(0xFFE2EFE2)];

    final Color borderColor = isLegendary
        ? const Color(0xFFFFA000)
        : isEpic
            ? const Color(0xFFAB47BC)
            : isRare
                ? const Color(0xFF29B6F6)
                : isUncommon
                    ? const Color(0xFF66BB6A)
                    : const Color(0xFFA5C4A3);

    final Color textColor = isLegendary
        ? const Color(0xFFC47600)
        : isEpic
            ? const Color(0xFF7B1FA2)
            : isRare
                ? const Color(0xFF0277BD)
                : isUncommon
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF4A6B46);

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 11,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 9 : 14),
        border: Border.all(
          color: borderColor,
          width: isCelebratory ? 1.4 : 1.0,
        ),
        boxShadow: [
          if (isCelebratory)
            BoxShadow(
              color: borderColor.withAlpha(isLegendary ? 110 : 70),
              blurRadius: compact ? 6 : 10,
              offset: const Offset(0, 2),
            ),
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rarity.emoji,
            style: TextStyle(
              fontSize: compact ? 11 : 14,
              height: 1.1,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            rarity.label(isFr),
            style: TextStyle(
              fontSize: compact ? 10.5 : 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: textColor,
            ),
          ),
          if (isCelebratory) ...[
            SizedBox(width: compact ? 2 : 4),
            Text(
              isLegendary ? '✨' : '★',
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                color: borderColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (showXp) ...[
            SizedBox(width: compact ? 4 : 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${rarity.totalPoints} XP',
                style: TextStyle(
                  fontSize: compact ? 8.5 : 10.5,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return badge;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: badge,
    );
  }
}

/// Standout border + glow for discovery cards.
/// Common has a soft, crisp natural border that keeps the card clean and friendly rather than dull.
/// Higher tiers (rare, epic, legendary) receive vibrant colored glows and distinct borders.
class RarityFrame {
  RarityFrame._();

  static Border? border(DiscoveryRarity r) {
    switch (r) {
      case DiscoveryRarity.legendary:
        return Border.all(color: const Color(0xFFFFA000), width: 2.0);
      case DiscoveryRarity.epic:
        return Border.all(color: const Color(0xFFAB47BC), width: 1.8);
      case DiscoveryRarity.rare:
        return Border.all(color: const Color(0xFF29B6F6), width: 1.6);
      case DiscoveryRarity.uncommon:
        return Border.all(color: const Color(0xFF66BB6A).withAlpha(160), width: 1.2);
      case DiscoveryRarity.common:
        return Border.all(color: const Color(0xFFA5C4A3).withAlpha(100), width: 1.0);
    }
  }

  static List<BoxShadow> shadows(DiscoveryRarity r, [List<BoxShadow> base = const []]) {
    switch (r) {
      case DiscoveryRarity.legendary:
        return [
          ...base,
          BoxShadow(
            color: const Color(0xFFFFA000).withAlpha(85),
            blurRadius: 16,
            spreadRadius: 1.0,
            offset: const Offset(0, 3),
          ),
        ];
      case DiscoveryRarity.epic:
        return [
          ...base,
          BoxShadow(
            color: const Color(0xFFAB47BC).withAlpha(75),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ];
      case DiscoveryRarity.rare:
        return [
          ...base,
          BoxShadow(
            color: const Color(0xFF29B6F6).withAlpha(65),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ];
      case DiscoveryRarity.uncommon:
        return [
          ...base,
          BoxShadow(
            color: const Color(0xFF66BB6A).withAlpha(35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case DiscoveryRarity.common:
        return base.isNotEmpty
            ? base
            : [
                BoxShadow(
                  color: const Color(0xFFA5C4A3).withAlpha(35),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ];
    }
  }
}

/// Joyful (~2.4s), non-blocking celebration for rare / epic / legendary finds:
/// rainbow firework bursts, falling confetti, twinkle rings and a playful
/// shout-out card. Use [RarityCelebration.show] to play it above the screen.
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

  static const Duration duration = Duration(milliseconds: 2400);

  /// Plays the celebration in the root overlay.
  /// If [force] is true, celebration plays for any rarity tier.
  /// Otherwise, plays when [rarity.isCelebratory] is true.
  static void show(
    BuildContext context,
    DiscoveryRarity rarity, {
    bool isFr = false,
    bool force = false,
    VoidCallback? onDone,
  }) {
    if (!rarity.isCelebratory && !force) {
      onDone?.call();
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) {
      debugPrint('[Mossy] Overlay not found for RarityCelebration');
      onDone?.call();
      return;
    }
    // Gentle haptic tap and celebration sound
    HapticFeedback.lightImpact().catchError((_) {});
    SoundService.instance.playCelebrationSound().catchError((_) {});
    late final OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      try {
        entry.remove();
      } catch (_) {}
      onDone?.call();
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
  late final List<_Confetti> _confetti;
  late final String _shout;

  /// Bright, happy, kid-friendly palette shared by all tiers (+ tier color).
  static const List<Color> _rainbow = [
    Color(0xFFFF5D8F), // pink
    Color(0xFFFFC145), // sunny yellow
    Color(0xFF4CD7A0), // mint
    Color(0xFF4DB8FF), // sky blue
    Color(0xFFB48CFF), // lavender
    Color(0xFFFF8A4C), // orange
    Colors.white,
  ];

  static const Map<DiscoveryRarity, List<String>> _shoutsEn = {
    DiscoveryRarity.common: [
      'New plant in your Journal! 🌱',
      'Nature Explorer on a roll! 🌿',
      'Great catch, nature detective! 🔍',
    ],
    DiscoveryRarity.uncommon: [
      'Nice find! That one is special! 🍃',
      'Sharp eyes, explorer! ✨',
      'Uncommon discovery recorded! 🌿',
    ],
    DiscoveryRarity.rare: [
      'Wow, a rare find! 🎉',
      'Super spotter! You found something special! ✨',
      'Ooooh, sparkly discovery! 💎',
    ],
    DiscoveryRarity.epic: [
      'EPIC find! You are amazing! 🔮',
      'Whoa! Hardly anyone spots this one! 🌟',
      'Nature detective level: EPIC! 🕵️',
    ],
    DiscoveryRarity.legendary: [
      'LEGENDARY!!! You are a nature hero! 👑',
      'Unbelievable! A once-in-a-lifetime find! 🌈',
      'Mossy is jumping for joy! 🥳',
    ],
  };

  static const Map<DiscoveryRarity, List<String>> _shoutsFr = {
    DiscoveryRarity.common: [
      'Nouvelle plante dans ton Journal ! 🌱',
      'Explorateur de la nature en action ! 🌿',
      'Super trouvaille, détective ! 🔍',
    ],
    DiscoveryRarity.uncommon: [
      'Belle trouvaille ! Celle-ci est spéciale ! 🍃',
      'Quel œil d\'explorateur ! ✨',
      'Une jolie rareté découverte ! 🌿',
    ],
    DiscoveryRarity.rare: [
      'Waouh, une trouvaille rare ! 🎉',
      'Super explorateur ! Tu as trouvé quelque chose de spécial ! ✨',
      'Oh là là, une découverte qui brille ! 💎',
    ],
    DiscoveryRarity.epic: [
      'Trouvaille ÉPIQUE ! Tu es génial ! 🔮',
      'Waouh ! Presque personne ne voit celle-là ! 🌟',
      'Détective de la nature niveau ÉPIQUE ! 🕵️',
    ],
    DiscoveryRarity.legendary: [
      'LÉGENDAIRE !!! Tu es un héros de la nature ! 👑',
      'Incroyable ! Une trouvaille unique dans une vie ! 🌈',
      'Mossy saute de joie ! 🥳',
    ],
  };

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    final tier = widget.rarity.index; // 0..4
    final palette = <Color>[widget.rarity.color, widget.rarity.color, ..._rainbow];

    final shouts = (widget.isFr ? _shoutsFr : _shoutsEn)[widget.rarity] ??
        (widget.isFr ? _shoutsFr[DiscoveryRarity.rare]! : _shoutsEn[DiscoveryRarity.rare]!);
    _shout = shouts[rnd.nextInt(shouts.length)];

    final burstCount = 3 + tier; // 3, 4, 5, 6, 7
    _bursts = List.generate(burstCount, (i) {
      return _Burst(
        center: Offset(0.15 + rnd.nextDouble() * 0.7, 0.14 + rnd.nextDouble() * 0.34),
        start: (i * (0.5 / burstCount)).clamp(0.0, 0.55),
        ringColor: palette[rnd.nextInt(palette.length)],
        particles: List.generate(20, (j) {
          final angle = (j / 20) * math.pi * 2 + rnd.nextDouble() * 0.25;
          return _Particle(
            angle: angle,
            distance: 60 + rnd.nextDouble() * 70,
            size: 3 + rnd.nextDouble() * 3.5,
            color: palette[rnd.nextInt(palette.length)],
            shape: _Shape.values[rnd.nextInt(_Shape.values.length)],
          );
        }),
      );
    });

    final confettiCount = 20 + tier * 8; // 20, 28, 36, 44, 52
    _confetti = List.generate(confettiCount, (_) {
      return _Confetti(
        x: rnd.nextDouble(),
        start: rnd.nextDouble() * 0.35,
        speed: 0.75 + rnd.nextDouble() * 0.5,
        sway: 8 + rnd.nextDouble() * 18,
        phase: rnd.nextDouble() * math.pi * 2,
        spin: 2 + rnd.nextDouble() * 5,
        w: 5 + rnd.nextDouble() * 4,
        h: 8 + rnd.nextDouble() * 6,
        color: palette[rnd.nextInt(palette.length)],
      );
    });

    _controller = AnimationController(vsync: this, duration: RarityCelebration.duration)
      ..addStatusListener((status) {
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
    final bonus = r.bonusPoints > 0
        ? (widget.isFr ? '+${r.bonusPoints} points bonus !' : '+${r.bonusPoints} bonus XP!')
        : (widget.isFr ? '+${r.totalPoints} points gagnés !' : '+${r.totalPoints} XP earned!');

    return IgnorePointer(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CelebrationPainter(_controller, _bursts, _confetti),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 52,
              left: 16,
              right: 16,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) {
                    final t = _controller.value;
                    // Bouncy pop-in, gentle fade-out.
                    final pop = Curves.elasticOut.transform((t / 0.3).clamp(0.0, 1.0));
                    final fade = t > 0.82 ? ((1 - t) / 0.18).clamp(0.0, 1.0) : 1.0;
                    final wobble = math.sin(t * math.pi * 6) * 0.015 * (1 - t);
                    return Opacity(
                      opacity: fade,
                      child: Transform.rotate(
                        angle: wobble,
                        child: Transform.scale(scale: 0.3 + 0.7 * pop, child: child),
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(245),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: r.color, width: 2),
                      boxShadow: [
                        BoxShadow(color: r.color.withAlpha(110), blurRadius: 22, spreadRadius: 1),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _shout,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            color: r.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bonus,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE08A00),
                          ),
                        ),
                      ],
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

enum _Shape { circle, star, sparkle }

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final _Shape shape;
  const _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.shape,
  });
}

class _Burst {
  final Offset center; // fractions of the screen
  final double start; // 0..1 of the whole animation
  final Color ringColor;
  final List<_Particle> particles;
  const _Burst({
    required this.center,
    required this.start,
    required this.ringColor,
    required this.particles,
  });
}

class _Confetti {
  final double x; // fraction of width
  final double start;
  final double speed;
  final double sway;
  final double phase;
  final double spin;
  final double w;
  final double h;
  final Color color;
  const _Confetti({
    required this.x,
    required this.start,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.spin,
    required this.w,
    required this.h,
    required this.color,
  });
}

class _CelebrationPainter extends CustomPainter {
  final Animation<double> animation;
  final List<_Burst> bursts;
  final List<_Confetti> confetti;

  _CelebrationPainter(this.animation, this.bursts, this.confetti) : super(repaint: animation);

  static const double _burstLength = 0.42;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Falling confetti (behind the bursts).
    for (final c in confetti) {
      final local = ((t - c.start) / (1 - c.start)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final y = -20 + (size.height * 0.85) * local * c.speed;
      final x = c.x * size.width + math.sin(c.phase + local * 6) * c.sway;
      final alpha = local > 0.8 ? ((1 - local) / 0.2).clamp(0.0, 1.0) : 1.0;
      fill.color = c.color.withValues(alpha: alpha);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(c.phase + local * c.spin);
      // Flip-flop like paper confetti.
      canvas.scale(1, math.cos(local * c.spin * 2).abs().clamp(0.25, 1.0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: c.w, height: c.h),
          const Radius.circular(1.5),
        ),
        fill,
      );
      canvas.restore();
    }

    // Firework bursts.
    for (final b in bursts) {
      final local = ((t - b.start) / _burstLength).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final eased = Curves.easeOutCubic.transform(local);
      final alpha = (1 - local * local).clamp(0.0, 1.0);
      final origin = Offset(b.center.dx * size.width, b.center.dy * size.height);

      // Twinkle ring at the start of each burst.
      if (local < 0.5) {
        stroke.color = b.ringColor.withValues(alpha: (1 - local * 2).clamp(0.0, 1.0) * 0.8);
        canvas.drawCircle(origin, 8 + 46 * Curves.easeOut.transform(local * 2), stroke);
      }

      for (final p in b.particles) {
        final pos = origin +
            Offset(
              math.cos(p.angle) * p.distance * eased,
              math.sin(p.angle) * p.distance * eased + 30 * local * local, // gentle gravity
            );
        // Soft twinkle so particles shimmer as they fly.
        final twinkle = 0.75 + 0.25 * math.sin((t * 40) + p.angle * 5);
        fill.color = p.color.withValues(alpha: alpha * twinkle);
        final s = p.size * (1 - local * 0.45);
        switch (p.shape) {
          case _Shape.circle:
            canvas.drawCircle(pos, s, fill);
          case _Shape.star:
            _drawStar(canvas, pos, s * 2.4, 5, fill);
          case _Shape.sparkle:
            _drawStar(canvas, pos, s * 2.8, 4, fill, inner: 0.22);
        }
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, int points, Paint paint,
      {double inner = 0.45}) {
    final path = Path();
    final steps = points * 2;
    for (var i = 0; i < steps; i++) {
      final radius = i.isEven ? r : r * inner;
      final a = (math.pi / points) * i - math.pi / 2;
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
  bool shouldRepaint(covariant _CelebrationPainter old) => false;
}
