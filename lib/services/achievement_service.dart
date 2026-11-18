import 'package:flutter/material.dart';
import '../shared/models/achievement.dart';
import 'supabase_service.dart';

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
}

/// Demo implementation with predefined Mossy milestones and per-user unlock tracking.
class DemoAchievementService implements AchievementService {
  static const List<Achievement> _achievementTemplates = [
    Achievement(
      id: 'ach-first-discovery',
      title: 'First Discovery',
      description: 'Log your very first botanical discovery into the journal.',
      icon: Icons.eco_rounded,
      isUnlocked: false,
    ),
    Achievement(
      id: 'ach-curious-explorer',
      title: 'Curious Explorer',
      description: 'Discover and catalog 5 different plant specimens.',
      icon: Icons.explore_rounded,
      isUnlocked: false,
    ),
    Achievement(
      id: 'ach-flower-collector',
      title: 'Flower Collector',
      description: 'Collect 10 plant discoveries in your personal nature journal.',
      icon: Icons.local_florist_rounded,
      isUnlocked: false,
    ),
    Achievement(
      id: 'ach-nature-enthusiast',
      title: 'Nature Enthusiast',
      description: 'Reach a milestone of 25 outdoor plant discoveries.',
      icon: Icons.park_rounded,
      isUnlocked: false,
    ),
    Achievement(
      id: 'ach-adventure-seeker',
      title: 'Adventure Seeker',
      description: 'Complete 5 exploration missions and daily nature quests.',
      icon: Icons.backpack_rounded,
      isUnlocked: false,
    ),
    Achievement(
      id: 'ach-garden-keeper',
      title: 'Garden Keeper',
      description: 'Nurture your virtual sanctuary to reach Garden Level 3.',
      icon: Icons.yard_rounded,
      isUnlocked: false,
    ),
    Achievement(
      id: 'ach-botanist',
      title: 'Botanist',
      description: 'Identify species belonging to 5 different plant families.',
      icon: Icons.menu_book_rounded,
      isUnlocked: false,
    ),
  ];

  final Map<String, Set<String>> _userUnlocked = {};
  final Map<String, Map<String, DateTime>> _userUnlockedAt = {};

  void clear() {
    _userUnlocked.clear();
    _userUnlockedAt.clear();
  }

  void clearUser(String userId) {
    _userUnlocked.remove(userId);
    _userUnlockedAt.remove(userId);
  }

  @override
  Future<List<Achievement>> getAchievements(String userId) async {
    await Future.delayed(const Duration(milliseconds: 30));
    final unlocked = _userUnlocked[userId] ?? const <String>{};
    final times = _userUnlockedAt[userId] ?? const <String, DateTime>{};

    return _achievementTemplates.map((ach) {
      final isUnl = unlocked.contains(ach.id);
      return ach.copyWith(
        isUnlocked: isUnl,
        unlockedAt: isUnl ? times[ach.id] : null,
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
    if (userId.isEmpty || userId == 'guest-user') return [];

    final newlyUnlocked = <Achievement>[];
    final unlocked = _userUnlocked.putIfAbsent(userId, () => <String>{});
    final times = _userUnlockedAt.putIfAbsent(userId, () => <String, DateTime>{});

    for (final ach in _achievementTemplates) {
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
        case 'ach-adventure-seeker':
          if ((completedMissionsCount ?? 0) >= 5) shouldUnlock = true;
          break;
        case 'ach-garden-keeper':
          if ((gardenLevel ?? 1) >= 3) shouldUnlock = true;
          break;
        case 'ach-botanist':
          if ((distinctFamilyCount ?? 0) >= 5) shouldUnlock = true;
          break;
      }

      if (shouldUnlock) {
        final now = DateTime.now();
        unlocked.add(ach.id);
        times[ach.id] = now;
        newlyUnlocked.add(ach.copyWith(isUnlocked: true, unlockedAt: now));
      }
    }

    return newlyUnlocked;
  }

  @override
  Future<Achievement?> unlockAchievement(String userId, String achievementId) async {
    if (userId.isEmpty || userId == 'guest-user') return null;

    final unlocked = _userUnlocked.putIfAbsent(userId, () => <String>{});
    final times = _userUnlockedAt.putIfAbsent(userId, () => <String, DateTime>{});

    try {
      final ach = _achievementTemplates.firstWhere((a) => a.id == achievementId);
      final now = DateTime.now();
      unlocked.add(ach.id);
      times[ach.id] = now;
      return ach.copyWith(isUnlocked: true, unlockedAt: now);
    } catch (_) {
      return null;
    }
  }
}

/// Supabase backed implementation of [AchievementService].
class SupabaseAchievementService implements AchievementService {
  final SupabaseService _supabaseService;
  final DemoAchievementService _demoFallback = DemoAchievementService();

  SupabaseAchievementService(this._supabaseService);

  void clear() {
    _demoFallback.clear();
  }

  @override
  Future<List<Achievement>> getAchievements(String userId) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.getAchievements(userId);
    }

    try {
      final response = await _supabaseService
          .from('user_achievements')!
          .select('*, achievement:achievements(*)') 
          .eq('user_id', userId);

      final list = (response as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        final achData = map['achievement'] as Map<String, dynamic>? ?? {};
        return Achievement(
          id: achData['id'] as String? ?? map['achievement_id'] as String? ?? '',
          title: achData['name'] as String? ?? 'Achievement',
          description: achData['description'] as String? ?? '',
          icon: Icons.emoji_events_rounded,
          isUnlocked: true,
          unlockedAt: map['earned_at'] != null ? DateTime.parse(map['earned_at'].toString()) : null,
        );
      }).toList();

      if (list.isEmpty) {
        return await _demoFallback.getAchievements(userId);
      }

      return list;
    } catch (e) {
      debugPrint('[Mossy] Supabase getAchievements error: $e. Falling back to demo.');
      return await _demoFallback.getAchievements(userId);
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
    return _demoFallback.checkAndAwardAchievements(
      userId,
      discoveryCount: discoveryCount,
      distinctFamilyCount: distinctFamilyCount,
      completedMissionsCount: completedMissionsCount,
      gardenLevel: gardenLevel,
    );
  }

  @override
  Future<Achievement?> unlockAchievement(String userId, String achievementId) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.unlockAchievement(userId, achievementId);
    }

    try {
      await _supabaseService.from('user_achievements')!.insert({
        'user_id': userId,
        'achievement_id': achievementId,
        'earned_at': DateTime.now().toIso8601String(),
      });
      return await _demoFallback.unlockAchievement(userId, achievementId);
    } catch (e) {
      debugPrint('[Mossy] Supabase unlockAchievement error: $e');
      return await _demoFallback.unlockAchievement(userId, achievementId);
    }
  }
}
