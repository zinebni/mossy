import 'plant_candidate.dart';

enum IdentificationStatus {
  identified,
  uncertain,
  failed;

  static IdentificationStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'identified':
        return IdentificationStatus.identified;
      case 'uncertain':
        return IdentificationStatus.uncertain;
      case 'failed':
      default:
        return IdentificationStatus.failed;
    }
  }

  String get value => name;
}

class IdentificationResult {
  final IdentificationStatus status;
  final List<PlantCandidate> candidates;
  final PlantCandidate? bestMatch;
  final Map<String, dynamic>? rawResponse;

  const IdentificationResult({
    required this.status,
    this.candidates = const [],
    this.bestMatch,
    this.rawResponse,
  });

  bool get isIdentified => status == IdentificationStatus.identified;
  bool get isUncertain => status == IdentificationStatus.uncertain;
  bool get isFailed => status == IdentificationStatus.failed;
  bool get hasCandidates => candidates.isNotEmpty;

  factory IdentificationResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final candidatesList = (json['candidates'] as List<dynamic>?)
            ?.map((e) => PlantCandidate.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    PlantCandidate? best;
    if (json['best_match'] != null) {
      best = PlantCandidate.fromJson(json['best_match'] as Map<String, dynamic>);
    } else if (json['bestMatch'] != null) {
      best = PlantCandidate.fromJson(json['bestMatch'] as Map<String, dynamic>);
    } else if (candidatesList.isNotEmpty) {
      best = candidatesList.first;
    }

    return IdentificationResult(
      status: IdentificationStatus.fromString(statusStr),
      candidates: candidatesList,
      bestMatch: best,
      rawResponse: json['raw_response'] as Map<String, dynamic>? ??
          json['rawResponse'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      'candidates': candidates.map((e) => e.toJson()).toList(),
      if (bestMatch != null) 'best_match': bestMatch!.toJson(),
      if (rawResponse != null) 'raw_response': rawResponse,
    };
  }

  IdentificationResult copyWith({
    IdentificationStatus? status,
    List<PlantCandidate>? candidates,
    PlantCandidate? bestMatch,
    Map<String, dynamic>? rawResponse,
  }) {
    return IdentificationResult(
      status: status ?? this.status,
      candidates: candidates ?? this.candidates,
      bestMatch: bestMatch ?? this.bestMatch,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdentificationResult &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          bestMatch == other.bestMatch;

  @override
  int get hashCode => status.hashCode ^ bestMatch.hashCode;

  @override
  String toString() =>
      'IdentificationResult(status: ${status.value}, bestMatch: ${bestMatch?.commonName}, candidates: ${candidates.length})';
}
