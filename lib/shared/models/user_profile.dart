/// User profile model for Mossy.
class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl;
  final int totalPoints;
  final int explorerLevel;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.totalPoints = 0,
    this.explorerLevel = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Points thresholds per level (cumulative)
  static const List<int> _levelThresholds = [
    0, 50, 150, 300, 500, 750, 1050, 1400, 1800, 2250, 2750,
  ];

  static int calculateLevel(int points) {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (points >= _levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  /// Progress 0.0–1.0 within current level band
  double get levelProgress {
    final lvl = explorerLevel;
    if (lvl >= _levelThresholds.length) return 1.0;
    final start = _levelThresholds[lvl - 1];
    final end = lvl < _levelThresholds.length ? _levelThresholds[lvl] : _levelThresholds.last + 500;
    if (end <= start) return 1.0;
    return ((totalPoints - start) / (end - start)).clamp(0.0, 1.0);
  }

  int get pointsToNextLevel {
    final lvl = explorerLevel;
    if (lvl >= _levelThresholds.length) return 0;
    final end = lvl < _levelThresholds.length ? _levelThresholds[lvl] : _levelThresholds.last + 500;
    return (end - totalPoints).clamp(0, 99999);
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? totalPoints,
    int? explorerLevel,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      explorerLevel: explorerLevel ?? this.explorerLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final pts = json['total_points'] as int? ?? 0;
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'Explorer',
      avatarUrl: json['avatar_url'] as String?,
      totalPoints: pts,
      explorerLevel: json['explorer_level'] as int? ?? calculateLevel(pts),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'avatar_url': avatarUrl,
        'total_points': totalPoints,
        'explorer_level': explorerLevel,
        'created_at': createdAt.toIso8601String(),
      };
}
