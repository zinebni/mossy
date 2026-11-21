import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mossy/features/discovery_map/presentation/discovery_map_screen.dart';
import 'package:mossy/services/discovery_service.dart';
import 'package:mossy/shared/models/discovery.dart';
import 'package:mossy/shared/models/discovery_rarity.dart';
import 'package:mossy/shared/providers/app_providers.dart';

Discovery _mockDiscovery({
  required String id,
  required String name,
  required String sci,
  double? lat,
  double? lng,
  DiscoveryRarity rarity = DiscoveryRarity.common,
}) {
  return Discovery(
    id: id,
    userId: 'test-user-123',
    commonName: name,
    scientificName: sci,
    family: 'Asteraceae',
    imagePath: '',
    discoveredAt: DateTime(2026, 5, 20),
    createdAt: DateTime(2026, 5, 20),
    latitude: lat,
    longitude: lng,
    rarity: rarity,
  );
}

class _FakeDiscoveryService implements DiscoveryService {
  final List<Discovery> discoveries;
  _FakeDiscoveryService(this.discoveries);

  @override
  Future<List<Discovery>> getDiscoveries({String? userId, bool? favoritesOnly}) async => discoveries;

  @override
  Future<Discovery?> getDiscoveryById(String id) async =>
      discoveries.where((d) => d.id == id).firstOrNull;

  @override
  Future<Discovery> saveDiscovery(Discovery discovery) async => discovery;

  @override
  Future<Discovery> updateDiscovery(Discovery discovery) async => discovery;

  @override
  Future<void> deleteDiscovery(String id) async {}

  @override
  Future<Discovery> toggleFavorite(String id) async => discoveries.first;

  @override
  Future<int> getDiscoveryCount({String? userId}) async => discoveries.length;

  @override
  Future<List<String>> getDiscoveredFamilies({String? userId}) async => [];
}

void main() {
  group('DiscoveryMapScreen Tests', () {
    testWidgets('renders OpenStreetMap and empty helper banner when no locations exist', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveriesProvider.overrideWith(
              (ref) => DiscoveriesNotifier(_FakeDiscoveryService([]), 'test-user-123', ref),
            ),
          ],
          child: const MaterialApp(
            home: DiscoveryMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Discovery count badge should show 0 plants
      expect(find.textContaining('0 Plants Mapped'), findsOneWidget);
      // Empty helper banner should be visible
      expect(find.text('No Mapped Plants Yet'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
    });

    testWidgets('renders real plant markers and opens preview card on tap', (tester) async {
      final plant1 = _mockDiscovery(
        id: 'plant-1',
        name: 'Silver Fir',
        sci: 'Abies alba',
        lat: 48.8566,
        lng: 2.3522,
        rarity: DiscoveryRarity.rare,
      );
      final plant2 = _mockDiscovery(
        id: 'plant-2',
        name: 'Dandelion',
        sci: 'Taraxacum officinale',
        lat: 48.8600,
        lng: 2.3600,
        rarity: DiscoveryRarity.common,
      );
      final plantWithoutLocation = _mockDiscovery(
        id: 'plant-3',
        name: 'Mystery Moss',
        sci: 'Bryum argenteum',
        lat: null,
        lng: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveriesProvider.overrideWith(
              (ref) => DiscoveriesNotifier(
                _FakeDiscoveryService([plant1, plant2, plantWithoutLocation]),
                'test-user-123',
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: DiscoveryMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Only the 2 plants with location should be counted
      expect(find.textContaining('2 Plants Mapped'), findsOneWidget);

      // Empty helper banner should NOT be visible when plants are mapped
      expect(find.text('No Mapped Plants Yet'), findsNothing);

      // Fit all plants button should be present
      expect(find.byIcon(Icons.filter_center_focus_rounded), findsOneWidget);

      // Find the marker by eco icon
      final ecoIcons = find.byIcon(Icons.eco_rounded);
      expect(ecoIcons, findsWidgets);

      // Tap on a marker
      await tester.tap(ecoIcons.first);
      await tester.pumpAndSettle();

      // Preview card should open with plant details and View in Journal button
      expect(find.text('View in Journal'), findsOneWidget);
    });

    testWidgets('handles multiple discoveries at identical coordinates with petal separation and location switcher', (tester) async {
      final plantA = _mockDiscovery(
        id: 'plant-a',
        name: 'Red Poppy',
        sci: 'Papaver rhoeas',
        lat: 48.8566,
        lng: 2.3522,
        rarity: DiscoveryRarity.common,
      );
      final plantB = _mockDiscovery(
        id: 'plant-b',
        name: 'Wild Chamomile',
        sci: 'Matricaria chamomilla',
        lat: 48.8566,
        lng: 2.3522, // Same coordinate!
        rarity: DiscoveryRarity.rare,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveriesProvider.overrideWith(
              (ref) => DiscoveriesNotifier(
                _FakeDiscoveryService([plantA, plantB]),
                'test-user-123',
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: DiscoveryMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Count shows 2 Plants Mapped
      expect(find.textContaining('2 Plants Mapped'), findsOneWidget);

      // Both markers should have group index badges (1/2 and 2/2)
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('2/2'), findsOneWidget);

      // Group center hub with count '2' should be rendered
      expect(find.text('2'), findsOneWidget);

      // Tap the first plant marker
      await tester.tap(find.text('1/2'));
      await tester.pumpAndSettle();

      // Preview card should display location group switcher
      expect(find.textContaining('Plant 1 of 2 at this spot'), findsOneWidget);

      // Tap next arrow in preview card switcher to switch to plant-b
      await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
      await tester.pumpAndSettle();

      // Card now shows plant 2
      expect(find.textContaining('Plant 2 of 2 at this spot'), findsOneWidget);
      expect(find.text('Wild Chamomile'), findsOneWidget);
    });
  });
}
