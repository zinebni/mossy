import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/sound_service.dart';
import '../../../shared/models/garden_state.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/celebration_dialogs.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mascot_with_accessory.dart';
import 'widgets/garden_painter.dart';

class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();

  static String localizedStageName(int level, bool isFr) {
    if (!isFr) {
      switch (level) {
        case 1: return 'Empty Plot';
        case 2: return 'Moss Patch';
        case 3: return 'First Sprouts';
        case 4: return 'Flower Garden';
        case 5: return 'Wild Meadow';
        case 6: return 'Woodland Edge';
        case 7: return 'Growing Forest';
        case 8: return 'Nature Sanctuary';
        case 9: return 'Lush Paradise';
        case 10: return 'Botanical Wonderland';
        default: return 'Garden';
      }
    }
    switch (level) {
      case 1: return 'Parcelle nue';
      case 2: return 'Tapis de mousse';
      case 3: return 'Premières pousses';
      case 4: return 'Jardin fleuri';
      case 5: return 'Prairie sauvage';
      case 6: return 'Lisière de forêt';
      case 7: return 'Forêt naissante';
      case 8: return 'Sanctuaire naturel';
      case 9: return 'Paradis verdoyant';
      case 10: return 'Merveille botanique';
      default: return 'Jardin';
    }
  }
}

