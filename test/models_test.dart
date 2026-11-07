import 'package:flutter_test/flutter_test.dart';
import 'package:mossy/shared/models/discovery.dart';
import 'package:mossy/shared/models/garden_state.dart';
import 'package:mossy/shared/models/mission.dart';
import 'package:mossy/shared/models/user_profile.dart';

void main() {
  group('Discovery Model Tests', () {
    final now = DateTime.utc(2025, 5, 10, 14, 30);

    test('Discovery computes confidenceLabel correctly', () {
      final high = Discovery(
        id: 'd-1',
        userId: 'u-1',
        commonName: 'Common Dandelion',
        scientificName: 'Taraxacum officinale',
        family: 'Asteraceae',
        imagePath: 'https://example.com/flower.jpg',
        discoveredAt: now,
        createdAt: now,
        identificationScore: 0.85,
      );

      final medium = Discovery(
        id: 'd-2',
        userId: 'u-1',
        commonName: 'Common Daisy',
        scientificName: 'Bellis perennis',
        family: 'Asteraceae',
        imagePath: 'https://example.com/daisy.jpg',
        discoveredAt: now,
        createdAt: now,
        identificationScore: 0.55,
      );

      final low = Discovery(
        id: 'd-3',
        userId: 'u-1',
        commonName: 'Unknown Weed',
        scientificName: 'Flora incognita',
        family: 'Plantae',
        imagePath: 'https://example.com/weed.jpg',
        discoveredAt: now,
        createdAt: now,
        identificationScore: 0.15,
      );

      expect(high.confidenceLabel, 'Very Likely');
      expect(medium.confidenceLabel, 'Likely');
      expect(low.confidenceLabel, 'Uncertain');
    });

    test('Discovery hasLocation evaluates accurately', () {
      final located = Discovery(
        id: 'd-1',
        userId: 'u-1',
        commonName: 'Fern',
        scientificName: 'Polypodiopsida',
        family: 'Polypodiaceae',
        imagePath: '',
        discoveredAt: now,
        createdAt: now,
        identificationScore: 0.9,
        latitude: 48.8566,
        longitude: 2.3522,
      );

      final unlocated = Discovery(
        id: 'd-2',
        userId: 'u-1',
        commonName: 'Fern',
        scientificName: 'Polypodiopsida',
        family: 'Polypodiaceae',
        imagePath: '',
        discoveredAt: now,
        createdAt: now,
        identificationScore: 0.9,
      );

      expect(located.hasLocation, isTrue);
      expect(unlocated.hasLocation, isFalse);
    });

    test('Discovery JSON roundtrip preserves data', () {
      final original = Discovery(
        id: 'd-test-100',
        userId: 'user-abc',
        commonName: 'Wild Violet',
        scientificName: 'Viola odorata',
        family: 'Violaceae',
        imagePath: 'https://example.com/violet.png',
        discoveredAt: now,
        createdAt: now,
        identificationScore: 0.92,
        isFavorite: true,
        personalNotes: 'Found near an ancient mossy stone.',
        latitude: 51.5074,
        longitude: -0.1278,
      );

      final json = original.toJson();
      final parsed = Discovery.fromJson(json);

      expect(parsed.id, original.id);
      expect(parsed.commonName, original.commonName);
      expect(parsed.scientificName, original.scientificName);
      expect(parsed.family, original.family);
      expect(parsed.isFavorite, isTrue);
      expect(parsed.personalNotes, original.personalNotes);
      expect(parsed.latitude, original.latitude);
      expect(parsed.longitude, original.longitude);
      expect(parsed.identificationScore, original.identificationScore);
    });
  });

  group('GardenState Model Tests', () {
    test('pointsForLevel scales appropriately across levels', () {
      expect(GardenState.pointsForLevel(1), 0);
      expect(GardenState.pointsForLevel(2), 50);
      expect(GardenState.pointsForLevel(3), 150);
      expect(GardenState.pointsForLevel(5), 500);
      expect(GardenState.pointsForLevel(10), 2250);
    });

    test('Garden stageName reflects development stages', () {
      final stage1 = GardenState(userId: 'u-1', gardenLevel: 1);
      final stage2 = GardenState(userId: 'u-1', gardenLevel: 2);
      final stage3 = GardenState(userId: 'u-1', gardenLevel: 3);
      final stage7 = GardenState(userId: 'u-1', gardenLevel: 7);

      expect(stage1.stageName, 'Empty Plot');
      expect(stage2.stageName, 'Moss Patch');
      expect(stage3.stageName, 'First Sprouts');
      expect(stage7.stageName, 'Growing Forest');
    });

    test('GardenState item unlock works via copyWith', () {
      final garden = GardenState(userId: 'u-1', gardenLevel: 1, unlockedItems: ['sprout']);
      final updated = garden.copyWith(unlockedItems: [...garden.unlockedItems, 'stone-bench']);

      expect(updated.unlockedItems, contains('sprout'));
      expect(updated.unlockedItems, contains('stone-bench'));
    });
  });

  group('Mission & UserProfile Models Tests', () {
    test('Mission properties are cleanly populated', () {
      const mission = Mission(
        id: 'm-1',
        title: 'Find Yellow Flower',
        description: 'Search sunny lawn edges',
        category: MissionCategory.daily,
        difficulty: MissionDifficulty.easy,
        rewardPoints: 60,
      );

      expect(mission.category, MissionCategory.daily);
      expect(mission.difficulty, MissionDifficulty.easy);
      expect(mission.rewardPoints, 60);
    });

    test('UserProfile calculates level from points', () {
      expect(UserProfile.calculateLevel(0), 1);
      expect(UserProfile.calculateLevel(49), 1);
      expect(UserProfile.calculateLevel(50), 2);
      expect(UserProfile.calculateLevel(99), 2);
      expect(UserProfile.calculateLevel(150), 3);
      expect(UserProfile.calculateLevel(1200), 7);
    });
  });
}
