import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/garden_state.dart';
import 'points_service.dart';
import 'supabase_service.dart';

/// Returns the SharedPreferences key for a user's virtual garden state.
String _gardenKey(String userId) => 'mossy_user_garden_v1_$userId';

/// Abstract interface for managing virtual garden state and progression.
abstract class GardenService {
  Future<GardenState> getGardenState(String userId);
  Future<GardenState> updateGardenLevel(String userId, int newLevel);
  Future<GardenState> unlockGardenItem(String userId, String itemId);
  Future<GardenState> checkProgression(String userId, int totalPoints);
}

/// Demo implementation of [GardenService] with per-user isolated,
/// SharedPreferences-persisted garden progression.
class DemoGardenService implements GardenService {
  final Map<String, GardenState> _userGardens = {};
  final Set<String> _loaded = {};

  void clear() {
    _userGardens.clear();
    _loaded.clear();
  }

  Future<void> clearUser(String userId) async {
    _userGardens.remove(userId);
    _loaded.remove(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_gardenKey(userId));
    } catch (_) {}
  }

  Future<void> _ensureLoaded(String userId) async {
    if (userId.isEmpty || _loaded.contains(userId)) return;
    _loaded.add(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_gardenKey(userId));
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _userGardens[userId] = GardenState.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[Mossy] DemoGardenService load error for $userId: $e');
    }
  }

  Future<void> _save(String userId, GardenState state) async {
    _userGardens[userId] = state;
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_gardenKey(userId), jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('[Mossy] DemoGardenService save error for $userId: $e');
    }
  }

  Future<GardenState> _getOrCreate(String userId) async {
    if (userId.isNotEmpty) {
      await _ensureLoaded(userId);
      if (_userGardens.containsKey(userId)) {
        return _userGardens[userId]!;
      }
    }

    // Determine if the user already has accumulated points in the ledger/profile
    int points = 0;
    if (userId.isNotEmpty) {
      try {
        points = await DemoPointsService().getTotalPoints(userId);
      } catch (_) {}
    }

    final initialLevel = points > 0 ? GardenState.calculateLevel(points) : 1;
    final state = GardenState(
      userId: userId,
      gardenLevel: initialLevel,
      totalPoints: points,
      unlockedItems: GardenState.defaultUnlockedItemsForLevel(initialLevel),
      updatedAt: DateTime.now(),
    );

    if (userId.isNotEmpty) {
      await _save(userId, state);
    }
    return state;
  }

  @override
  Future<GardenState> getGardenState(String userId) async {
    return await _getOrCreate(userId);
  }

  @override
  Future<GardenState> updateGardenLevel(String userId, int newLevel) async {
    final current = await _getOrCreate(userId);
    final clampedLevel = newLevel.clamp(GardenState.minLevel, GardenState.maxLevel);
    final effectiveLevel = math.max(current.gardenLevel, clampedLevel);

    final allUnlocked = <String>{
      ...current.unlockedItems,
      ...GardenState.defaultUnlockedItemsForLevel(effectiveLevel),
    }.toList();

    final pts = current.totalPoints >= GardenState.pointsForLevel(effectiveLevel)
        ? current.totalPoints
        : GardenState.pointsForLevel(effectiveLevel);

    final updated = current.copyWith(
      gardenLevel: effectiveLevel,
      totalPoints: pts,
      unlockedItems: allUnlocked,
      updatedAt: DateTime.now(),
    );

    if (userId.isNotEmpty) {
      await _save(userId, updated);
    }
    return updated;
  }

  @override
  Future<GardenState> unlockGardenItem(String userId, String itemId) async {
    final current = await _getOrCreate(userId);
    if (!current.unlockedItems.contains(itemId)) {
      final updatedList = List<String>.from(current.unlockedItems)..add(itemId);
      final updated = current.copyWith(
        unlockedItems: updatedList,
        updatedAt: DateTime.now(),
      );
      if (userId.isNotEmpty) {
        await _save(userId, updated);
      }
      return updated;
    }
    return current;
  }

  @override
  Future<GardenState> checkProgression(String userId, int totalPoints) async {
    final current = await _getOrCreate(userId);
    final targetLevel = GardenState.calculateLevel(totalPoints);
    final effectiveLevel = math.max(targetLevel, current.gardenLevel);

    final allUnlocked = <String>{
      ...current.unlockedItems,
      ...GardenState.defaultUnlockedItemsForLevel(effectiveLevel),
    }.toList();

    final updated = current.copyWith(
      gardenLevel: effectiveLevel,
      totalPoints: math.max(totalPoints, current.totalPoints),
      unlockedItems: allUnlocked,
      updatedAt: DateTime.now(),
    );

    if (userId.isNotEmpty) {
      await _save(userId, updated);
    }
    return updated;
  }
}

