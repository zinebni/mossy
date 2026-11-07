import 'ai_content.dart';

/// Represents a saved plant discovery in the user's collection.
class Discovery {
  final String id;
  final String userId;
  final String commonName;
  final String scientificName;
  final String family;
  final String imagePath; // URL or local path
  final DateTime discoveredAt;
  final bool isFavorite;
  final double? latitude;
  final double? longitude;
  final String? personalNotes;
  final AiContent? aiContent;
  final double identificationScore; // 0.0 - 1.0
  final DateTime createdAt;

  // Convenience aliases for compatibility
  String get imageUrl => imagePath;
  String? get notes => personalNotes;
  double get confidence => identificationScore;

  const Discovery({
    required this.id,
    required this.userId,
    required this.commonName,
    required this.scientificName,
    required this.family,
    required this.imagePath,
    required this.discoveredAt,
    required this.createdAt,
    this.isFavorite = false,
    this.latitude,
    this.longitude,
    this.personalNotes,
    this.aiContent,
    this.identificationScore = 0.95,
  });

  bool get hasLocation => latitude != null && longitude != null;

  String get confidenceLabel {
    if (identificationScore >= 0.7) return 'Very Likely';
    if (identificationScore >= 0.4) return 'Likely';
    if (identificationScore >= 0.2) return 'Possible';
    return 'Uncertain';
  }

  List<String> get funFacts => aiContent?.funFacts ?? const [];
  List<String> get observationTips => aiContent?.observationTips ?? const [];
  String? get safetyNote => aiContent?.safetyNote;

  Discovery copyWith({
    String? id,
    String? userId,
    String? commonName,
    String? scientificName,
    String? family,
    String? imagePath,
    DateTime? discoveredAt,
    bool? isFavorite,
    double? latitude,
    double? longitude,
    String? personalNotes,
    AiContent? aiContent,
    double? identificationScore,
    DateTime? createdAt,
  }) {
    return Discovery(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      commonName: commonName ?? this.commonName,
      scientificName: scientificName ?? this.scientificName,
      family: family ?? this.family,
      imagePath: imagePath ?? this.imagePath,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      personalNotes: personalNotes ?? this.personalNotes,
      aiContent: aiContent ?? this.aiContent,
      identificationScore: identificationScore ?? this.identificationScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Discovery.fromJson(Map<String, dynamic> json) {
    return Discovery(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      commonName: json['common_name'] as String? ?? '',
      scientificName: json['scientific_name'] as String,
      family: json['family'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      discoveredAt: DateTime.parse(json['discovered_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      isFavorite: json['is_favorite'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      personalNotes: json['personal_notes'] as String?,
      aiContent: json['ai_content'] != null
          ? AiContent.fromJson(json['ai_content'] as Map<String, dynamic>)
          : null,
      identificationScore: (json['identification_score'] as num?)?.toDouble() ?? 0.95,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'common_name': commonName,
        'scientific_name': scientificName,
        'family': family,
        'image_path': imagePath,
        'discovered_at': discoveredAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'is_favorite': isFavorite,
        'latitude': latitude,
        'longitude': longitude,
        'personal_notes': personalNotes,
        'ai_content': aiContent?.toJson(),
        'identification_score': identificationScore,
      };
}
