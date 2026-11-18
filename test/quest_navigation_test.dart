import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mossy/features/adventures/presentation/widgets/challenge_detail_sheet.dart';
import 'package:mossy/features/explore/presentation/explore_screen.dart';
import 'package:mossy/features/home/presentation/home_screen.dart';
import 'package:mossy/services/quest_service.dart';
import 'package:mossy/shared/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapWithRouter(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => child),
      GoRoute(path: '/explore', builder: (_, __) => const Scaffold(body: Text('ExploreScreenRoute'))),
      GoRoute(path: '/adventures', builder: (_, __) => const Scaffold(body: Text('AdventuresScreenRoute'))),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Quest Definition & Matching Logic Tests', () {
    test('matchesPlant correctly evaluates specificFamily', () {
      const quest = QuestDefinition(
        id: 'seasonal-herb',
        titleEn: 'Aromatic Herb Hunt',
        titleFr: 'Chasse aux Herbes Aromatiques',
        descriptionEn: 'Find 3 aromatic plants from the Lamiaceae family.',
        descriptionFr: 'Trouvez 3 plantes aromatiques de la famille Lamiaceae.',
        emoji: '🌿',
        type: QuestType.seasonal,
        requirementType: QuestRequirementType.specificFamily,
        requiredFamily: 'Lamiaceae',
      );

      expect(
        quest.matchesPlant(
          family: 'Lamiaceae',
          scientificName: 'Lavandula angustifolia',
          commonName: 'English Lavender',
        ),
        isTrue,
      );

      expect(
        quest.matchesPlant(
          family: 'lamiaceae', // case-insensitive check
          scientificName: 'Salvia officinalis',
          commonName: 'Common Sage',
        ),
        isTrue,
      );

      expect(
        quest.matchesPlant(
          family: 'Rosaceae',
          scientificName: 'Rosa canina',
          commonName: 'Dog Rose',
        ),
        isFalse,
      );
    });

    test('Meadow quest accepts both Asteraceae and Poaceae', () {
      final quest = QuestCatalog.byId('seasonal-meadow')!;

      expect(
        quest.matchesPlant(
          family: 'Asteraceae',
          scientificName: 'Bellis perennis',
          commonName: 'Common Daisy',
        ),
        isTrue,
      );

      expect(
        quest.matchesPlant(
          family: 'Poaceae',
          scientificName: 'Festuca rubra',
          commonName: 'Red Fescue',
        ),
        isTrue,
      );

      expect(
        quest.matchesPlant(
          family: 'Solanaceae',
          scientificName: 'Solanum dulcamara',
          commonName: 'Bittersweet Nightshade',
        ),
        isFalse,
      );
    });

    test('anyPlant requirement type matches any botanical find', () {
      final dailyQuest = QuestCatalog.activeDailyQuest(DateTime.now());

      if (dailyQuest.requirementType == QuestRequirementType.anyPlant) {
        expect(
          dailyQuest.matchesPlant(
            family: 'Brassicaceae',
            scientificName: 'Capsella bursa-pastoris',
            commonName: "Shepherd's Purse",
          ),
          isTrue,
        );
      }
    });
  });

  group('Challenge Detail Sheet & Priming Flow Tests', () {
    testWidgets('ChallengeDetailSheet displays quest details and action buttons',
        (tester) async {
      final questDef = QuestCatalog.activeQuests().first;
      final questWithProgress = QuestWithProgress(
        definition: questDef,
        progress: QuestProgress(
          questId: questDef.id,
          userId: 'test-user',
          currentCount: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _wrapWithRouter(
            Scaffold(
              body: ChallengeDetailSheet(quest: questWithProgress),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Check title and emoji are displayed
      expect(find.text(questDef.titleEn), findsOneWidget);
      expect(find.text(questDef.emoji), findsOneWidget);

      // Check start button is rendered
      expect(find.text('Start Challenge & Scan'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('ExploreScreen displays Primed Challenge banner when activeQuest is set',
        (tester) async {
      final container = ProviderContainer();
      final questDef = QuestCatalog.activeQuests().first;

      // Prime the scanner with the active quest
      container.read(activeQuestProvider.notifier).state = questDef;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const ExploreScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the primed challenge banner appears with quest title
      expect(find.text('PRIMED CHALLENGE'), findsOneWidget);
      expect(find.text(questDef.titleEn), findsOneWidget);
      expect(find.text('+${questDef.xpReward} XP'), findsOneWidget);

      // Verify clearing target removes banner
      await tester.tap(find.text('Clear'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PRIMED CHALLENGE'), findsNothing);
      expect(container.read(activeQuestProvider), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('HomeScreen renders the active daily challenge from core quest engine',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      // Ensure quests are loaded in container
      await container.read(questsProvider.notifier).loadQuests();

      final activeDaily = QuestCatalog.activeDailyQuest(DateTime.now());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _wrapWithRouter(const HomeScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      // Verify daily challenge title is shown on Home screen
      expect(find.text(activeDaily.titleEn), findsOneWidget);
      expect(find.text('DAILY CHALLENGE'), findsOneWidget);
      expect(find.text('Start & Scan'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
