import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/models/discovery.dart';

// ============================================================================
// QUEST MODELS
// ============================================================================

/// Type of quest — drives reset cadence and UI bucketing.
enum QuestType { daily, seasonal }

/// What kind of botanical criteria a quest checks.
enum QuestRequirementType {
  /// Any successfully identified plant counts.
  anyPlant,

  /// Must match a specific botanical family (e.g. 'Asteraceae').
  specificFamily,

  /// Count-based: scan N different plants regardless of family.
  countBased,

  /// Scientific or common name contains one of the provided tags.
  tagMatch,
}

/// Immutable definition of a quest — no user state.
class QuestDefinition {
  final String id;
  final String titleEn;
  final String titleFr;
  final String descriptionEn;
  final String descriptionFr;
  final String emoji;
  final QuestType type;
  final QuestRequirementType requirementType;

  /// For [QuestRequirementType.specificFamily]: exact family string.
  final String? requiredFamily;

  /// For [QuestRequirementType.tagMatch]: keywords to search in name fields.
  final List<String> requiredTags;

  /// Total scans needed to complete the quest.
  final int targetCount;

  /// XP awarded on completion.
  final int xpReward;

  const QuestDefinition({
    required this.id,
    required this.titleEn,
    required this.titleFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.emoji,
    required this.type,
    required this.requirementType,
    this.requiredFamily,
    this.requiredTags = const [],
    this.targetCount = 1,
    this.xpReward = 30,
  });

  String title(bool isFr) => isFr ? titleFr : titleEn;
  String description(bool isFr) => isFr ? descriptionFr : descriptionEn;

  /// Evaluates whether a plant candidate or discovery fulfills this quest's criteria.
  bool matchesPlant({
    required String family,
    required String scientificName,
    required String commonName,
  }) {
    switch (requirementType) {
      case QuestRequirementType.anyPlant:
        return true;
      case QuestRequirementType.specificFamily:
        final f = family.toLowerCase().trim();
        // Meadow quest accepts Asteraceae or Poaceae
        if (id == 'seasonal-meadow') {
          return f == 'asteraceae' || f == 'poaceae';
        }
        return f == (requiredFamily?.toLowerCase().trim() ?? '');
      case QuestRequirementType.countBased:
        return true;
      case QuestRequirementType.tagMatch:
        final haystack = '$commonName $scientificName'.toLowerCase();
        return requiredTags.any((tag) => haystack.contains(tag.toLowerCase()));
    }
  }

  /// User-friendly label of the requirement for badges and challenge preview banners.
  String targetRequirementLabel(bool isFr) {
    switch (requirementType) {
      case QuestRequirementType.specificFamily:
        if (id == 'seasonal-meadow') {
          return isFr
              ? 'Famille : Asteraceae ou Poaceae'
              : 'Family: Asteraceae or Poaceae';
        }
        return isFr
            ? 'Famille : ${requiredFamily ?? "Spécifique"}'
            : 'Family: ${requiredFamily ?? "Specific"}';
      case QuestRequirementType.tagMatch:
        return isFr
            ? 'Mot-clé : ${requiredTags.join(", ")}'
            : 'Keywords: ${requiredTags.join(", ")}';
      case QuestRequirementType.anyPlant:
      case QuestRequirementType.countBased:
        return isFr ? 'Toute plante sauvage' : 'Any wild plant';
    }
  }
}

/// Mutable progress record for a single quest, persisted locally.
class QuestProgress {
  final String questId;
  final String userId;
  int currentCount;
  bool isCompleted;
  DateTime? completedAt;
  final DateTime startedAt;

  /// IDs of discoveries that already counted toward this quest (dedup guard).
  final Set<String> countedDiscoveryIds;

  QuestProgress({
    required this.questId,
    required this.userId,
    this.currentCount = 0,
    this.isCompleted = false,
    this.completedAt,
    DateTime? startedAt,
    Set<String>? countedDiscoveryIds,
  })  : startedAt = startedAt ?? DateTime.now(),
        countedDiscoveryIds = countedDiscoveryIds ?? {};

  Map<String, dynamic> toJson() => {
        'questId': questId,
        'userId': userId,
        'currentCount': currentCount,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'startedAt': startedAt.toIso8601String(),
        'countedDiscoveryIds': countedDiscoveryIds.toList(),
      };

  factory QuestProgress.fromJson(Map<String, dynamic> json) => QuestProgress(
        questId: json['questId'] as String,
        userId: json['userId'] as String,
        currentCount: json['currentCount'] as int? ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : DateTime.now(),
        countedDiscoveryIds:
            ((json['countedDiscoveryIds'] as List<dynamic>?) ?? [])
                .map((e) => e as String)
                .toSet(),
      );
}

/// Combined view of a quest definition + the user's current progress.
class QuestWithProgress {
  final QuestDefinition definition;
  final QuestProgress progress;

