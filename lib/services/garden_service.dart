import 'package:flutter/foundation.dart';
import '../shared/models/garden_state.dart';
import 'supabase_service.dart';

/// Abstract interface for managing virtual garden state and progression.
abstract class GardenService {
  Future<GardenState> getGardenState(String userId);
  Future<GardenState> updateGardenLevel(String userId, int newLevel);
  Future<GardenState> unlockGardenItem(String userId, String itemId);
  Future<GardenState> checkProgression(String userId, int totalPoints);
}

/// Demo implementation of [GardenService] with rich visual garden progression.
class DemoGardenService implements GardenService {
  GardenState _state = GardenState(
    userId: 'demo-user',
    gardenLevel: 3,
    unlockedItems: const [
      'tiny_sprout',
      'moss_carpet',
      'stepping_stones',
      'wildflower_patch',
      'stone_birdbath',
    ],
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  );

  static const Map<int, List<String>> _levelItemUnlocks = {
    1: ['tiny_sprout'],
    2: ['moss_carpet', 'stepping_stones'],
    3: ['wildflower_patch', 'stone_birdbath'],
    4: ['fern_cluster', 'wooden_bench'],
    5: ['butterfly_bush', 'wind_chimes'],
    6: ['flowering_shrub', 'cobblestone_path'],
    7: ['sunlit_pond', 'lantern_post'],
    8: ['wooden_bridge', 'hummingbird_feeder'],
    9: ['ancient_oak_canopy', 'firefly_glow'],
    10: ['grand_fountain', 'mossy_botanical_shrine'],
  };

  @override
  Future<GardenState> getGardenState(String userId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _state;
  }

  @override
  Future<GardenState> updateGardenLevel(String userId, int newLevel) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final clampedLevel = newLevel.clamp(GardenState.minLevel, GardenState.maxLevel);

    final allUnlocked = <String>{..._state.unlockedItems};
    for (int lvl = 1; lvl <= clampedLevel; lvl++) {
      if (_levelItemUnlocks.containsKey(lvl)) {
        allUnlocked.addAll(_levelItemUnlocks[lvl]!);
      }
    }

    _state = _state.copyWith(
      gardenLevel: clampedLevel,
      unlockedItems: allUnlocked.toList(),
      updatedAt: DateTime.now(),
    );
    return _state;
  }

  @override
  Future<GardenState> unlockGardenItem(String userId, String itemId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_state.unlockedItems.contains(itemId)) {
      final updatedList = List<String>.from(_state.unlockedItems)..add(itemId);
      _state = _state.copyWith(
        unlockedItems: updatedList,
        updatedAt: DateTime.now(),
      );
    }
    return _state;
  }

  @override
  Future<GardenState> checkProgression(String userId, int totalPoints) async {
    int targetLevel = 1;
    for (int lvl = 10; lvl >= 1; lvl--) {
      if (totalPoints >= GardenState.pointsForLevel(lvl)) {
        targetLevel = lvl;
        break;
      }
    }

    if (targetLevel > _state.gardenLevel) {
      return updateGardenLevel(userId, targetLevel);
    }
    return _state;
  }
}

/// Supabase backed implementation of [GardenService].
class SupabaseGardenService implements GardenService {
  final SupabaseService _supabaseService;
  final DemoGardenService _demoFallback = DemoGardenService();

  SupabaseGardenService(this._supabaseService);

  @override
  Future<GardenState> getGardenState(String userId) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.getGardenState(userId);
    }

    try {
      final response = await _supabaseService
          .from('garden_state')!
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return await _demoFallback.getGardenState(userId);
      }
      return GardenState.fromJson(response);
    } catch (e) {
      debugPrint('[Mossy] Supabase getGardenState failed: $e. Falling back to demo.');
      return await _demoFallback.getGardenState(userId);
    }
  }

  @override
  Future<GardenState> updateGardenLevel(String userId, int newLevel) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.updateGardenLevel(userId, newLevel);
    }

    try {
      final response = await _supabaseService
          .from('garden_state')!
          .upsert({
            'user_id': userId,
            'garden_level': newLevel,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return GardenState.fromJson(response);
    } catch (e) {
      debugPrint('[Mossy] Supabase updateGardenLevel failed: $e. Using demo fallback.');
      return await _demoFallback.updateGardenLevel(userId, newLevel);
    }
  }

  @override
  Future<GardenState> unlockGardenItem(String userId, String itemId) async {
    return await _demoFallback.unlockGardenItem(userId, itemId);
  }

  @override
  Future<GardenState> checkProgression(String userId, int totalPoints) async {
    return await _demoFallback.checkProgression(userId, totalPoints);
  }
}
