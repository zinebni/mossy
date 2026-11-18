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
/// Keeps all user finds saved across app launches even when offline or in guest mode.
class LocalDiscoveryStore {
  static const String _storageKey = 'mossy_user_discoveries_journal';

  static Future<List<Discovery>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = decoded
            .map((e) => Discovery.fromJson(e as Map<String, dynamic>))
            .where((d) =>
                d.userId != 'starter-guide' &&
                d.userId != 'demo-user' &&
                !d.id.startsWith('d1000000-'))
            .toList();

        // If legacy fake/seed discoveries were filtered out, purge them from persistent storage
        if (list.length != decoded.length) {
          await saveAll(list);
        }
        return list;
      }
      return <Discovery>[];
    } catch (e) {
      debugPrint('[Mossy] LocalDiscoveryStore load error: $e');
      return <Discovery>[];
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
          .where((d) => d.userId == userId)
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
