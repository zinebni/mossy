class PlantCandidate {
  final String scientificName;
  final String commonName;
  final String family;
  final double score;
  final String? imageUrl;

  const PlantCandidate({
    required this.scientificName,
    required this.commonName,
    required this.family,
    required this.score,
    this.imageUrl,
  });

  factory PlantCandidate.fromJson(Map<String, dynamic> json) {
    return PlantCandidate(
      scientificName: json['scientific_name'] as String? ??
          json['scientificName'] as String? ??
          '',
      commonName: json['common_name'] as String? ??
          json['commonName'] as String? ??
          '',
      family: json['family'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scientific_name': scientificName,
      'common_name': commonName,
      'family': family,
      'score': score,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  PlantCandidate copyWith({
    String? scientificName,
    String? commonName,
    String? family,
    double? score,
    String? imageUrl,
  }) {
    return PlantCandidate(
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      family: family ?? this.family,
      score: score ?? this.score,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlantCandidate &&
          runtimeType == other.runtimeType &&
          scientificName == other.scientificName &&
          commonName == other.commonName &&
          family == other.family &&
          score == other.score &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode =>
      scientificName.hashCode ^
      commonName.hashCode ^
      family.hashCode ^
      score.hashCode ^
      imageUrl.hashCode;

  @override
  String toString() =>
      'PlantCandidate($scientificName, $commonName, score: ${(score * 100).toStringAsFixed(1)}%)';
}
