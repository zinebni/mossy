import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/sound_service.dart';
import '../models/achievement.dart';
import '../models/garden_state.dart';

/// Joyful celebration modal displayed when the user reaches a new garden level
/// and unlocks new botanical sanctuary items.
class GardenUnlockAlert extends StatelessWidget {
  final int level;
  final List<String> unlockedItems;
  final bool isFr;

  const GardenUnlockAlert({
    super.key,
    required this.level,
    required this.unlockedItems,
    this.isFr = false,
  });

  /// Plays the unlock chime sound and presents the celebration dialog.
  static Future<void> show(
    BuildContext context, {
    required int level,
    required List<String> unlockedItems,
    bool isFr = false,
  }) async {
    // Play celebratory unlock chime sound immediately
    SoundService.instance.playUnlockSound();

    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => GardenUnlockAlert(
        level: level,
        unlockedItems: unlockedItems,
        isFr: isFr,
      ),
    );
  }

  static String _stageName(int lvl, bool isFr) {
    if (!isFr) {
      switch (lvl) {
        case 1: return 'Empty Plot';
        case 2: return 'Moss Patch 🌱';
        case 3: return 'First Sprouts 🌿';
        case 4: return 'Flower Garden 🌸';
        case 5: return 'Wild Meadow 🌼';
        case 6: return 'Woodland Edge 🌲';
        case 7: return 'Growing Forest 🌳';
        case 8: return 'Nature Sanctuary 🍃';
        case 9: return 'Lush Paradise 🌈';
        case 10: return 'Botanical Wonderland ✨';
        default: return 'Garden Sanctuary';
      }
    }
    switch (lvl) {
      case 1: return 'Parcelle nue';
      case 2: return 'Tapis de mousse 🌱';
      case 3: return 'Premières pousses 🌿';
      case 4: return 'Jardin fleuri 🌸';
      case 5: return 'Prairie sauvage 🌼';
      case 6: return 'Lisière de forêt 🌲';
      case 7: return 'Forêt naissante 🌳';
      case 8: return 'Sanctuaire naturel 🍃';
      case 9: return 'Paradis verdoyant 🌈';
      case 10: return 'Merveille botanique ✨';
      default: return 'Sanctuaire fleuri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.sageGreen.withAlpha(60),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: AppColors.sageGreen.withAlpha(80), width: 2),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Joyful icon burst
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withAlpha(90),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.sageGreen, width: 2),
              ),
              child: const Center(
                child: Text('🎉', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Text(
              isFr ? 'Sanctuaire Évolué !' : 'Sanctuary Leveled Up!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${isFr ? 'Niveau' : 'Level'} $level • ${_stageName(level, isFr)}',
              style: const TextStyle(
                color: AppColors.sageGreen,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              isFr
                  ? 'Regarde ton jardin fleurir ! De nouveaux trésors ont été ajoutés à ton sanctuaire :'
                  : 'Look how your garden blossoms! New treasures have arrived in your sanctuary:',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Unlocked Items List
            if (unlockedItems.isNotEmpty)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: unlockedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final itemId = unlockedItems[index];
                    final emoji = GardenState.getItemEmoji(itemId);
                    final name = GardenState.formatItemName(itemId, isFr);
                    final desc = GardenState.formatItemDescription(itemId, isFr);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.mintGreen.withAlpha(120)),
                      ),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  desc,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondaryText,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Celebration button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isFr ? 'Visiter mon sanctuaire !' : 'Visit My Sanctuary!',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Joyful celebration modal displayed when a user earns a new achievement badge.
class BadgeUnlockAlert extends StatelessWidget {
  final Achievement achievement;
  final bool isFr;

  const BadgeUnlockAlert({
    super.key,
    required this.achievement,
    this.isFr = false,
  });

  /// Plays the triumphant fanfare sound and presents the badge celebration dialog.
  static Future<void> show(
    BuildContext context, {
    required Achievement achievement,
    bool isFr = false,
  }) async {
    // Play celebratory badge fanfare sound immediately
    SoundService.instance.playBadgeSound();

    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => BadgeUnlockAlert(
        achievement: achievement,
        isFr: isFr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = achievement.localizedTitle(isFr);
    final desc = achievement.localizedDescription(isFr);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withAlpha(60),
              blurRadius: 26,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFFFC107).withAlpha(160), width: 2),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Emblem with golden glow
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withAlpha(120),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(achievement.emoji, style: const TextStyle(fontSize: 42)),
              ),
            ),
            const SizedBox(height: 16),

            // Banner Title
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECB3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isFr ? '🏆 NOUVEAU BADGE OBTENU !' : '🏆 NEW BADGE EARNED!',
                style: const TextStyle(
                  color: Color(0xFFE65100),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
            ),
            const SizedBox(height: 8),

            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // Bonus Explorer Points tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mintGreen.withAlpha(140)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    isFr ? '+25 Points d\'Explorateur' : '+25 Explorer Points',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Dismiss Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isFr ? 'Youpi ! 🎉' : 'Awesome! 🎉',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
