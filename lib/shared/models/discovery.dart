import 'ai_content.dart';
import 'discovery_rarity.dart';

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
  final DiscoveryRarity? _rarity;

  /// Rarity tier. Falls back to the deterministic engine for records saved
  /// before the rarity system existed (null-safe).
  /// Order: stored tier -> Gemini tier saved inside ai_content -> legacy
  /// deterministic rule. Stable for a given record across views and re-fetches.
  DiscoveryRarity get rarity =>
      _rarity ??
      aiContent?.rarity ??
      RarityEngine.assign(scientificName: scientificName, family: family);

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
    DiscoveryRarity? rarity,
  }) : _rarity = rarity;

  String get genus => scientificName.trim().split(RegExp(r'\s+')).first;

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
    DiscoveryRarity? rarity,
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
      rarity: rarity ?? _rarity,
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
      aiContent: json['ai_content'] != null &&
              json['ai_content'] is Map &&
              (json['ai_content'] as Map).isNotEmpty
          ? AiContent.fromJson(json['ai_content'] as Map<String, dynamic>)
          : null,
      identificationScore: (json['identification_score'] as num?)?.toDouble() ?? 0.95,
      rarity: DiscoveryRarity.tryParse(json['rarity']),
    );
  }

  /// [includeRarity] is false for Supabase payloads (rarity is deterministic and
  /// recomputed on read, so no remote schema change is required).
  Map<String, dynamic> toJson({bool includeRarity = true}) => {
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
        'ai_content': aiContent?.toJson() ?? {},
        'identification_score': identificationScore,
        if (includeRarity) 'rarity': rarity.name,
      };
}

