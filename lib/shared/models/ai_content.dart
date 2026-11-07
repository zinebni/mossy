class AiContent {
  final String introduction;
  final String description;
  final List<String> funFacts;
  final List<String> observationTips;
  final String? safetyNote;

  const AiContent({
    required this.introduction,
    required this.description,
    this.funFacts = const [],
    this.observationTips = const [],
    this.safetyNote,
  });

  factory AiContent.fromJson(Map<String, dynamic> json) {
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'introduction': introduction,
      'description': description,
      'fun_facts': funFacts,
      'observation_tips': observationTips,
      'safety_note': safetyNote,
    };
  }

  AiContent copyWith({
    String? introduction,
    String? description,
    List<String>? funFacts,
    List<String>? observationTips,
    String? safetyNote,
  }) {
    return AiContent(
      introduction: introduction ?? this.introduction,
      description: description ?? this.description,
      funFacts: funFacts ?? this.funFacts,
      observationTips: observationTips ?? this.observationTips,
      safetyNote: safetyNote ?? this.safetyNote,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiContent &&
          runtimeType == other.runtimeType &&
          introduction == other.introduction &&
          description == other.description &&
          safetyNote == other.safetyNote;

  @override
  int get hashCode =>
      introduction.hashCode ^ description.hashCode ^ safetyNote.hashCode;

  @override
  String toString() =>
      'AiContent(introduction: $introduction, funFactsCount: ${funFacts.length})';
}
