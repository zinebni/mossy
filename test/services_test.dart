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
