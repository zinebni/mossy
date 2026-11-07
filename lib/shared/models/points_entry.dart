class PointsEntry {
  final String id;
  final String userId;
  final int points;
  final String reason;
  final String? referenceId;
  final DateTime createdAt;

  const PointsEntry({
    required this.id,
    required this.userId,
    required this.points,
    required this.reason,
    this.referenceId,
    required this.createdAt,
  });

  factory PointsEntry.fromJson(Map<String, dynamic> json) {
    return PointsEntry(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      points: (json['points'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] ?? '') as String,
      referenceId: (json['reference_id'] ?? json['referenceId']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'reason': reason,
      'reference_id': referenceId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PointsEntry copyWith({
    String? id,
    String? userId,
    int? points,
    String? reason,
    String? referenceId,
    DateTime? createdAt,
  }) {
    return PointsEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      reason: reason ?? this.reason,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointsEntry && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PointsEntry(id: $id, points: $points, reason: $reason, createdAt: $createdAt)';
}
