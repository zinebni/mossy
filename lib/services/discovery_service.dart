import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
/// Keeps all user finds saved across app launches even when offline.
/// Strictly scoped per user ID so multi-account data never leaks.
class LocalDiscoveryStore {
  static const String _legacyKey = 'mossy_user_discoveries_journal';
  static String _userStorageKey(String userId) => 'mossy_user_discoveries_journal_$userId';

  /// Load discoveries strictly for [userId].
  static Future<List<Discovery>> loadForUser(String userId) async {
    if (userId.isEmpty) return <Discovery>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userStorageKey(userId));
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = decoded
            .map((e) => Discovery.fromJson(e as Map<String, dynamic>))
            .where((d) =>
                d.userId == userId &&
                d.userId != 'starter-guide' &&
                d.userId != 'demo-user' &&
                d.userId != 'guest-user' &&
                !d.id.startsWith('d1000000-'))
            .toList();

        if (list.length != decoded.length) {
          await saveForUser(userId, list);
        }
        return list;
      }
      return <Discovery>[];
    } catch (e) {
      debugPrint('[Mossy] LocalDiscoveryStore load error: $e');
      return <Discovery>[];
    }
  }

  /// Save discoveries strictly for [userId].
  static Future<void> saveForUser(String userId, List<Discovery> list) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only keep records belonging to this user
      final userScoped = list.where((d) => d.userId == userId).toList();
      final jsonStr = jsonEncode(userScoped.map((d) => d.toJson()).toList());
      await prefs.setString(_userStorageKey(userId), jsonStr);
    } catch (e) {
      debugPrint('[Mossy] LocalDiscoveryStore saveForUser error: $e');
    }
  }

  /// Purges discoveries for a specific user.
  static Future<void> clearUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userStorageKey(userId));
    } catch (e) {
      debugPrint('[Mossy] LocalDiscoveryStore clearUser error: $e');
    }
  }

  /// Purges all discovery storage keys across the entire app.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key == _legacyKey || key.startsWith('mossy_user_discoveries_journal')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('[Mossy] LocalDiscoveryStore clearAll error: $e');
    }
  }

  /// Legacy load helper for backwards-compatibility; redirects to empty if no user.
  static Future<List<Discovery>> loadAll([String? userId]) async {
    if (userId != null && userId.isNotEmpty) {
      return loadForUser(userId);
    }
    return <Discovery>[];
  }

  /// Legacy save helper for backwards-compatibility.
  static Future<void> saveAll(List<Discovery> list, [String? userId]) async {
    if (userId != null && userId.isNotEmpty) {
      await saveForUser(userId, list);
    }
  }
}

/// Demo & offline implementation of [DiscoveryService] with user-scoped persistent local storage.
class DemoDiscoveryService implements DiscoveryService {
  final Map<String, List<Discovery>> _userCaches = {};

  void clearCache() {
    _userCaches.clear();
  }

  Future<List<Discovery>> _ensureLoaded(String userId) async {
    if (userId.isEmpty) return [];
    if (!_userCaches.containsKey(userId)) {
      _userCaches[userId] = await LocalDiscoveryStore.loadForUser(userId);
    }
    return _userCaches[userId]!;
  }

  @override
  Future<List<Discovery>> getDiscoveries({String? userId, bool? favoritesOnly}) async {
    if (userId == null || userId.isEmpty || userId == 'guest-user') {
      return <Discovery>[];
    }

    final list = await _ensureLoaded(userId);
    var result = List<Discovery>.from(list);

    result = result.where((d) => d.userId == userId).toList();

    if (favoritesOnly == true) {
      result = result.where((d) => d.isFavorite).toList();
    }
    result.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
    return result;
  }

  @override
  Future<Discovery?> getDiscoveryById(String id) async {
    for (final list in _userCaches.values) {
      try {
        return list.firstWhere((d) => d.id == id);
      } catch (_) {}
    }
    return null;
  }

  @override
  Future<Discovery> saveDiscovery(Discovery discovery) async {
    final userId = discovery.userId;
    if (userId.isEmpty) return discovery;

    final list = await _ensureLoaded(userId);
    final index = list.indexWhere((d) =>
        d.id == discovery.id ||
        (d.scientificName.toLowerCase() == discovery.scientificName.toLowerCase() &&
         d.userId == discovery.userId &&
         d.discoveredAt.difference(discovery.discoveredAt).abs().inSeconds < 15));
    if (index >= 0) {
      list[index] = discovery;
    } else {
      list.insert(0, discovery);
    }
    await LocalDiscoveryStore.saveForUser(userId, list);
    return discovery;
  }

  @override
  Future<Discovery> updateDiscovery(Discovery discovery) async {
    return saveDiscovery(discovery);
  }

  @override
  Future<void> deleteDiscovery(String id) async {
    for (final entry in _userCaches.entries) {
      final list = entry.value;
      final before = list.length;
      list.removeWhere((d) => d.id == id);
      if (list.length != before) {
        await LocalDiscoveryStore.saveForUser(entry.key, list);
      }
    }
  }

  @override
  Future<Discovery> toggleFavorite(String id) async {
    for (final entry in _userCaches.entries) {
      final list = entry.value;
      final index = list.indexWhere((d) => d.id == id);
      if (index >= 0) {
        final current = list[index];
        final updated = current.copyWith(isFavorite: !current.isFavorite);
        list[index] = updated;
        await LocalDiscoveryStore.saveForUser(entry.key, list);
        return updated;
      }
    }
    throw Exception('Discovery not found: $id');
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

  void clearCache() {
    _demoFallback.clearCache();
  }

  bool get _canUseSupabase =>
      !_supabaseService.isDemoMode &&
      _supabaseService.isInitialized &&
      _supabaseService.auth?.currentUser != null;

  @override
  Future<List<Discovery>> getDiscoveries({String? userId, bool? favoritesOnly}) async {
    final effectiveUserId = userId ?? _supabaseService.auth?.currentUser?.id;
    if (effectiveUserId == null || effectiveUserId.isEmpty || effectiveUserId == 'guest-user') {
      return <Discovery>[];
    }

    // 1. Load local cache first
    final localList = await _demoFallback.getDiscoveries(userId: effectiveUserId, favoritesOnly: favoritesOnly);

    if (!_canUseSupabase) {
      return localList;
    }

    try {
      final currentUserId = _supabaseService.auth!.currentUser!.id;
      if (effectiveUserId != currentUserId) {
        return localList;
      }

      var query = _supabaseService.from('discoveries')!.select().eq('user_id', currentUserId);

      if (favoritesOnly == true) {
        query = query.eq('is_favorite', true);
      }

      final response = await query.order('discovered_at', ascending: false);
      final remoteList = (response as List<dynamic>)
          .map((e) => Discovery.fromJson(e as Map<String, dynamic>))
          .where((d) => d.userId == currentUserId)
          .toList();

      // Merge: remote takes precedence; preserve any local user discoveries not yet synced
      final remoteIds = remoteList.map((d) => d.id).toSet();
      final localOnly = localList.where((d) => d.userId == currentUserId && !remoteIds.contains(d.id)).toList();

      final combined = [...remoteList, ...localOnly];
      combined.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));

      // Update local store with fresh remote data strictly for this user
      await LocalDiscoveryStore.saveForUser(currentUserId, combined);
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
      final payload = discovery.copyWith(userId: currentUser.id).toJson(includeRarity: false);

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
      final payload = discovery.copyWith(userId: currentUser.id).toJson(includeRarity: false);

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

