import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/ai_content.dart';
import '../shared/models/discovery.dart';
import 'supabase_service.dart';

/// Abstract interface for managing plant discoveries.
abstract class DiscoveryService {
  Future<List<Discovery>> getDiscoveries({String? userId, bool? favoritesOnly});
  Future<Discovery?> getDiscoveryById(String id);
  Future<Discovery> saveDiscovery(Discovery discovery);
  Future<Discovery> updateDiscovery(Discovery discovery);
  Future<void> deleteDiscovery(String id);
  Future<Discovery> toggleFavorite(String id);
  Future<int> getDiscoveryCount({String? userId});
  Future<List<String>> getDiscoveredFamilies({String? userId});
}

/// Persistent local storage helper for the Nature Discovery Journal.
/// Keeps all user finds saved across app launches even when offline or in guest mode.
class LocalDiscoveryStore {
  static const String _storageKey = 'mossy_user_discoveries_journal';

  static final List<Discovery> starterDiscoveries = [
    Discovery(
      id: 'd1000000-0000-0000-0000-000000000001',
      userId: 'starter-guide',
      scientificName: 'Bellis perennis',
      commonName: 'Common Daisy',
      family: 'Asteraceae',
      identificationScore: 0.94,
      imagePath: 'https://images.unsplash.com/photo-1560717789-0ac7c58ac90a?auto=format&fit=crop&w=800&q=80',
      latitude: 51.5074,
      longitude: -0.1278,
      personalNotes: 'Found thriving in the sunny meadow near the pond. Opening wide in morning light!',
      isFavorite: true,
      discoveredAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      aiContent: const AiContent(
        introduction: 'The cheerful Common Daisy is one of the most recognizable European wildflowers.',
        description: 'Bellis perennis features spoon-shaped leaves and bright white composite flower heads around a gold center.',
        funFacts: [
          'The name comes from Old English "day\'s eye" because it opens at sunrise.',
          'Each daisy flower is actually a composite head of over a hundred miniature florets.',
        ],
        observationTips: [
          'Watch the flower head track the sun throughout the midday hours.',
        ],
        safetyNote: 'Generally non-toxic, safe to touch.',
      ),
    ),
    Discovery(
      id: 'd1000000-0000-0000-0000-000000000002',
      userId: 'starter-guide',
      scientificName: 'Taraxacum officinale',
      commonName: 'Common Dandelion',
      family: 'Asteraceae',
      identificationScore: 0.91,
      imagePath: 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?auto=format&fit=crop&w=800&q=80',
      latitude: 51.5090,
      longitude: -0.1300,
      personalNotes: 'Spotted next to the ancient stone wall. Several honeybees were feeding on the rich nectar.',
      isFavorite: false,
      discoveredAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      aiContent: const AiContent(
        introduction: 'A resilient perennial herb that transforms from golden bloom to silver seed clock.',
        description: 'Features toothed basal leaves and hollow stems carrying vibrant composite flowers.',
        funFacts: [
          'Its parachute-like pappus seeds can travel miles on summer breezes.',
          'Dandelions are one of the earliest pollen sources for wild bees waking from winter.',
        ],
        observationTips: [
          'Notice how flowers close tightly before rainfall to protect precious pollen.',
        ],
      ),
    ),
    Discovery(
      id: 'd1000000-0000-0000-0000-000000000003',
      userId: 'starter-guide',
      scientificName: 'Rosa canina',
      commonName: 'Dog Rose',
      family: 'Rosaceae',
      identificationScore: 0.89,
      imagePath: 'https://images.unsplash.com/photo-1559563458-527698bf5295?auto=format&fit=crop&w=800&q=80',
      latitude: 51.5050,
      longitude: -0.1250,
      personalNotes: 'A sprawling bush on the hedgerow trail with sweet delicate aroma.',
      isFavorite: true,
      discoveredAt: DateTime.now().subtract(const Duration(days: 4, hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 4, hours: 2)),
      aiContent: const AiContent(
        introduction: 'An ancient wild climbing rose with delicate pale pink blossoms and curved thorns.',
        description: 'Deciduous shrub growing up to 3 meters with fragrant 5-petaled flowers and autumn rose hips.',
        funFacts: [
          'Wild rose hips contain up to 20 times more vitamin C than oranges.',
          'Curved thorns act like natural climbing hooks allowing it to scramble over hedges.',
        ],
        observationTips: [
          'Examine the distinctive hooked thorns along the climbing stems.',
        ],
      ),
    ),
    Discovery(
      id: 'd1000000-0000-0000-0000-000000000004',
      userId: 'starter-guide',
      scientificName: 'Lavandula angustifolia',
      commonName: 'English Lavender',
      family: 'Lamiaceae',
      identificationScore: 0.96,
      imagePath: 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?auto=format&fit=crop&w=800&q=80',
      latitude: 51.5120,
      longitude: -0.1210,
      personalNotes: 'In the community botanical garden. Incredible calming lavender perfume.',
      isFavorite: true,
      discoveredAt: DateTime.now().subtract(const Duration(days: 6, hours: 8)),
      createdAt: DateTime.now().subtract(const Duration(days: 6, hours: 8)),
      aiContent: const AiContent(
        introduction: 'Famous worldwide for its soothing fragrance, silvery leaves, and violet flower spikes.',
        description: 'Compact Mediterranean evergreen subshrub with narrow linear leaves and aromatic flowers.',
        funFacts: [
          'The botanical name comes from Latin "lavare", meaning "to wash", as Romans used it in thermal baths.',
          'Linalool in lavender oil is scientifically shown to promote relaxation.',
        ],
        observationTips: [
          'Gently roll a leaf between fingers to release natural essential oils.',
        ],
      ),
    ),
    Discovery(
      id: 'd1000000-0000-0000-0000-000000000005',
      userId: 'starter-guide',
      scientificName: 'Hedera helix',
      commonName: 'Common Ivy',
      family: 'Araliaceae',
      identificationScore: 0.90,
      imagePath: 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=800&q=80',
      latitude: 51.5030,
      longitude: -0.1330,
      personalNotes: 'Covering an old oak trunk. Beautiful deep green contrast.',
      isFavorite: false,
      discoveredAt: DateTime.now().subtract(const Duration(days: 8, hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 8, hours: 1)),
      aiContent: const AiContent(
        introduction: 'An evergreen woody climber that provides essential habitat and winter nectar.',
        description: 'Climbs using aerial rootlets. Displays lobed juvenile leaves and unlobed adult leaves.',
        funFacts: [
          'Blooms very late in autumn, providing vital food for hibernating insects.',
          'Does not choke healthy trees; it uses bark strictly for physical support.',
        ],
        observationTips: [
          'Compare the lobed lower climbing leaves with smooth upper flowering leaves.',
        ],
        safetyNote: 'Berries and leaves are mildly toxic if swallowed.',
      ),
    ),
    Discovery(
      id: 'd1000000-0000-0000-0000-000000000006',
      userId: 'starter-guide',
      scientificName: 'Trifolium repens',
      commonName: 'White Clover',
      family: 'Fabaceae',
      identificationScore: 0.93,
      imagePath: 'https://images.unsplash.com/photo-1589307004396-1c20163359d9?auto=format&fit=crop&w=800&q=80',
      latitude: 51.5080,
      longitude: -0.1290,
      personalNotes: 'Looked closely for a 4-leaf mutation! Found a lush patch by the path.',
      isFavorite: false,
      discoveredAt: DateTime.now().subtract(const Duration(days: 10, hours: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 10, hours: 4)),
      aiContent: const AiContent(
        introduction: 'A soil-nourishing groundcover with classic trifoliate leaves and sweet clover blossoms.',
        description: 'Perennial legume with creeping stems, three-part leaves, and white spherical flower heads.',
        funFacts: [
          'Fixes atmospheric nitrogen into the soil, acting as natural fertilizer.',
          'A four-leaf clover occurs in approximately one out of 10,000 specimens.',
        ],
        observationTips: [
          'Look for the subtle white crescent watermark on each individual leaflet.',
        ],
      ),
    ),
  ];

