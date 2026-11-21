import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shared/models/achievement.dart';
import 'supabase_service.dart';

/// Returns a normalized user identifier for persistent storage.
String _normalizeUserId(String userId) => userId.trim().isEmpty ? 'local_user' : userId.trim();

/// Returns the SharedPreferences key for a user's earned achievements.
String _achievementsKey(String userId) => 'mossy_user_achievements_v1_${_normalizeUserId(userId)}';

/// Abstract interface for achievement tracking and unlock awards.
abstract class AchievementService {
  Future<List<Achievement>> getAchievements(String userId);
  Future<List<Achievement>> checkAndAwardAchievements(
    String userId, {
    int? discoveryCount,
    int? distinctFamilyCount,
    int? completedMissionsCount,
    int? gardenLevel,
  });
  Future<Achievement?> unlockAchievement(String userId, String achievementId);
  Future<void> clearUser(String userId);
}

/// Demo and offline implementation with predefined Mossy milestones and
/// isolated, SharedPreferences-persisted unlock tracking.
class DemoAchievementService implements AchievementService {
  static const List<Achievement> achievementTemplates = [
    Achievement(
      id: 'ach-first-discovery',
      title: 'First Discovery',
      description: 'Log your very first botanical discovery into the journal.',
      icon: Icons.eco_rounded,
      isUnlocked: false,
      maxProgress: 1,
      category: 'discovery',
    ),
    Achievement(
      id: 'ach-curious-explorer',
      title: 'Curious Explorer',
      description: 'Discover and catalog 5 different plant specimens.',
      icon: Icons.explore_rounded,
      isUnlocked: false,
      maxProgress: 5,
      category: 'discovery',
    ),
    Achievement(
      id: 'ach-flower-collector',
      title: 'Flower Collector',
      description: 'Collect 10 plant discoveries in your personal nature journal.',
      icon: Icons.local_florist_rounded,
      isUnlocked: false,
      maxProgress: 10,
      category: 'discovery',
    ),
    Achievement(
      id: 'ach-nature-enthusiast',
      title: 'Nature Enthusiast',
      description: 'Reach a milestone of 25 outdoor plant discoveries.',
      icon: Icons.park_rounded,
      isUnlocked: false,
      maxProgress: 25,
      category: 'discovery',
    ),
    Achievement(
      id: 'ach-botanist',
      title: 'Botanist',
      description: 'Identify species belonging to 3 different plant families.',
      icon: Icons.menu_book_rounded,
      isUnlocked: false,
      maxProgress: 3,
      category: 'botanist',
    ),
    Achievement(
      id: 'ach-adventure-seeker',
      title: 'Adventure Seeker',
      description: 'Complete 3 exploration missions or daily nature quests.',
      icon: Icons.backpack_rounded,
      isUnlocked: false,
      maxProgress: 3,
      category: 'missions',
    ),
    Achievement(
      id: 'ach-garden-keeper',
      title: 'Garden Keeper',
      description: 'Nurture your virtual sanctuary to reach Garden Level 2.',
      icon: Icons.yard_rounded,
      isUnlocked: false,
      maxProgress: 2,
      category: 'garden',
    ),
    Achievement(
      id: 'ach-master-gardener',
      title: 'Master Gardener',
      description: 'Nurture your virtual sanctuary to reach Garden Level 5.',
      icon: Icons.filter_vintage_rounded,
      isUnlocked: false,
      maxProgress: 5,
      category: 'garden',
    ),
    Achievement(
      id: 'ach-botanical-expert',
      title: 'Botanical Expert',
      description: 'Achieve a master collection of 50 plant discoveries.',
      icon: Icons.workspace_premium_rounded,
      isUnlocked: false,
      maxProgress: 50,
      category: 'discovery',
    ),
  ];

  final Map<String, Set<String>> _userUnlocked = {};
  final Map<String, Map<String, DateTime>> _userUnlockedAt = {};
  final Set<String> _loadedUsers = {};

  void clear() {
    _userUnlocked.clear();
    _userUnlockedAt.clear();
    _loadedUsers.clear();
  }

