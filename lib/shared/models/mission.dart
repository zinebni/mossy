enum MissionCategory {
  daily,
  general,
  special;

  static MissionCategory fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'daily': return MissionCategory.daily;
      case 'special': return MissionCategory.special;
      default: return MissionCategory.general;
    }
  }
}

enum MissionDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case MissionDifficulty.easy: return 'Easy';
      case MissionDifficulty.medium: return 'Medium';
      case MissionDifficulty.hard: return 'Hard';
    }
  }

  static MissionDifficulty fromString(String? s) {
    switch (s?.toLowerCase()) {
      case 'hard': return MissionDifficulty.hard;
      case 'medium': return MissionDifficulty.medium;
      default: return MissionDifficulty.easy;
    }
  }
}

class Mission {
  final String id;
  final String title;
  final String description;
  final MissionCategory category;
  final MissionDifficulty difficulty;
  final int rewardPoints;
  final Map<String, dynamic> verificationCriteria;
  final bool isActive;

  const Mission({
    required this.id,
    required this.title,
    required this.description,
    this.category = MissionCategory.general,
    required this.difficulty,
    this.rewardPoints = 10,
    this.verificationCriteria = const {},
    this.isActive = true,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: MissionCategory.fromString(json['category'] as String?),
      difficulty: MissionDifficulty.fromString(json['difficulty'] as String?),
      rewardPoints: json['reward_points'] as int? ?? json['rewardPoints'] as int? ?? 10,
      verificationCriteria: (json['verification_criteria'] as Map<String, dynamic>?) ?? {},
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'difficulty': difficulty.name,
        'reward_points': rewardPoints,
        'verification_criteria': verificationCriteria,
        'is_active': isActive,
      };
}