  static Future<List<Discovery>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded
            .map((e) => Discovery.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // First boot: pre-seed starter discoveries and persist them
      await saveAll(starterDiscoveries);
      return List<Discovery>.from(starterDiscoveries);
    } catch (e) {
      debugPrint('[Mossy] LocalDiscoveryStore load error: $e');
      return List<Discovery>.from(starterDiscoveries);
    }
  }

  static Future<void> saveAll(List<Discovery> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(list.map((d) => d.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('[Mossy] LocalDiscoveryStore saveAll error: $e');
    }
  }
}

/// Demo & offline implementation of [DiscoveryService] with persistent local storage.
class DemoDiscoveryService implements DiscoveryService {
  List<Discovery>? _cache;

  Future<List<Discovery>> _ensureLoaded() async {
    _cache ??= await LocalDiscoveryStore.loadAll();
    return _cache!;
  }

  @override
  Future<List<Discovery>> getDiscoveries({String? userId, bool? favoritesOnly}) async {
    final list = await _ensureLoaded();
    var result = List<Discovery>.from(list);

    if (userId != null && userId.isNotEmpty && userId != 'guest-user') {
      result = result
          .where((d) => d.userId == userId || d.userId == 'starter-guide' || d.userId == 'demo-user')
          .toList();
    }
    if (favoritesOnly == true) {
      result = result.where((d) => d.isFavorite).toList();
    }
    result.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
    return result;
  }

