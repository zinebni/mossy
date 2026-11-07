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

/// Demo implementation with predefined Mossy milestones.
class DemoAchievementService implements AchievementService {
  static final List<Achievement> _defaultAchievements = [
    Achievement(
      id: 'ach-first-discovery',
      title: 'First Discovery',
      description: 'Log your very first botanical discovery into the journal.',
      icon: Icons.eco_rounded,
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Achievement(
      id: 'ach-curious-explorer',
      title: 'Curious Explorer',
      description: 'Discover and catalog 5 different plant specimens.',
      icon: Icons.explore_rounded,
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    const Achievement(
      id: 'ach-flower-collector',
      title: 'Flower Collector',
      description: 'Collect 10 plant discoveries in your personal nature journal.',
      icon: Icons.local_florist_rounded,
      isUnlocked: false,
    ),
    const Achievement(
      id: 'ach-nature-enthusiast',
      title: 'Nature Enthusiast',
      description: 'Reach a milestone of 25 outdoor plant discoveries.',
      icon: Icons.park_rounded,
      isUnlocked: false,
    ),
    const Achievement(
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
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Achievement(
      id: 'ach-botanist',
      title: 'Botanist',
      description: 'Identify species belonging to 5 different plant families.',
      icon: Icons.menu_book_rounded,
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  final List<Achievement> _achievements = List.from(_defaultAchievements);

  @override
  Future<List<Achievement>> getAchievements(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_achievements);
  }

  @override
  Future<List<Achievement>> checkAndAwardAchievements(
    String userId, {
    int? discoveryCount,
    int? distinctFamilyCount,
    int? completedMissionsCount,
    int? gardenLevel,
  }) async {
    final newlyUnlocked = <Achievement>[];

    for (int i = 0; i < _achievements.length; i++) {
      final ach = _achievements[i];
      if (ach.isUnlocked) continue;

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
        final unlocked = ach.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        _achievements[i] = unlocked;
        newlyUnlocked.add(unlocked);
      }
    }

    return newlyUnlocked;
  }

  @override
  Future<Achievement?> unlockAchievement(String userId, String achievementId) async {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index >= 0 && !_achievements[index].isUnlocked) {
      final unlocked = _achievements[index].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      _achievements[index] = unlocked;
      return unlocked;
    }
    return null;
  }
}

/// Supabase backed implementation of [AchievementService].
class SupabaseAchievementService implements AchievementService {
  final SupabaseService _supabaseService;
  final DemoAchievementService _demoFallback = DemoAchievementService();

  SupabaseAchievementService(this._supabaseService);

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