/// Supabase backed implementation of [GardenService] with offline local persistence fallback.
class SupabaseGardenService implements GardenService {
  final SupabaseService _supabaseService;
  final DemoGardenService _demoFallback = DemoGardenService();

  SupabaseGardenService(this._supabaseService);

  void clear() {
    _demoFallback.clear();
  }

  @override
  Future<GardenState> getGardenState(String userId) async {
    // 1. Always load the locally persisted copy first
    final local = await _demoFallback.getGardenState(userId);

    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized || userId.isEmpty) {
      return local;
    }

    try {
      // Primary table is 'garden_states' (from migrations), with fallback to 'garden_state'
      Map<String, dynamic>? response;
      try {
        response = await _supabaseService
            .from('garden_states')!
            .select()
            .eq('user_id', userId)
            .maybeSingle();
      } catch (_) {
        try {
          response = await _supabaseService
              .from('garden_state')!
              .select()
              .eq('user_id', userId)
              .maybeSingle();
        } catch (_) {}
      }

      if (response != null) {
        final dbGarden = GardenState.fromJson(response);
        // Take the highest level, points, and merge all items so progress is NEVER lost!
        final bestLevel = math.max(dbGarden.gardenLevel, local.gardenLevel);
        final bestPoints = math.max(dbGarden.totalPoints, local.totalPoints);
        final mergedItems = <String>{
          ...dbGarden.unlockedItems,
          ...local.unlockedItems,
          ...GardenState.defaultUnlockedItemsForLevel(bestLevel),
        }.toList();

        final merged = dbGarden.copyWith(
          gardenLevel: bestLevel,
          totalPoints: bestPoints,
          unlockedItems: mergedItems,
        );

        // Keep local cache synced
        await _demoFallback._save(userId, merged);

        // If local had advanced ahead of Supabase, sync back
        if (bestLevel > dbGarden.gardenLevel || mergedItems.length > dbGarden.unlockedItems.length) {
          _syncToSupabase(userId, merged);
        }
        return merged;
      } else {
        // No row in Supabase yet — initialize Supabase from local state
        _syncToSupabase(userId, local);
        return local;
      }
    } catch (e) {
      debugPrint('[Mossy] Supabase getGardenState failed: $e. Using local storage state.');
      return local;
    }
  }

  void _syncToSupabase(String userId, GardenState state) {
    if (userId.isEmpty || _supabaseService.isDemoMode || !_supabaseService.isInitialized) return;
    try {
      final payload = {
        'user_id': userId,
        'garden_level': state.gardenLevel,
        'unlocked_items': state.unlockedItems,
        'updated_at': DateTime.now().toIso8601String(),
      };
      _supabaseService.from('garden_states')?.upsert(payload).then((_) {}).catchError((_) {
        _supabaseService.from('garden_state')?.upsert(payload).then((_) {}).catchError((e) {
          debugPrint('[Mossy] Failed to sync garden_states to Supabase: $e');
        });
      });
    } catch (_) {}
  }

  @override
  Future<GardenState> updateGardenLevel(String userId, int newLevel) async {
    final local = await _demoFallback.updateGardenLevel(userId, newLevel);
    if (!_supabaseService.isDemoMode && _supabaseService.isInitialized && userId.isNotEmpty) {
      _syncToSupabase(userId, local);
    }
    return local;
  }

  @override
  Future<GardenState> unlockGardenItem(String userId, String itemId) async {
    final local = await _demoFallback.unlockGardenItem(userId, itemId);
    if (!_supabaseService.isDemoMode && _supabaseService.isInitialized && userId.isNotEmpty) {
      _syncToSupabase(userId, local);
    }
    return local;
  }

  @override
  Future<GardenState> checkProgression(String userId, int totalPoints) async {
    final local = await _demoFallback.checkProgression(userId, totalPoints);
    if (!_supabaseService.isDemoMode && _supabaseService.isInitialized && userId.isNotEmpty) {
      _syncToSupabase(userId, local);
    }
    return local;
  }
}
