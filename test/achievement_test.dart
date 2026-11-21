import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mossy/services/achievement_service.dart';
import 'package:mossy/shared/models/achievement.dart';
import 'package:mossy/shared/models/discovery.dart';
import 'package:mossy/shared/providers/app_providers.dart';
import 'package:mossy/shared/providers/auth_provider.dart';
import 'package:mossy/shared/widgets/celebration_dialogs.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. DemoAchievementService Unit Tests', () {
    test('Returns 9 master templates with initial locked state', () async {
      final service = DemoAchievementService();
      final achievements = await service.getAchievements('test-user');

      expect(achievements.length, equals(9));
      expect(achievements.every((a) => !a.isUnlocked), isTrue);
      expect(achievements.map((a) => a.id).toList(), containsAll([
        'ach-first-discovery',
        'ach-curious-explorer',
        'ach-flower-collector',
        'ach-nature-enthusiast',
        'ach-botanist',
        'ach-adventure-seeker',
        'ach-garden-keeper',
        'ach-master-gardener',
        'ach-botanical-expert',
      ]));
    });

    test('Allows guest or empty user ID to unlock and query achievements', () async {
      final service = DemoAchievementService();

      final awardedGuest = await service.checkAndAwardAchievements('guest-user', discoveryCount: 1);
      expect(awardedGuest.length, equals(1));
      expect(awardedGuest.first.id, equals('ach-first-discovery'));

      final listGuest = await service.getAchievements('guest-user');
      final firstAch = listGuest.firstWhere((a) => a.id == 'ach-first-discovery');
      expect(firstAch.isUnlocked, isTrue);

      final awardedEmpty = await service.checkAndAwardAchievements('', discoveryCount: 1);
      expect(awardedEmpty.length, equals(1)); // Awards for local_user default identity

      final awardedEmptyAgain = await service.checkAndAwardAchievements('', discoveryCount: 1);
      expect(awardedEmptyAgain.length, equals(0)); // Already earned by local_user
    });

    test('Evaluates discovery and family milestones correctly', () async {
      final service = DemoAchievementService();
      const userId = 'botanist-tester';

      // 1 discovery -> First Discovery unlocked
      var awarded = await service.checkAndAwardAchievements(userId, discoveryCount: 1);
      expect(awarded.map((a) => a.id), contains('ach-first-discovery'));
      expect(awarded.length, equals(1));

      // Same count -> no new awards
      awarded = await service.checkAndAwardAchievements(userId, discoveryCount: 1);
      expect(awarded.isEmpty, isTrue);

      // 5 discoveries + 3 families -> Curious Explorer + Botanist unlocked
      awarded = await service.checkAndAwardAchievements(
        userId,
        discoveryCount: 5,
        distinctFamilyCount: 3,
      );
      expect(awarded.map((a) => a.id), containsAll(['ach-curious-explorer', 'ach-botanist']));
      expect(awarded.length, equals(2));
    });

    test('Evaluates garden and mission milestones correctly', () async {
      final service = DemoAchievementService();
      const userId = 'garden-tester';

      // Level 2 garden + 3 completed missions
      final awarded = await service.checkAndAwardAchievements(
        userId,
        gardenLevel: 2,
        completedMissionsCount: 3,
      );
      expect(awarded.map((a) => a.id), containsAll(['ach-garden-keeper', 'ach-adventure-seeker']));
    });

    test('Persists unlocked achievements to SharedPreferences across service instances', () async {
      const userId = 'persistence-user';
      final service1 = DemoAchievementService();

      // Unlock a badge with instance 1
      final awarded = await service1.checkAndAwardAchievements(userId, discoveryCount: 1);
      expect(awarded.length, equals(1));
      expect(awarded.first.id, equals('ach-first-discovery'));

      // Create brand-new service instance 2 (simulating app restart)
      final service2 = DemoAchievementService();
      final list = await service2.getAchievements(userId);
      final first = list.firstWhere((a) => a.id == 'ach-first-discovery');
      expect(first.isUnlocked, isTrue);
      expect(first.unlockedAt, isNotNull);

      // Other badges remain locked
      final second = list.firstWhere((a) => a.id == 'ach-curious-explorer');
      expect(second.isUnlocked, isFalse);
    });

    test('clearUser removes persisted achievements for that user', () async {
      const userId = 'wipe-user';
      final service = DemoAchievementService();
      await service.checkAndAwardAchievements(userId, discoveryCount: 1);

      var list = await service.getAchievements(userId);
      expect(list.firstWhere((a) => a.id == 'ach-first-discovery').isUnlocked, isTrue);

      await service.clearUser(userId);

      final service2 = DemoAchievementService();
      list = await service2.getAchievements(userId);
      expect(list.firstWhere((a) => a.id == 'ach-first-discovery').isUnlocked, isFalse);
    });
  });

  group('2. Achievement Model Localization & Emojis', () {
    test('Returns French localized title and description', () {
      const ach = Achievement(
        id: 'ach-first-discovery',
        title: 'First Discovery',
        description: 'Log your very first botanical discovery into the journal.',
        icon: Icons.eco_rounded,
      );

      expect(ach.localizedTitle(false), equals('First Discovery'));
      expect(ach.localizedTitle(true), equals('Première Découverte'));
      expect(ach.localizedDescription(false), contains('very first'));
      expect(ach.localizedDescription(true), contains('première découverte'));
      expect(ach.emoji, equals('🌱'));
    });

    test('Maps emojis for all milestone badges', () {
      const badges = [
        'ach-first-discovery',
        'ach-curious-explorer',
        'ach-flower-collector',
        'ach-nature-enthusiast',
        'ach-botanical-expert',
        'ach-adventure-seeker',
        'ach-garden-keeper',
        'ach-master-gardener',
        'ach-botanist',
      ];

      for (final id in badges) {
        final ach = Achievement(id: id, title: id, description: '', icon: Icons.star);
        expect(ach.emoji, isNotEmpty);
        expect(ach.emoji, isNot(equals('🏆')));
      }
    });
  });

  group('3. AchievementsNotifier Progression Integration Tests', () {
    test('checkProgression automatically evaluates milestones from state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).signUpWithEmail(
            'tester@mossy.test',
            'Password123',
            username: 'TestBotanist',
          );
      await container.read(userProfileProvider.notifier).loadProfile();

      final notifier = container.read(achievementsProvider.notifier);
      await notifier.loadAchievements();

      // Trigger progression with 1 discovery
      final awarded = await notifier.checkProgression(discoveryCount: 1);
      expect(awarded.length, equals(1));
      expect(awarded.first.id, equals('ach-first-discovery'));

      // latestBadgeAwardProvider is set
      expect(container.read(latestBadgeAwardProvider)?.id, equals('ach-first-discovery'));

      // achievementsProvider state is updated
      final state = container.read(achievementsProvider).value ?? [];
      final firstAch = state.firstWhere((a) => a.id == 'ach-first-discovery');
      expect(firstAch.isUnlocked, isTrue);
    });

    test('addDiscovery automatically triggers achievement evaluation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).signUpWithEmail(
            'tester2@mossy.test',
            'Password123',
            username: 'TestBotanist2',
          );
      await container.read(userProfileProvider.notifier).loadProfile();

      final discoveryNotifier = container.read(discoveriesProvider.notifier);

      final sampleDiscovery = Discovery(
        id: 'sample-disc-1',
        userId: 'test-user',
        commonName: 'Dandelion',
        scientificName: 'Taraxacum officinale',
        family: 'Asteraceae',
        imagePath: 'https://example.com/dandelion.jpg',
        discoveredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await discoveryNotifier.addDiscovery(sampleDiscovery);
      await container.read(achievementsProvider.notifier).loadAchievements();

      // Verify that First Discovery was automatically awarded
      final achievements = container.read(achievementsProvider).value ?? [];
      final firstAch = achievements.firstWhere((a) => a.id == 'ach-first-discovery');
      expect(firstAch.isUnlocked, isTrue);
    });
  });

  group('4. BadgeUnlockAlert Celebration Dialog Widget Tests', () {
    testWidgets('Renders badge celebration alert in English and French', (tester) async {
      const ach = Achievement(
        id: 'ach-first-discovery',
        title: 'First Discovery',
        description: 'Log your very first botanical discovery into the journal.',
        icon: Icons.eco_rounded,
        isUnlocked: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => BadgeUnlockAlert.show(ctx, achievement: ach, isFr: true),
                child: const Text('Open Badge'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Badge'));
      await tester.pumpAndSettle();

      expect(find.text('🏆 NOUVEAU BADGE OBTENU !'), findsOneWidget);
      expect(find.text('Première Découverte'), findsOneWidget);
      expect(find.text('🌱'), findsOneWidget);
      expect(find.text('Youpi ! 🎉'), findsOneWidget);

      await tester.tap(find.text('Youpi ! 🎉'));
      await tester.pumpAndSettle();
      expect(find.text('Première Découverte'), findsNothing);
    });
  });
}