  const QuestWithProgress({required this.definition, required this.progress});

  bool get isCompleted => progress.isCompleted;
  int get currentCount => progress.currentCount;
  int get targetCount => definition.targetCount;
  double get completionFraction =>
      (currentCount / targetCount).clamp(0.0, 1.0);
}

// ============================================================================
// QUEST DEFINITIONS (clean, no user state)
// ============================================================================

/// All quest definitions for the app. Pure data — no progress seeded here.
class QuestCatalog {
  static const List<QuestDefinition> _daily = [
    // Rotation slot A — shown on days where dayOfYear % 3 == 0
    QuestDefinition(
      id: 'daily-a',
      titleEn: 'First Bloom of the Day',
      titleFr: 'Première Fleur du Jour',
      descriptionEn: 'Scan and save any 1 plant today to earn your daily XP.',
      descriptionFr: 'Scannez et enregistrez une plante aujourd\'hui.',
      emoji: '🌸',
      type: QuestType.daily,
      requirementType: QuestRequirementType.anyPlant,
      targetCount: 1,
      xpReward: 20,
    ),
    // Rotation slot B — shown on days where dayOfYear % 3 == 1
    QuestDefinition(
      id: 'daily-b',
      titleEn: 'Family Botanist',
      titleFr: 'Botaniste de Famille',
      descriptionEn: 'Discover 2 plants from the same botanical family today.',
      descriptionFr:
          'Découvrez 2 plantes de la même famille botanique aujourd\'hui.',
      emoji: '🌿',
      type: QuestType.daily,
      requirementType: QuestRequirementType.anyPlant,
      targetCount: 2,
      xpReward: 35,
    ),
    // Rotation slot C — shown on days where dayOfYear % 3 == 2
    QuestDefinition(
      id: 'daily-c',
      titleEn: 'Wild Explorer',
      titleFr: 'Explorateur Sauvage',
      descriptionEn: 'Scan 3 different plants today and embrace the wild!',
      descriptionFr: 'Scannez 3 plantes différentes aujourd\'hui !',
      emoji: '🧭',
      type: QuestType.daily,
      requirementType: QuestRequirementType.anyPlant,
      targetCount: 3,
      xpReward: 50,
    ),
  ];

  static const List<QuestDefinition> _seasonal = [
    QuestDefinition(
      id: 'seasonal-meadow',
      titleEn: 'Meadow Wanderer',
      titleFr: 'Promeneur des Prairies',
      descriptionEn:
          'Scan 10 plants from the Asteraceae or Poaceae family and roam the meadows.',
      descriptionFr:
          'Scannez 10 plantes de la famille Asteraceae ou Poaceae.',
      emoji: '🌼',
      type: QuestType.seasonal,
      requirementType: QuestRequirementType.specificFamily,
      requiredFamily: 'Asteraceae',
      targetCount: 10,
      xpReward: 150,
    ),
    QuestDefinition(
      id: 'seasonal-forest',
      titleEn: 'Forest Floor Explorer',
      titleFr: 'Explorateur du Sous-Bois',
      descriptionEn:
          'Discover any 5 plants — your adventure starts beneath the canopy.',
      descriptionFr:
          'Découvrez 5 plantes — votre aventure commence sous la canopée.',
      emoji: '🌲',
      type: QuestType.seasonal,
      requirementType: QuestRequirementType.anyPlant,
      targetCount: 5,
      xpReward: 100,
    ),
    QuestDefinition(
      id: 'seasonal-herb',
      titleEn: 'Aromatic Herb Hunt',
      titleFr: 'Chasse aux Herbes Aromatiques',
      descriptionEn:
          'Find 3 aromatic plants from the Lamiaceae (mint) family.',
      descriptionFr:
          'Trouvez 3 plantes aromatiques de la famille Lamiaceae (menthe).',
      emoji: '🌿',
      type: QuestType.seasonal,
      requirementType: QuestRequirementType.specificFamily,
      requiredFamily: 'Lamiaceae',
      targetCount: 3,
      xpReward: 90,
    ),
  ];

