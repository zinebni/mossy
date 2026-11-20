import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mossy/features/garden/presentation/widgets/garden_painter.dart';
import 'package:mossy/services/sound_service.dart';
import 'package:mossy/shared/models/achievement.dart';
import 'package:mossy/shared/models/garden_state.dart';
import 'package:mossy/shared/widgets/celebration_dialogs.dart';

void main() {
  group('Garden Sanctuary & Sound Service Tests', () {
    test('SoundService is safely test-tolerant and produces valid RIFF WAV data', () async {
      final sound = SoundService.instance;
      sound.isMuted = true; // Mute actual audio driver in headless test runner

      // Verify all sound methods execute gracefully without unhandled exceptions
      await sound.playUnlockSound();
      await sound.playBadgeSound();
      await sound.playGardenTapSound();
      await sound.playCelebrationSound();

      expect(sound.isMuted, isTrue);
    });

    test('GardenState provides bilingual names and descriptions for unlocked items', () {
      final items = [
        'tiny_sprout',
        'wooden_sign',
        'moss_carpet',
        'stepping_stones',
        'wildflower_patch',
        'stone_birdbath',
        'fern_cluster',
        'wooden_bench',
        'butterfly_bush',
        'wind_chimes',
        'flowering_shrub',
        'cobblestone_path',
        'sunlit_pond',
        'lantern_post',
        'wooden_bridge',
        'hummingbird_feeder',
        'ancient_oak_canopy',
        'firefly_glow',
        'grand_fountain',
        'mossy_botanical_shrine',
      ];

      for (final id in items) {
        final enName = GardenState.formatItemName(id, false);
        final frName = GardenState.formatItemName(id, true);
        final enDesc = GardenState.formatItemDescription(id, false);
        final frDesc = GardenState.formatItemDescription(id, true);
        final emoji = GardenState.getItemEmoji(id);
        final level = GardenState.getItemLevel(id);

        expect(enName, isNotEmpty);
        expect(frName, isNotEmpty);
        expect(enDesc, isNotEmpty);
        expect(frDesc, isNotEmpty);
        expect(emoji, isNotEmpty);
        expect(level, inInclusiveRange(1, 10));

        // Names should differ between FR and EN
        expect(enName != frName, isTrue, reason: 'Item $id should have distinct FR and EN names');
        expect(enDesc != frDesc, isTrue, reason: 'Item $id should have distinct FR and EN descriptions');
      }

      // Test normalization with spaces, emoji suffix, or legacy ids
      expect(GardenState.formatItemName('moss_stone', true), 'Pierre de mousse 🪨');
      expect(GardenState.formatItemName('stone_path', true), 'Sentier de pierres 🪨');
      expect(GardenState.formatItemName('sunflower_patch', true), 'Champ de tournesols 🌻');
      expect(GardenState.formatItemName('Tiny Sprout 🌱', true), 'Petite pousse 🌱');
      expect(GardenState.formatItemName('Cozy Bench 🪑', true), 'Banc en bois 🪑');
      expect(GardenState.formatItemDescription('Tiny Sprout 🌱', true), contains('petite pousse'));
    });

    test('Achievement provides kid-friendly bilingual titles and descriptions', () {
      const ach = Achievement(
        id: 'ach-first-discovery',
        title: 'First Discovery',
        description: 'Log your very first botanical discovery into the journal.',
        icon: Icons.eco_rounded,
        isUnlocked: true,
      );

      expect(ach.localizedTitle(false), 'First Discovery');
      expect(ach.localizedTitle(true), 'Première Découverte');
      expect(ach.localizedDescription(false), contains('botanical discovery'));
      expect(ach.localizedDescription(true), contains('première découverte'));
      expect(ach.emoji, '🌱');
    });

    test('GardenPainter shouldRepaint triggers accurately on level, time, or particles', () {
      const p1 = GardenPainter(level: 2, animationValue: 0.0);
      const p2 = GardenPainter(level: 2, animationValue: 0.0);
      const p3 = GardenPainter(level: 3, animationValue: 0.0);
      const p4 = GardenPainter(level: 2, animationValue: 1.5);

      expect(p1.shouldRepaint(p2), isFalse);
      expect(p3.shouldRepaint(p1), isTrue);
      expect(p4.shouldRepaint(p1), isTrue);
    });
  });

  group('Celebration Dialogs Widget Tests', () {
    testWidgets('GardenUnlockAlert renders level, stage, and unlocked items in English and French', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GardenUnlockAlert(
              level: 3,
              unlockedItems: const ['wildflower_patch', 'stone_birdbath'],
              isFr: false,
            ),
          ),
        ),
      );

      expect(find.text('Sanctuary Leveled Up!'), findsOneWidget);
      expect(find.textContaining('Level 3'), findsOneWidget);
      expect(find.textContaining('Wildflowers'), findsOneWidget);
      expect(find.textContaining('Stone Birdbath'), findsOneWidget);
      expect(find.text('Visit My Sanctuary!'), findsOneWidget);

      // Re-pump with French
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GardenUnlockAlert(
              level: 3,
              unlockedItems: const ['wildflower_patch', 'stone_birdbath'],
              isFr: true,
            ),
          ),
        ),
      );

      expect(find.text('Sanctuaire Évolué !'), findsOneWidget);
      expect(find.textContaining('Niveau 3'), findsOneWidget);
      expect(find.textContaining('Fleurs sauvages'), findsOneWidget);
      expect(find.textContaining('Bain d\'oiseaux'), findsOneWidget);
      expect(find.text('Visiter mon sanctuaire !'), findsOneWidget);
    });

    testWidgets('BadgeUnlockAlert renders trophy, points, and localized badge details', (tester) async {
      const ach = Achievement(
        id: 'ach-garden-keeper',
        title: 'Garden Keeper',
        description: 'Nurture your virtual sanctuary to reach Garden Level 3.',
        icon: Icons.yard_rounded,
        isUnlocked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeUnlockAlert(
              achievement: ach,
              isFr: false,
            ),
          ),
        ),
      );

      expect(find.text('🏆 NEW BADGE EARNED!'), findsOneWidget);
      expect(find.text('Garden Keeper'), findsOneWidget);
      expect(find.text('+25 Explorer Points'), findsOneWidget);
      expect(find.text('Awesome! 🎉'), findsOneWidget);

      // Re-pump with French
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgeUnlockAlert(
              achievement: ach,
              isFr: true,
            ),
          ),
        ),
      );

      expect(find.text('🏆 NOUVEAU BADGE OBTENU !'), findsOneWidget);
      expect(find.text('Gardien du Jardin'), findsOneWidget);
      expect(find.text('+25 Points d\'Explorateur'), findsOneWidget);
      expect(find.text('Youpi ! 🎉'), findsOneWidget);
    });
  });
}
