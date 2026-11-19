import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mossy/shared/models/discovery.dart';
import 'package:mossy/shared/models/discovery_rarity.dart';
import 'package:mossy/shared/widgets/rarity_widgets.dart';

Discovery _d({Map<String, dynamic>? extra, String sci = 'Rosa gallica'}) => Discovery.fromJson({
      'id': 'x',
      'user_id': 'u1',
      'scientific_name': sci,
      'family': 'Rosaceae',
      'discovered_at': DateTime(2025).toIso8601String(),
      'created_at': DateTime(2025).toIso8601String(),
      ...?extra,
    });

void main() {
  group('Rarity system', () {
    test('engine is deterministic and everyday species are common', () {
      expect(RarityEngine.assign(scientificName: 'Rosa gallica', family: 'Rosaceae'),
          RarityEngine.assign(scientificName: 'rosa gallica', family: 'Rosaceae'));
      expect(RarityEngine.assign(scientificName: 'Bellis perennis'), DiscoveryRarity.common);
      expect(RarityEngine.assign(scientificName: 'Whatever x', family: 'Orchidaceae').index,
          greaterThanOrEqualTo(DiscoveryRarity.rare.index));
    });

    test('rarer tiers award strictly more XP', () {
      final pts = DiscoveryRarity.values.map((r) => r.totalPoints).toList();
      for (var i = 1; i < pts.length; i++) {
        expect(pts[i], greaterThan(pts[i - 1]));
      }
      expect(DiscoveryRarity.common.totalPoints, 15);
    });

    test('old records without rarity fall back safely; unknown values ignored', () {
      final old = _d();
      expect(old.rarity, RarityEngine.assign(scientificName: 'Rosa gallica', family: 'Rosaceae'));
      expect(_d(extra: {'rarity': 'garbage'}).rarity, old.rarity);
      expect(_d(extra: {'rarity': 'legendary'}).rarity, DiscoveryRarity.legendary);
    });

    test('json round trip keeps rarity; remote payload omits it', () {
      final d = _d(extra: {'rarity': 'epic'});
      expect(d.toJson()['rarity'], 'epic');
      expect(d.toJson(includeRarity: false).containsKey('rarity'), isFalse);
      expect(Discovery.fromJson(d.toJson()).rarity, DiscoveryRarity.epic);
    });

    testWidgets('celebration plays ~1.8s and removes itself', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () => RarityCelebration.show(ctx, DiscoveryRarity.legendary),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.byType(RarityCelebration), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump();
      expect(find.byType(RarityCelebration), findsNothing);
    });

    testWidgets('common finds do not trigger celebration', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => RarityCelebration.show(ctx, DiscoveryRarity.common),
            child: const Text('go'),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.byType(RarityCelebration), findsNothing);
    });
  });
}