  /// Returns the single daily quest active for a given date (rotating cycle).
  static QuestDefinition activeDailyQuest(DateTime date) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays;
    return _daily[dayOfYear % _daily.length];
  }

  /// Returns all seasonal quests.
  static List<QuestDefinition> seasonalQuests() =>
      List.unmodifiable(_seasonal);

  /// Returns all currently active quest definitions (1 daily + all seasonal).
  static List<QuestDefinition> activeQuests() {
    final today = DateTime.now();
    return [activeDailyQuest(today), ..._seasonal];
  }

  /// Look up a definition by id.
  static QuestDefinition? byId(String id) {
    final all = [..._daily, ..._seasonal];
    try {
      return all.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ============================================================================
// LOCAL PERSISTENCE
// ============================================================================

class _LocalQuestStore {
  static const String _progressKey = 'mossy_user_quest_progress_v2';
  static const String _dailyResetKey = 'mossy_quest_daily_reset_date';

  /// Load all saved progress records for a user, keyed by questId.
  static Future<Map<String, QuestProgress>> loadAll(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_progressKey}_$userId');
      if (raw == null || raw.isEmpty) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(k, QuestProgress.fromJson(v as Map<String, dynamic>)),
      );
    } catch (e) {
      debugPrint('[Mossy] QuestStore load error: $e');
      return {};
    }
  }

  /// Persist all progress records for a user.
  static Future<void> saveAll(
      String userId, Map<String, QuestProgress> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(data.map((k, v) => MapEntry(k, v.toJson())));
      await prefs.setString('${_progressKey}_$userId', encoded);
    } catch (e) {
      debugPrint('[Mossy] QuestStore save error: $e');
    }
  }

  /// Returns the last stored daily-reset date string (yyyy-MM-dd).
  static Future<String?> getLastDailyResetDate(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('${_dailyResetKey}_$userId');
    } catch (_) {
      return null;
    }
  }

  /// Stores today's date as the last daily-reset date.
  static Future<void> saveDailyResetDate(String userId, String dateStr) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_dailyResetKey}_$userId', dateStr);
    } catch (_) {}
  }
}

// ============================================================================
// QUEST SERVICE INTERFACE + IMPLEMENTATION
// ============================================================================

abstract class QuestService {
  /// Returns all active quests merged with the user's current progress.
  Future<List<QuestWithProgress>> getActiveQuestsWithProgress(String userId);

  /// Called whenever a plant is saved. Checks all active quests, updates
  /// progress, and returns any newly-completed [QuestDefinition]s (for XP award).
  Future<List<QuestDefinition>> onDiscoverySaved(
      String userId, Discovery discovery);
}

/// Local-first implementation — all persistence via SharedPreferences.
/// Zero pre-seeded user progress; fresh accounts start with clean state.
class LocalQuestService implements QuestService {
  @override
  Future<List<QuestWithProgress>> getActiveQuestsWithProgress(
      String userId) async {
    // Reset daily quest if the calendar date has changed.
    await _maybeResetDailyQuest(userId);

    final savedProgress = await _LocalQuestStore.loadAll(userId);
    final active = QuestCatalog.activeQuests();

    return active.map((def) {
      final progress = savedProgress[def.id] ??
          QuestProgress(questId: def.id, userId: userId);
      return QuestWithProgress(definition: def, progress: progress);
    }).toList();
  }

  @override
  Future<List<QuestDefinition>> onDiscoverySaved(
      String userId, Discovery discovery) async {
    // Reset daily if needed first.
    await _maybeResetDailyQuest(userId);

    final savedProgress = await _LocalQuestStore.loadAll(userId);
    final active = QuestCatalog.activeQuests();
    final newlyCompleted = <QuestDefinition>[];

    for (final def in active) {
      final progress = savedProgress[def.id] ??
          QuestProgress(questId: def.id, userId: userId);

      // Skip already-completed quests.
      if (progress.isCompleted) continue;

      // Avoid double-counting the same discovery for this quest.
      if (progress.countedDiscoveryIds.contains(discovery.id)) continue;

      // Check if this discovery matches the quest requirement.
      if (!_matches(def, discovery)) continue;

      // It matches — increment.
      progress.currentCount += 1;
      progress.countedDiscoveryIds.add(discovery.id);

      if (progress.currentCount >= def.targetCount) {
        progress.isCompleted = true;
        progress.completedAt = DateTime.now();
        newlyCompleted.add(def);
      }

      savedProgress[def.id] = progress;
    }

    if (savedProgress.isNotEmpty) {
      await _LocalQuestStore.saveAll(userId, savedProgress);
    }

    return newlyCompleted;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  bool _matches(QuestDefinition def, Discovery discovery) {
    return def.matchesPlant(
      family: discovery.family,
      scientificName: discovery.scientificName,
      commonName: discovery.commonName,
    );
  }

  /// Clears daily quest progress when the calendar date has rolled over.
  Future<void> _maybeResetDailyQuest(String userId) async {
    final today = _todayString();
    final lastReset = await _LocalQuestStore.getLastDailyResetDate(userId);

    if (lastReset == today) return; // Already reset today.

    // Load progress and clear only the active daily quest's data.
    final saved = await _LocalQuestStore.loadAll(userId);
    final todayDef = QuestCatalog.activeDailyQuest(DateTime.now());
    // Also clear yesterday's daily slot if it differs.
    for (final key in saved.keys.toList()) {
      if (key.startsWith('daily-')) {
        saved.remove(key);
      }
    }
    await _LocalQuestStore.saveAll(userId, saved);
    await _LocalQuestStore.saveDailyResetDate(userId, today);
    debugPrint('[Mossy] Daily quest reset for $userId — slot: ${todayDef.id}');
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