  @override
  Future<Discovery?> getDiscoveryById(String id) async {
    final list = await _ensureLoaded();
    try {
      return list.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Discovery> saveDiscovery(Discovery discovery) async {
    final list = await _ensureLoaded();
    final index = list.indexWhere((d) => d.id == discovery.id);
    if (index >= 0) {
      list[index] = discovery;
    } else {
      list.insert(0, discovery);
    }
    await LocalDiscoveryStore.saveAll(list);
    return discovery;
  }

  @override
  Future<Discovery> updateDiscovery(Discovery discovery) async {
    return saveDiscovery(discovery);
  }

  @override
  Future<void> deleteDiscovery(String id) async {
    final list = await _ensureLoaded();
    list.removeWhere((d) => d.id == id);
    await LocalDiscoveryStore.saveAll(list);
  }

  @override
  Future<Discovery> toggleFavorite(String id) async {
    final list = await _ensureLoaded();
    final index = list.indexWhere((d) => d.id == id);
    if (index < 0) {
      throw Exception('Discovery not found: $id');
    }
    final current = list[index];
    final updated = current.copyWith(isFavorite: !current.isFavorite);
    list[index] = updated;
    await LocalDiscoveryStore.saveAll(list);
    return updated;
  }

  @override
  Future<int> getDiscoveryCount({String? userId}) async {
    final list = await getDiscoveries(userId: userId);
    return list.length;
  }

  @override
  Future<List<String>> getDiscoveredFamilies({String? userId}) async {
    final list = await getDiscoveries(userId: userId);
    final families = list.map((d) => d.family).where((f) => f.isNotEmpty).toSet().toList();
    families.sort();
    return families;
  }
}

/// Supabase backed implementation of [DiscoveryService] with local persistent caching.
class SupabaseDiscoveryService implements DiscoveryService {
  final SupabaseService _supabaseService;
  final DemoDiscoveryService _demoFallback = DemoDiscoveryService();

  SupabaseDiscoveryService(this._supabaseService);

  bool get _canUseSupabase =>
      !_supabaseService.isDemoMode &&
      _supabaseService.isInitialized &&
      _supabaseService.auth?.currentUser != null;

  @override
  Future<List<Discovery>> getDiscoveries({String? userId, bool? favoritesOnly}) async {
    // 1. Load local cache first
    final localList = await _demoFallback.getDiscoveries(userId: userId, favoritesOnly: favoritesOnly);

    if (!_canUseSupabase) {
      return localList;
    }

    try {
      final currentUserId = _supabaseService.auth!.currentUser!.id;
      var query = _supabaseService.from('discoveries')!.select().eq('user_id', currentUserId);

      if (favoritesOnly == true) {
        query = query.eq('is_favorite', true);
      }

      final response = await query.order('discovered_at', ascending: false);
      final remoteList = (response as List<dynamic>)
          .map((e) => Discovery.fromJson(e as Map<String, dynamic>))
          .toList();

      // Merge: remote takes precedence; preserve any local user discoveries not yet synced
      final remoteIds = remoteList.map((d) => d.id).toSet();
      final localOnly = localList.where((d) => !remoteIds.contains(d.id)).toList();

      final combined = [...remoteList, ...localOnly];
      combined.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));

      // Update local store with fresh remote data
      await LocalDiscoveryStore.saveAll(combined);
      return combined;
    } catch (e) {
      debugPrint('[Mossy] Supabase getDiscoveries failed: $e. Returning cached local finds.');
      return localList;
    }
  }

