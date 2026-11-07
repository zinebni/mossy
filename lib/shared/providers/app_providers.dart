import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/achievement_service.dart';
import '../../services/ai_content_service.dart';
import '../../services/camera_service.dart';
import '../../services/discovery_service.dart';
import '../../services/garden_service.dart';
import '../../services/location_service.dart';
import '../../services/mission_service.dart';
import '../../services/plant_identification_service.dart';
import '../../services/points_service.dart';
import '../../services/supabase_service.dart';

import '../models/achievement.dart';
import '../models/discovery.dart';
import '../models/garden_state.dart';
import '../models/user_mission.dart';
import '../models/user_profile.dart';
import 'auth_provider.dart';

// ============================================================================
// 1. CORE CONFIGURATION & SERVICE PROVIDERS
// ============================================================================

/// Tracks whether demo mode is actively enabled.
final demoModeProvider = StateProvider<bool>((ref) {
  return SupabaseService.instance.isDemoMode;
});

/// Shared SupabaseService instance provider.
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance;
});

/// Provider for plant identification service.
final plantIdentificationServiceProvider = Provider<PlantIdentificationService>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return isDemo
      ? DemoPlantIdentificationService()
      : SupabasePlantIdentificationService(supabase);
});

/// Provider for AI educational content generation.
final aiContentServiceProvider = Provider<AiContentService>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return isDemo
      ? DemoAiContentService()
      : SupabaseAiContentService(supabase);
});

/// Provider for discovery management.
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return isDemo
      ? DemoDiscoveryService()
      : SupabaseDiscoveryService(supabase);
});

/// Provider for nature missions and quests.
final missionServiceProvider = Provider<MissionService>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return isDemo
      ? DemoMissionService()
      : SupabaseMissionService(supabase);
});

/// Provider for achievements milestones.
final achievementServiceProvider = Provider<AchievementService>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return isDemo
      ? DemoAchievementService()
      : SupabaseAchievementService(supabase);
});

/// Provider for virtual garden state management.
final gardenServiceProvider = Provider<GardenService>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return isDemo
      ? DemoGardenService()
      : SupabaseGardenService(supabase);
});