  @override
  Future<void> clearUser(String userId) async {
    final normId = _normalizeUserId(userId);
    _userUnlocked.remove(normId);
    _userUnlockedAt.remove(normId);
    _loadedUsers.remove(normId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_achievementsKey(userId));
    } catch (_) {}
  }

  Future<void> _ensureLoaded(String userId) async {
    final normId = _normalizeUserId(userId);
    if (_loadedUsers.contains(normId)) return;
    _loadedUsers.add(normId);

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_achievementsKey(userId));
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        final unlocked = _userUnlocked.putIfAbsent(normId, () => <String>{});
        final times = _userUnlockedAt.putIfAbsent(normId, () => <String, DateTime>{});

        decoded.forEach((key, val) {
          unlocked.add(key);
          times[key] = DateTime.tryParse(val.toString()) ?? DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('[Mossy] DemoAchievementService load error for $userId: $e');
    }
  }

  Future<void> _save(String userId) async {
    final normId = _normalizeUserId(userId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final times = _userUnlockedAt[normId] ?? {};
      final map = times.map((k, v) => MapEntry(k, v.toIso8601String()));
      await prefs.setString(_achievementsKey(userId), jsonEncode(map));
    } catch (e) {
      debugPrint('[Mossy] DemoAchievementService save error for $userId: $e');
    }
  }

  @override
  Future<List<Achievement>> getAchievements(String userId) async {
    await _ensureLoaded(userId);
    final normId = _normalizeUserId(userId);
    final unlocked = _userUnlocked[normId] ?? const <String>{};
    final times = _userUnlockedAt[normId] ?? const <String, DateTime>{};

    return achievementTemplates.map((ach) {
      final isUnl = unlocked.contains(ach.id);
      return ach.copyWith(
        isUnlocked: isUnl,
        unlockedAt: isUnl ? times[ach.id] : null,
        progress: isUnl ? ach.maxProgress : 0,
      );
    }).toList();
  }

  @override
  Future<List<Achievement>> checkAndAwardAchievements(
    String userId, {
    int? discoveryCount,
    int? distinctFamilyCount,
    int? completedMissionsCount,
    int? gardenLevel,
  }) async {
    await _ensureLoaded(userId);
    final normId = _normalizeUserId(userId);
    final newlyUnlocked = <Achievement>[];
    final unlocked = _userUnlocked.putIfAbsent(normId, () => <String>{});
    final times = _userUnlockedAt.putIfAbsent(normId, () => <String, DateTime>{});

    for (final ach in achievementTemplates) {
      if (unlocked.contains(ach.id)) continue;

      bool shouldUnlock = false;

      switch (ach.id) {
        case 'ach-first-discovery':
          if ((discoveryCount ?? 0) >= 1) shouldUnlock = true;
          break;
        case 'ach-curious-explorer':
          if ((discoveryCount ?? 0) >= 5) shouldUnlock = true;
          break;
        case 'ach-flower-collector':
          if ((discoveryCount ?? 0) >= 10) shouldUnlock = true;
          break;
        case 'ach-nature-enthusiast':
          if ((discoveryCount ?? 0) >= 25) shouldUnlock = true;
          break;
        case 'ach-botanical-expert':
          if ((discoveryCount ?? 0) >= 50) shouldUnlock = true;
          break;
        case 'ach-adventure-seeker':
          if ((completedMissionsCount ?? 0) >= 3) shouldUnlock = true;
          break;
        case 'ach-garden-keeper':
          if ((gardenLevel ?? 1) >= 2) shouldUnlock = true;
          break;
        case 'ach-master-gardener':
          if ((gardenLevel ?? 1) >= 5) shouldUnlock = true;
          break;
        case 'ach-botanist':
          if ((distinctFamilyCount ?? 0) >= 3) shouldUnlock = true;
          break;
      }

      if (shouldUnlock) {
        final now = DateTime.now();
        unlocked.add(ach.id);
        times[ach.id] = now;
        newlyUnlocked.add(ach.copyWith(
          isUnlocked: true,
          unlockedAt: now,
          progress: ach.maxProgress,
        ));
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _save(userId);
    }

    return newlyUnlocked;
  }

  @override
  Future<Achievement?> unlockAchievement(String userId, String achievementId) async {
    await _ensureLoaded(userId);
    final normId = _normalizeUserId(userId);
    final unlocked = _userUnlocked.putIfAbsent(normId, () => <String>{});
    final times = _userUnlockedAt.putIfAbsent(normId, () => <String, DateTime>{});

    try {
      final ach = achievementTemplates.firstWhere((a) => a.id == achievementId);
      final now = DateTime.now();
      unlocked.add(ach.id);
      times[ach.id] = now;
      await _save(userId);
      return ach.copyWith(
        isUnlocked: true,
        unlockedAt: now,
        progress: ach.maxProgress,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Supabase backed implementation of [AchievementService] with local-first
/// SharedPreferences fallback and bi-directional synchronization.
class SupabaseAchievementService implements AchievementService {
  final SupabaseService _supabaseService;
  final DemoAchievementService _demoFallback = DemoAchievementService();

  SupabaseAchievementService(this._supabaseService);

  void clear() {
    _demoFallback.clear();
  }

  @override
  Future<void> clearUser(String userId) async {
    await _demoFallback.clearUser(userId);
  }

  @override
  Future<List<Achievement>> getAchievements(String userId) async {
    // 1. Always load local persisted achievements first for instant response
    final localList = await _demoFallback.getAchievements(userId);

    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized || userId.isEmpty) {
      return localList;
    }

    // 2. Query Supabase for earned user achievements to sync with server
    try {
      final response = await _supabaseService
          .from('user_achievements')
          ?.select('*, achievement:achievements(*)')
          .eq('user_id', userId);

      if (response != null) {
        for (final item in (response as List<dynamic>)) {
          final map = item as Map<String, dynamic>;
          final achData = map['achievement'] as Map<String, dynamic>? ?? {};
          final name = (achData['name'] as String? ?? '').trim().toLowerCase();

          final match = DemoAchievementService.achievementTemplates.firstWhere(
            (t) => t.title.toLowerCase() == name,
            orElse: () => const Achievement(id: '', title: '', description: '', icon: Icons.help_outline),
          );

          if (match.id.isNotEmpty) {
            await _demoFallback.unlockAchievement(userId, match.id);
          }
        }
      }
      return await _demoFallback.getAchievements(userId);
    } catch (e) {
      debugPrint('[Mossy] Supabase getAchievements sync notice: $e. Using local data.');
      return localList;
    }
  }

  @override
  Future<List<Achievement>> checkAndAwardAchievements(
    String userId, {
    int? discoveryCount,
    int? distinctFamilyCount,
    int? completedMissionsCount,
    int? gardenLevel,
  }) async {
    // 1. Award locally with persistent storage
    final newlyUnlocked = await _demoFallback.checkAndAwardAchievements(
      userId,
      discoveryCount: discoveryCount,
      distinctFamilyCount: distinctFamilyCount,
      completedMissionsCount: completedMissionsCount,
      gardenLevel: gardenLevel,
    );

    // 2. If online and authenticated, attempt to notify Supabase RPC
    if (newlyUnlocked.isNotEmpty &&
        !_supabaseService.isDemoMode &&
        _supabaseService.isInitialized &&
        userId.isNotEmpty &&
        userId != 'guest-user' &&
        userId != 'local_user') {
      for (final ach in newlyUnlocked) {
        try {
          await _supabaseService.rpc('check_and_award_achievement', params: {
            'p_user_id': userId,
            'p_achievement_name': ach.title,
          });
        } catch (e) {
          debugPrint('[Mossy] Supabase check_and_award_achievement RPC notice for ${ach.title}: $e');
        }
      }
    }

    return newlyUnlocked;
  }

  @override
  Future<Achievement?> unlockAchievement(String userId, String achievementId) async {
    final unlocked = await _demoFallback.unlockAchievement(userId, achievementId);

    if (unlocked != null &&
        !_supabaseService.isDemoMode &&
        _supabaseService.isInitialized &&
        userId.isNotEmpty &&
        userId != 'guest-user' &&
        userId != 'local_user') {
      try {
        await _supabaseService.rpc('check_and_award_achievement', params: {
          'p_user_id': userId,
          'p_achievement_name': unlocked.title,
        });
      } catch (e) {
        debugPrint('[Mossy] Supabase unlock RPC notice: $e');
      }
    }

    return unlocked;
  }
}
