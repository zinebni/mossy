import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mossy/services/ai_content_service.dart';
import 'package:mossy/services/discovery_service.dart';
import 'package:mossy/services/garden_service.dart';
import 'package:mossy/services/image_storage_service.dart';
import 'package:mossy/services/plant_identification_service.dart';
import 'package:mossy/services/points_service.dart';
import 'package:mossy/shared/models/discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Demo Services Unit Tests', () {
    test('DemoPlantIdentificationService identifies sample image', () async {
      final service = DemoPlantIdentificationService();
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);

      final result = await service.identifyPlant(dummyBytes, 'sample.jpg');

      expect(result.bestMatch, isNotNull);
      expect(result.candidates, isNotEmpty);
      expect(result.bestMatch!.commonName, isNotEmpty);
      expect(result.bestMatch!.scientificName, isNotEmpty);
      expect(result.bestMatch!.score, greaterThan(0.0));
    });

    test('DemoAiContentService generates lore and observation tips', () async {
      final service = DemoAiContentService();

      final content = await service.generateContent(
        'Taraxacum officinale',
        'Common Dandelion',
        'Asteraceae',
        'en',
      );

      expect(content.introduction, isNotEmpty);
      expect(content.description, isNotEmpty);
      expect(content.funFacts, isNotEmpty);
      expect(content.observationTips, isNotEmpty);
    });

    test('DemoAiContentService produces species-specific family wisdom without generic boilerplate', () async {
      final service = DemoAiContentService();

      // Test dynamic mint family (Lamiaceae) plant not in curated list
      final mintContent = await service.generateContent(
        'Salvia officinalis',
        'Common Sage',
        'Lamiaceae',
        'en',
      );

      expect(mintContent.introduction, contains('square stems'));
      expect(mintContent.description, contains('Mediterranean'));
      expect(mintContent.funFacts.any((f) => f.contains('herbal teas') || f.contains('aroma')), isTrue);
      // Ensure rigid boilerplate strings are gone
      expect(mintContent.description.contains('a superpower called photosynthesis'), isFalse);
      expect(mintContent.description.contains('grows in gardens, parks, and wild places around the world'), isFalse);

      // Test dynamic rose family (Rosaceae) plant in French
      final roseContentFr = await service.generateContent(
        'Prunus spinosa',
        'Épine noire',
        'Rosaceae',
        'fr',
      );

      expect(roseContentFr.introduction, contains('famille des roses'));
      expect(roseContentFr.funFacts.any((f) => f.contains('5 pétales')), isTrue);
      expect(roseContentFr.safetyNote, contains('épines'));
      expect(roseContentFr.description.contains('photosynthèse'), isFalse);
      expect(roseContentFr.description.contains('pousse dans des jardins, des parcs et des espaces sauvages'), isFalse);
    });

    test('DemoGardenService manages garden level and item unlock', () async {
      final service = DemoGardenService();
      const userId = 'test-gardener';

      final initial = await service.getGardenState(userId);
      expect(initial.gardenLevel, 1);

      final upgraded = await service.updateGardenLevel(userId, 4);
      expect(upgraded.gardenLevel, 4);

      final withItem = await service.unlockGardenItem(userId, 'item-bird-bath');
      expect(withItem.unlockedItems, contains('item-bird-bath'));
    });

    test('DemoGardenService checkProgression updates level and unlocks items according to points', () async {
      final service = DemoGardenService();
      const userId = 'test-gardener-progression';

      // 150 points corresponds to Level 3
      final level3Garden = await service.checkProgression(userId, 150);
      expect(level3Garden.gardenLevel, 3);
      expect(level3Garden.unlockedItems, contains('wildflower_patch'));
      expect(level3Garden.unlockedItems, contains('stone_birdbath'));

      // Check with a point amount that doesn't trigger downgrade
      final sameGarden = await service.checkProgression(userId, 0);
      expect(sameGarden.gardenLevel, 3); // Level must not drop!
      expect(sameGarden.unlockedItems, contains('wildflower_patch'));

      // Advance to 300 points (Level 4)
      final level4Garden = await service.checkProgression(userId, 300);
      expect(level4Garden.gardenLevel, 4);
      expect(level4Garden.unlockedItems, contains('fern_cluster'));
      expect(level4Garden.unlockedItems, contains('wildflower_patch'));
    });

    test('DemoPointsService computes ledger and total points', () async {
      final service = DemoPointsService();
      const userId = 'test-points-user';

      final entry1 = await service.awardPoints(userId, 50, 'Daily Quest');
      expect(entry1.points, 50);

      final entry2 = await service.awardPoints(userId, 75, 'Plant Identification');
      expect(entry2.points, 75);

      final total = await service.getTotalPoints(userId);
      expect(total, greaterThanOrEqualTo(125));
    });

    test('DemoDiscoveryService persists and prevents duplicate discoveries', () async {
      final service = DemoDiscoveryService();
      final now = DateTime.now();

      final d1 = Discovery(
        id: 'uuid-test-1',
        userId: 'user-abc',
        commonName: 'Silver Fern',
        scientificName: 'Cyathea dealbata',
        family: 'Cyatheaceae',
        imagePath: '/photos/fern.jpg',
        discoveredAt: now,
        createdAt: now,
      );

      final d2 = Discovery(
        id: 'uuid-test-2', // different id from accidental rapid re-click
        userId: 'user-abc',
        commonName: 'Silver Fern',
        scientificName: 'Cyathea dealbata',
        family: 'Cyatheaceae',
        imagePath: '/photos/fern.jpg',
        discoveredAt: now.add(const Duration(seconds: 1)),
        createdAt: now.add(const Duration(seconds: 1)),
      );

      await service.saveDiscovery(d1);
      final countAfterFirst = await service.getDiscoveryCount(userId: 'user-abc');

      // Attempt rapid second save
      await service.saveDiscovery(d2);
      final countAfterSecond = await service.getDiscoveryCount(userId: 'user-abc');

      // Deduplication prevents second duplicate from inflating collection count
      expect(countAfterSecond, countAfterFirst);

      // Deletion test
      await service.deleteDiscovery('uuid-test-2');
      final found = await service.getDiscoveryById('uuid-test-2');
      expect(found, isNull);
    });

    test('ImageStorageService resolves URLs and cleans file path prefixes', () async {
      const sampleUrl = 'https://images.unsplash.com/photo-sample.jpg';
      final resolvedUrl = await ImageStorageService.resolveImagePath(sampleUrl);
      expect(resolvedUrl, sampleUrl);

      expect(ImageStorageService.resolveImagePathSync('file:///path/to/specimen.jpg'), '/path/to/specimen.jpg');
    });
  });
}