/// Provider for points reward tracking.
final pointsServiceProvider = Provider<PointsService>((ref) {
  final isDemo = ref.watch(demoModeProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return isDemo
      ? DemoPointsService()
      : SupabasePointsService(supabase);
});

/// Provider for camera and image selection service.
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

/// Provider for optional geolocation service.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// ============================================================================
// 2. STATE NOTIFIERS AND DATA PROVIDERS
// ============================================================================

/// Notifier managing the list of user botanical discoveries.
class DiscoveriesNotifier extends StateNotifier<AsyncValue<List<Discovery>>> {
  final DiscoveryService _service;
  final String _userId;

  DiscoveriesNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    loadDiscoveries();
  }

  Future<void> loadDiscoveries() async {
    try {
      final discoveries = await _service.getDiscoveries(userId: _userId);
      state = AsyncValue.data(discoveries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDiscovery(Discovery discovery) async {
    final previousState = state;
    try {
      final saved = await _service.saveDiscovery(discovery);
      state = state.whenData((list) => [saved, ...list.where((d) => d.id != saved.id)]);
    } catch (e) {
      state = previousState;
      debugPrint('[Mossy] Failed to save discovery: $e');
      rethrow;
    }
  }

  Future<void> updateDiscovery(Discovery discovery) async {
    final previousState = state;
    try {
      final updated = await _service.updateDiscovery(discovery);
      state = state.whenData((list) =>
          list.map((d) => d.id == updated.id ? updated : d).toList());
    } catch (e) {
      state = previousState;
      debugPrint('[Mossy] Failed to update discovery: $e');
      rethrow;
    }
  }

  Future<void> deleteDiscovery(String id) async {
    final previousState = state;
    try {
      state = state.whenData((list) => list.where((d) => d.id != id).toList());
      await _service.deleteDiscovery(id);
    } catch (e) {
      state = previousState;
      debugPrint('[Mossy] Failed to delete discovery: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final updated = await _service.toggleFavorite(id);
      state = state.whenData((list) =>
          list.map((d) => d.id == updated.id ? updated : d).toList());
    } catch (e) {
      debugPrint('[Mossy] Failed to toggle favorite: $e');
    }
  }
}

/// Global provider for user discoveries.
final discoveriesProvider =
    StateNotifierProvider<DiscoveriesNotifier, AsyncValue<List<Discovery>>>((ref) {
  final service = ref.watch(discoveryServiceProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id ?? 'demo-user';
  return DiscoveriesNotifier(service, userId);
});

/// Notifier managing active, in-progress, and completed user challenges.
class MissionsNotifier extends StateNotifier<AsyncValue<List<UserMission>>> {
  final MissionService _service;
  final String _userId;

  MissionsNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    loadMissions();
  }

  Future<void> loadMissions() async {
    try {
      final missions = await _service.getUserMissions(_userId);
      state = AsyncValue.data(missions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserMission> startMission(String missionId) async {
    final updated = await _service.startMission(_userId, missionId);
    state = state.whenData((list) {
      final exists = list.any((um) => um.id == updated.id);
      if (exists) {
        return list.map((um) => um.id == updated.id ? updated : um).toList();
      }
      return [...list, updated];
    });
    return updated;
  }

  Future<UserMission> completeMission(
    String userMissionId, {
    Map<String, dynamic>? verificationData,
  }) async {
    final updated = await _service.completeMission(
      userMissionId,
      verificationData: verificationData,
    );
    state = state.whenData((list) =>
        list.map((um) => um.id == updated.id ? updated : um).toList());
    return updated;
  }

  Future<List<UserMission>> checkDiscoveryAgainstMissions(Discovery discovery) async {
    final currentList = state.value ?? [];
    final newlyCompleted = <UserMission>[];

    for (final um in currentList) {
      if (um.isCompleted) continue;
      final completed = await _service.verifyMissionWithDiscovery(
        _userId,
        um.missionId,
        discovery,
      );
      if (completed != null) {
        newlyCompleted.add(completed);
      }
    }

    if (newlyCompleted.isNotEmpty) {
      await loadMissions();
    }
    return newlyCompleted;
  }
}

/// Global provider for missions and adventures.
final missionsProvider =
    StateNotifierProvider<MissionsNotifier, AsyncValue<List<UserMission>>>((ref) {
  final service = ref.watch(missionServiceProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id ?? 'demo-user';
  return MissionsNotifier(service, userId);
});

/// Notifier managing achievement tracking and unlocks.
class AchievementsNotifier extends StateNotifier<AsyncValue<List<Achievement>>> {
  final AchievementService _service;
  final String _userId;

  AchievementsNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    loadAchievements();
  }

  Future<void> loadAchievements() async {
    try {
      final list = await _service.getAchievements(_userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<Achievement>> checkAndAward({
    int? discoveryCount,
    int? distinctFamilyCount,
    int? completedMissionsCount,
    int? gardenLevel,
  }) async {
    final newlyUnlocked = await _service.checkAndAwardAchievements(
      _userId,
      discoveryCount: discoveryCount,
      distinctFamilyCount: distinctFamilyCount,
      completedMissionsCount: completedMissionsCount,
      gardenLevel: gardenLevel,
    );

    if (newlyUnlocked.isNotEmpty) {
      await loadAchievements();
    }
    return newlyUnlocked;
  }

  Future<Achievement?> unlock(String achievementId) async {
    final unlocked = await _service.unlockAchievement(_userId, achievementId);
    if (unlocked != null) {
      state = state.whenData((list) =>
          list.map((a) => a.id == unlocked.id ? unlocked : a).toList());
    }
    return unlocked;
  }
}

/// Global provider for achievements.
final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AsyncValue<List<Achievement>>>((ref) {
  final service = ref.watch(achievementServiceProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id ?? 'demo-user';
  return AchievementsNotifier(service, userId);
});

/// Notifier managing virtual garden state.
class GardenStateNotifier extends StateNotifier<AsyncValue<GardenState>> {
  final GardenService _service;
  final String _userId;

  GardenStateNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    loadGardenState();
  }

  Future<void> loadGardenState() async {
    try {
      final garden = await _service.getGardenState(_userId);
      state = AsyncValue.data(garden);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<GardenState> updateLevel(int newLevel) async {
    final updated = await _service.updateGardenLevel(_userId, newLevel);
    state = AsyncValue.data(updated);
    return updated;
  }

  Future<GardenState> unlockItem(String itemId) async {
    final updated = await _service.unlockGardenItem(_userId, itemId);
    state = AsyncValue.data(updated);
    return updated;
  }

  Future<GardenState> checkProgression(int totalPoints) async {
    final updated = await _service.checkProgression(_userId, totalPoints);
    state = AsyncValue.data(updated);
    return updated;
  }
}

/// Global provider for garden state.
final gardenStateProvider =
    StateNotifierProvider<GardenStateNotifier, AsyncValue<GardenState>>((ref) {
  final service = ref.watch(gardenServiceProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id ?? 'demo-user';
  return GardenStateNotifier(service, userId);
});

/// Notifier managing user profile state and points advancement.
class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile>> {
  final PointsService _pointsService;
  final Ref _ref;

  UserProfileNotifier(this._pointsService, this._ref)
      : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    final authState = _ref.read(authProvider);
    final user = authState.user ?? AuthNotifier.demoUser;
    try {
      final total = await _pointsService.getTotalPoints(user.id);
      final updated = user.copyWith(
        totalPoints: total > 0 ? total : user.totalPoints,
        explorerLevel: UserProfile.calculateLevel(total > 0 ? total : user.totalPoints),
      );
      state = AsyncValue.data(updated);
    } catch (_) {
      state = AsyncValue.data(user);
    }
  }

  Future<void> addPoints(int points, String reason, {String? referenceId}) async {
    final current = state.value ?? AuthNotifier.demoUser;
    try {
      await _pointsService.awardPoints(
        current.id,
        points,
        reason,
        referenceId: referenceId,
      );

      final newTotal = current.totalPoints + points;
      final updated = current.copyWith(
        totalPoints: newTotal,
        explorerLevel: UserProfile.calculateLevel(newTotal),
      );

      state = AsyncValue.data(updated);
      _ref.read(authProvider.notifier).addPoints(points);

      // Check garden progression after point award
      await _ref.read(gardenStateProvider.notifier).checkProgression(newTotal);

      // Check achievements progression
      final discoveries = _ref.read(discoveriesProvider).value ?? [];
      final missions = _ref.read(missionsProvider).value ?? [];
      final completedMissions = missions.where((m) => m.isCompleted).length;
      final families = discoveries.map((d) => d.family).toSet().length;
      final garden = _ref.read(gardenStateProvider).value;

      await _ref.read(achievementsProvider.notifier).checkAndAward(
        discoveryCount: discoveries.length,
        distinctFamilyCount: families,
        completedMissionsCount: completedMissions,
        gardenLevel: garden?.gardenLevel ?? 1,
      );
    } catch (e) {
      debugPrint('[Mossy] Error adding points: $e');
    }
  }

  Future<void> updateProfile({String? username, String? avatarUrl}) async {
    final current = state.value;
    if (current == null) return;
    final updated = current.copyWith(
      username: username,
      avatarUrl: avatarUrl,
    );
    state = AsyncValue.data(updated);
    await _ref.read(authProvider.notifier).updateProfile(
      username: username,
      avatarUrl: avatarUrl,
    );
  }
}

/// Global provider for user profile.
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile>>((ref) {
  final pointsService = ref.watch(pointsServiceProvider);
  return UserProfileNotifier(pointsService, ref);
});

// ============================================================================
// 3. COMPUTED & SELECTOR PROVIDERS
// ============================================================================

/// Returns the 4 most recent discoveries for home screen and quick preview.
final recentDiscoveriesProvider = Provider<List<Discovery>>((ref) {
  final discoveriesAsync = ref.watch(discoveriesProvider);
  return discoveriesAsync.maybeWhen(
    data: (list) => list.take(4).toList(),
    orElse: () => const [],
  );
});

/// Data structure summarizing collection statistics.
class DiscoveryStats {
  final int totalDiscoveries;
  final int uniqueSpecies;
  final int distinctFamilies;
  final int favoriteCount;
  final Map<String, int> familyCounts;
  final String? mostCommonFamily;

  const DiscoveryStats({
    this.totalDiscoveries = 0,
    this.uniqueSpecies = 0,
    this.distinctFamilies = 0,
    this.favoriteCount = 0,
    this.familyCounts = const {},
    this.mostCommonFamily,
  });
}

/// Computes discovery statistics across the user collection.
final discoveryStatsProvider = Provider<DiscoveryStats>((ref) {
  final discoveriesAsync = ref.watch(discoveriesProvider);

  return discoveriesAsync.maybeWhen(
    data: (list) {
      if (list.isEmpty) return const DiscoveryStats();

      final uniqueSpecies = list.map((d) => d.scientificName).toSet().length;
      final distinctFamilies =
          list.map((d) => d.family).where((f) => f.isNotEmpty).toSet();
      final favorites = list.where((d) => d.isFavorite).length;

      final familyMap = <String, int>{};
      for (final d in list) {
        if (d.family.isNotEmpty) {
          familyMap[d.family] = (familyMap[d.family] ?? 0) + 1;
        }
      }

      String? topFamily;
      int maxFamilyCount = 0;
      familyMap.forEach((family, count) {
        if (count > maxFamilyCount) {
          maxFamilyCount = count;
          topFamily = family;
        }
      });

      return DiscoveryStats(
        totalDiscoveries: list.length,
        uniqueSpecies: uniqueSpecies,
        distinctFamilies: distinctFamilies.length,
        favoriteCount: favorites,
        familyCounts: familyMap,
        mostCommonFamily: topFamily,
      );
    },
    orElse: () => const DiscoveryStats(),
  );
});

// ============================================================================
// 3. APP LOCALIZATION & PREFERENCES PROVIDER
// ============================================================================

/// Notifier managing active app locale (English / French) with SharedPreferences persistence.
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _key = 'mossy_app_locale';

  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
      }
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, languageCode);
    } catch (_) {}
  }
}

/// Global provider for active app Locale.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});