class _GardenScreenState extends ConsumerState<GardenScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final List<GardenTapParticle> _particles = [];
  int? _lastKnownLevel;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleCanvasTap(TapDownDetails details) {
    // Play cheerful bubble/flower pop chime
    SoundService.instance.playGardenTapSound();

    final localPos = details.localPosition;
    final nowSeconds = _animController.value * 24.0;
    final rng = math.Random();
    final symbols = ['🌸', '✨', '🌱', '💖', '🌼', '⭐'];
    final colors = [
      AppColors.sageGreen,
      AppColors.peach,
      AppColors.butterYellow,
      AppColors.lavender,
      const Color(0xFFFF4081),
    ];

    setState(() {
      // Clean old particles
      _particles.removeWhere((p) => (nowSeconds - p.createdAt) > 1.2);

      // Spawn 4–5 joyful blossom particles
      for (int i = 0; i < 5; i++) {
        final angle = rng.nextDouble() * 2 * math.pi;
        final speed = 25.0 + rng.nextDouble() * 45.0;
        _particles.add(
          GardenTapParticle(
            position: localPos,
            color: colors[i % colors.length],
            size: 16.0 + rng.nextDouble() * 10.0,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed - 20.0,
            createdAt: nowSeconds,
            symbol: symbols[rng.nextInt(symbols.length)],
          ),
        );
      }
    });
  }

  void _showItemDetails(BuildContext context, String itemId, bool isFr) {
    SoundService.instance.playGardenTapSound();
    final name = GardenState.formatItemName(itemId, isFr);
    final desc = GardenState.formatItemDescription(itemId, isFr);
    final emoji = GardenState.getItemEmoji(itemId);
    final lvl = GardenState.getItemLevel(itemId);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 38))),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sageGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${isFr ? 'Débloqué au Niveau' : 'Unlocked at Level'} $lvl',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  isFr ? 'Fermer' : 'Close',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerCelebration(BuildContext context, GardenState garden, bool isFr) {
    GardenUnlockAlert.show(
      context,
      level: garden.gardenLevel,
      unlockedItems: GardenState.levelItemUnlocks[garden.gardenLevel] ?? garden.unlockedItems.take(3).toList(),
      isFr: isFr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final isFr = currentLocale.languageCode == 'fr' || l10n?.home == 'Accueil';
    final gardenAsync = ref.watch(gardenStateProvider);

    // Detect level up in garden state
    gardenAsync.whenData((garden) {
      if (_lastKnownLevel != null && garden.gardenLevel > _lastKnownLevel!) {
        final newLvl = garden.gardenLevel;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          GardenUnlockAlert.show(
            context,
            level: newLvl,
            unlockedItems: GardenState.levelItemUnlocks[newLvl] ?? const [],
            isFr: isFr,
          );
        });
      }
      _lastKnownLevel = garden.gardenLevel;
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: gardenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageGreen)),
        error: (e, _) => Center(child: Text('$e')),
        data: (garden) => CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: false,
            backgroundColor: AppColors.mintGreen.withAlpha(60),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                // Interactive Animated Garden Canvas
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: _handleCanvasTap,
                    child: AnimatedBuilder(
                      animation: _animController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: GardenPainter(
                            level: garden.gardenLevel,
                            animationValue: _animController.value * 24.0,
                            touchParticles: _particles,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Subtle Tap Hint on the canvas
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(190),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.sageGreen),
                        const SizedBox(width: 4),
                        Text(
                          isFr ? 'Touchez pour fleurir !' : 'Tap to blossom!',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Gradient overlay at bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.cream.withAlpha(240)],
                      ),
                    ),
                  ),
                ),

                // Top right level badge & celebratory button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Replay celebration sound & dialog
                      GestureDetector(
                        onTap: () => _triggerCelebration(context, garden, isFr),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                isFr ? 'Fêter !' : 'Celebrate!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.sageGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${isFr ? 'Niveau' : 'Level'} ${garden.gardenLevel}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.yourGarden ?? 'Your Garden',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkGreen,
                                ),
                          ),
                          Text(
                            GardenScreen.localizedStageName(garden.gardenLevel, isFr),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const MascotWithAccessory(
                      expression: MascotExpression.happy,
                      accessory: MascotAccessory.wateringCan,
                      size: 70,
                      animate: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Garden Progress Card
                MossyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFr ? 'Progression du jardin' : 'Garden Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${isFr ? 'Niveau' : 'Level'} ${garden.gardenLevel}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.sageGreen,
                            ),
                          ),
                          const Spacer(),
                          if (garden.gardenLevel < GardenState.maxLevel)
                            Text(
                              '${isFr ? 'Niveau' : 'Level'} ${garden.gardenLevel + 1}',
                              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                            )
                          else
                            Text(
                              isFr ? 'Niveau Max !' : 'Max Level!',
                              style: const TextStyle(
                                color: AppColors.sageGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: garden.progressToNextLevel,
                          minHeight: 10,
                          backgroundColor: AppColors.mintGreen.withAlpha(80),
                          color: AppColors.sageGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (garden.gardenLevel >= GardenState.maxLevel)
                        Text(
                          isFr
                              ? 'Merveille botanique maximale atteinte ! 🎉'
                              : 'Max botanical wonderland achieved! 🎉',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.sageGreen,
                                fontWeight: FontWeight.w600,
                              ),
                        )
                      else
                        Text(
                          '${(garden.progressToNextLevel * 100).toStringAsFixed(0)}% ${isFr ? 'vers le prochain niveau' : 'to next level'}${garden.pointsToNextLevel > 0 ? ' (${garden.pointsToNextLevel} pts ${isFr ? 'restants' : 'left'})' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // How to Grow Tips Card
                MossyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.sageGreen, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.growYourGarden ?? 'How to Grow Your Garden',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final tip in isFr
                          ? [
                              '🌱  Identifier de nouvelles plantes (+15 pts chacune)',
                              '🎯  Compléter des aventures (+10–50 pts)',
                              '🏆  Débloquer des succès et badges',
                              '⭐  Votre jardin grandit à chaque découverte !',
                            ]
                          : [
                              '🌱  Identify new plants (+15 pts each)',
                              '🎯  Complete adventures (+10–50 pts)',
                              '🏆  Unlock achievements and badges',
                              '⭐  Your garden grows with every discovery!',
                            ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(
                            tip,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),

                // Rich Bilingual Unlocked Items Section
                if (garden.unlockedItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        isFr ? 'Objets et trésors débloqués' : 'Unlocked Treasures & Decor',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${garden.unlockedItems.length} ${isFr ? 'objets' : 'items'}',
                        style: const TextStyle(fontSize: 12, color: AppColors.sageGreen, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: garden.unlockedItems.map((item) {
                      final emoji = GardenState.getItemEmoji(item);
                      final name = GardenState.formatItemName(item, isFr);
                      final lvl = GardenState.getItemLevel(item);

                      return InkWell(
                        onTap: () => _showItemDetails(context, item, isFr),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.mintGreen.withAlpha(120)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.mintGreen.withAlpha(60),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'L$lvl',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sageGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
