import 'discovery_rarity.dart';

class AiContent {
  final String introduction;
  final String description;
  final List<String> funFacts;
  final List<String> observationTips;
  final String? safetyNote;

  /// Rarity tier suggested by Gemini (null when unavailable / invalid).
  final DiscoveryRarity? rarity;

  /// Short kid-friendly reason for the tier (null when unavailable).
  final String? rarityReason;

  const AiContent({
    required this.introduction,
    required this.description,
    this.funFacts = const [],
    this.observationTips = const [],
    this.safetyNote,
    this.rarity,
    this.rarityReason,
  });

  factory AiContent.fromJson(Map<String, dynamic> json) {
    final reason = (json['rarity_reason'] ?? json['rarityReason']);
    return AiContent(
      introduction: json['introduction'] as String? ?? '',
      description: json['description'] as String? ?? '',
      funFacts: (json['fun_facts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['funFacts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      observationTips: (json['observation_tips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['observationTips'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      safetyNote: json['safety_note'] as String? ?? json['safetyNote'] as String?,
      rarity: DiscoveryRarity.tryParse(json['rarity']),
      rarityReason: reason is String && reason.trim().isNotEmpty ? reason.trim() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'introduction': introduction,
      'description': description,
      'fun_facts': funFacts,
      'observation_tips': observationTips,
      'safety_note': safetyNote,
      if (rarity != null) 'rarity': rarity!.name,
      if (rarityReason != null) 'rarity_reason': rarityReason,
    };
  }

  AiContent copyWith({
    String? introduction,
    String? description,
    List<String>? funFacts,
    List<String>? observationTips,
    String? safetyNote,
    DiscoveryRarity? rarity,
    String? rarityReason,
  }) {
    return AiContent(
      introduction: introduction ?? this.introduction,
      description: description ?? this.description,
      funFacts: funFacts ?? this.funFacts,
      observationTips: observationTips ?? this.observationTips,
      safetyNote: safetyNote ?? this.safetyNote,
      rarity: rarity ?? this.rarity,
      rarityReason: rarityReason ?? this.rarityReason,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiContent &&
          runtimeType == other.runtimeType &&
          introduction == other.introduction &&
          description == other.description &&
          safetyNote == other.safetyNote &&
          rarity == other.rarity;

  @override
  int get hashCode =>
      introduction.hashCode ^ description.hashCode ^ safetyNote.hashCode ^ rarity.hashCode;

  @override
  String toString() =>
      'AiContent(introduction: $introduction, funFactsCount: ${funFacts.length}, rarity: $rarity)';
}