  @override
  Future<Discovery?> getDiscoveryById(String id) async {
    if (!_canUseSupabase) {
      return _demoFallback.getDiscoveryById(id);
    }

    try {
      final response = await _supabaseService
          .from('discoveries')!
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return Discovery.fromJson(response);
      }
      return await _demoFallback.getDiscoveryById(id);
    } catch (e) {
      debugPrint('[Mossy] Supabase getDiscoveryById failed: $e. Using local store.');
      return _demoFallback.getDiscoveryById(id);
    }
  }

  @override
  Future<Discovery> saveDiscovery(Discovery discovery) async {
    // 1. Immediately persist locally so finds are never lost
    final saved = await _demoFallback.saveDiscovery(discovery);

    if (!_canUseSupabase) {
      return saved;
    }

    // 2. Sync to Supabase PostgreSQL when user is authenticated with a valid UUID
    try {
      final currentUser = _supabaseService.auth!.currentUser!;
      final payload = discovery.copyWith(userId: currentUser.id).toJson();

      final response = await _supabaseService
          .from('discoveries')!
          .upsert(payload)
          .select()
          .single();

      final remoteDiscovery = Discovery.fromJson(response);
      await _demoFallback.saveDiscovery(remoteDiscovery);
      return remoteDiscovery;
    } catch (e) {
      debugPrint('[Mossy] Supabase saveDiscovery remote sync failed: $e. Saved locally.');
      return saved;
    }
  }

  @override
  Future<Discovery> updateDiscovery(Discovery discovery) async {
    final updated = await _demoFallback.updateDiscovery(discovery);

    if (!_canUseSupabase) {
      return updated;
    }

    try {
      final currentUser = _supabaseService.auth!.currentUser!;
      final payload = discovery.copyWith(userId: currentUser.id).toJson();

      final response = await _supabaseService
          .from('discoveries')!
          .upsert(payload)
          .select()
          .single();

      return Discovery.fromJson(response);
    } catch (e) {
      debugPrint('[Mossy] Supabase updateDiscovery failed: $e. Local update preserved.');
      return updated;
    }
  }

  @override
  Future<void> deleteDiscovery(String id) async {
    await _demoFallback.deleteDiscovery(id);

    if (!_canUseSupabase) {
      return;
    }

    try {
      await _supabaseService.from('discoveries')!.delete().eq('id', id);
    } catch (e) {
      debugPrint('[Mossy] Supabase deleteDiscovery failed: $e. Local deletion preserved.');
    }
  }

  @override
  Future<Discovery> toggleFavorite(String id) async {
    final updated = await _demoFallback.toggleFavorite(id);

    if (!_canUseSupabase) {
      return updated;
    }

    try {
      await _supabaseService
          .from('discoveries')!
          .update({'is_favorite': updated.isFavorite})
          .eq('id', id);
      return updated;
    } catch (e) {
      debugPrint('[Mossy] Supabase toggleFavorite sync failed: $e. Local toggle preserved.');
      return updated;
    }
  }

  @override
  Future<int> getDiscoveryCount({String? userId}) async {
    final list = await getDiscoveries(userId: userId);
    return list.length;
  }

  @override
  Future<List<String>> getDiscoveredFamilies({String? userId}) async {
    final list = await getDiscoveries(userId: userId);
    final families = list.map((d) => d.family).where((f) => f.isNotEmpty).toSet().toList();
    families.sort();
    return families;
  }
}
