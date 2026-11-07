/// Represents the state of a user's virtual garden.
class GardenState {
  static const int minLevel = 1;
  static const int maxLevel = 10;

  /// Points thresholds required to reach each garden level (index = level - 1).
  static const List<int> _levelThresholds = [
    0, 50, 150, 300, 500, 750, 1050, 1400, 1800, 2250,
  ];

  /// Returns the cumulative point threshold required to unlock [level].
  static int pointsForLevel(int level) {
    final idx = (level - 1).clamp(0, _levelThresholds.length - 1);
    return _levelThresholds[idx];
  }

  final String userId;
  final int gardenLevel; // 1 to 10
  final List<String> unlockedItems;
  final DateTime updatedAt;

  GardenState({
    required this.userId,
    this.gardenLevel = 1,
    this.unlockedItems = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get stageName {
    switch (gardenLevel) {
      case 1: return 'Empty Plot';
      case 2: return 'Moss Patch';
      case 3: return 'First Sprouts';
      case 4: return 'Flower Garden';
      case 5: return 'Wild Meadow';
      case 6: return 'Woodland Edge';
      case 7: return 'Growing Forest';
      case 8: return 'Nature Sanctuary';
      case 9: return 'Lush Paradise';
      case 10: return 'Botanical Wonderland';
      default: return 'Garden';
    }
  }

  double get progressToNextLevel {
    if (gardenLevel >= 10) return 1.0;
    return 0.4; // Will be calculated properly by the service from points
  }

  GardenState copyWith({
    String? userId,
    int? gardenLevel,
    List<String>? unlockedItems,
    DateTime? updatedAt,
  }) {
    return GardenState(
      userId: userId ?? this.userId,
      gardenLevel: gardenLevel ?? this.gardenLevel,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GardenState.fromJson(Map<String, dynamic> json) {
    final items = (json['unlocked_items'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? <String>[];
    return GardenState(
      userId: json['user_id'] as String,
      gardenLevel: json['garden_level'] as int? ?? 1,
      unlockedItems: items,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'garden_level': gardenLevel,
        'unlocked_items': unlockedItems,
        'updated_at': updatedAt.toIso8601String(),
      };
}
