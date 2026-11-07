import 'mission.dart';

enum UserMissionStatus {
  available,
  inProgress,
  completed,
  failed;

  static UserMissionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'inprogress':
      case 'in_progress':
        return UserMissionStatus.inProgress;
      case 'completed':
        return UserMissionStatus.completed;
      case 'failed':
        return UserMissionStatus.failed;
      case 'available':
      default:
        return UserMissionStatus.available;
    }
  }

  String get value {
    switch (this) {
      case UserMissionStatus.inProgress:
        return 'in_progress';
      case UserMissionStatus.available:
        return 'available';
      case UserMissionStatus.completed:
        return 'completed';
      case UserMissionStatus.failed:
        return 'failed';
    }
  }
}

class UserMission {
  final String id;
  final String userId;
  final String missionId;
  final Mission? mission;
  final UserMissionStatus status;
  final Map<String, dynamic>? verificationResult;
  final DateTime? completedAt;

  const UserMission({
    required this.id,
    required this.userId,
    required this.missionId,
    this.mission,
    this.status = UserMissionStatus.available,
    this.verificationResult,
    this.completedAt,
  });

  bool get isCompleted => status == UserMissionStatus.completed;
  bool get isInProgress => status == UserMissionStatus.inProgress;
  bool get isAvailable => status == UserMissionStatus.available;
  bool get isFailed => status == UserMissionStatus.failed;

  factory UserMission.fromJson(Map<String, dynamic> json) {
    Mission? embeddedMission;
    if (json['mission'] != null && json['mission'] is Map<String, dynamic>) {
      embeddedMission = Mission.fromJson(json['mission'] as Map<String, dynamic>);
    }

    return UserMission(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? json['userId'] ?? '') as String,
      missionId: (json['mission_id'] ?? json['missionId'] ?? '') as String,
      mission: embeddedMission,
      status: UserMissionStatus.fromString(json['status'] as String?),
      verificationResult: (json['verification_result'] as Map<String, dynamic>?) ??
          (json['verificationResult'] as Map<String, dynamic>?),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'].toString())
          : (json['completedAt'] != null
              ? DateTime.parse(json['completedAt'].toString())
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mission_id': missionId,
      if (mission != null) 'mission': mission!.toJson(),
      'status': status.value,
      'verification_result': verificationResult,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  UserMission copyWith({
    String? id,
    String? userId,
    String? missionId,
    Mission? mission,
    UserMissionStatus? status,
    Map<String, dynamic>? verificationResult,
    DateTime? completedAt,
  }) {
    return UserMission(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      missionId: missionId ?? this.missionId,
      mission: mission ?? this.mission,
      status: status ?? this.status,
      verificationResult: verificationResult ?? this.verificationResult,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserMission && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserMission(id: $id, missionId: $missionId, status: ${status.value})';
}
