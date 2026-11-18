import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../shared/models/identification_result.dart';
import '../shared/models/plant_candidate.dart';

/// Abstract interface for plant identification providers.
abstract class PlantIdentificationService {
  Future<IdentificationResult> identifyPlant(
    Uint8List imageBytes,
    String fileName, {
    String language = 'en',
  });
}

// ============================================================================
// REAL PLANTNET API IMPLEMENTATION
// ============================================================================

/// Production implementation that calls the Pl@ntNet REST API directly.
/// Requires a valid [apiKey] from https://my-api.plantnet.org
class PlantNetIdentificationService implements PlantIdentificationService {
  final String apiKey;

  static const String _baseUrl = 'https://my-api.plantnet.org/v2/identify/all';
  static const int _maxCandidates = 5;
  static const Duration _timeout = Duration(seconds: 30);

  PlantNetIdentificationService(this.apiKey);

  @override
  Future<IdentificationResult> identifyPlant(
    Uint8List imageBytes,
    String fileName, {
    String language = 'en',
  }) async {
    if (apiKey.isEmpty) {
      debugPrint('[PlantNet] No API key — falling back to demo service.');
      return await DemoPlantIdentificationService().identifyPlant(
        imageBytes,
        fileName,
        language: language,
      );
    }

    try {
      final langCode = language.startsWith('fr') ? 'fr' : 'en';
      final uri = Uri.parse('$_baseUrl?api-key=$apiKey&nb-results=$_maxCandidates&lang=$langCode');

      final request = http.MultipartRequest('POST', uri);

      // Determine MIME type from file extension
      final ext = fileName.split('.').last.toLowerCase();
      final mimeType = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          imageBytes,
          filename: fileName,
        ),
      );
      request.fields['organs'] = 'auto';

      debugPrint('[PlantNet] Sending ${imageBytes.length} bytes ($mimeType) to PlantNet API...');

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('[PlantNet] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseSuccessResponse(response.body);
      } else if (response.statusCode == 404) {
        // 404 from PlantNet means no match found
        return IdentificationResult(
          status: IdentificationStatus.notFound,
          candidates: const [],
          bestMatch: null,
          rawResponse: {'error': 'no_match', 'status': 404},
        );
      } else {
        debugPrint('[PlantNet] API error ${response.statusCode}: ${response.body}');
        return IdentificationResult(
          status: IdentificationStatus.error,
          candidates: const [],
          bestMatch: null,
          rawResponse: {
            'error': 'api_error',
            'status': response.statusCode,
            'body': response.body,
          },
        );
      }
    } on Exception catch (e) {
      debugPrint('[PlantNet] Exception during identification: $e');
      return IdentificationResult(
        status: IdentificationStatus.error,
        candidates: const [],
        bestMatch: null,
        rawResponse: {'error': e.toString()},
      );
    }
  }

  IdentificationResult _parseSuccessResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final resultsRaw = json['results'] as List<dynamic>? ?? [];

      final candidates = resultsRaw.map((raw) {
        final r = raw as Map<String, dynamic>;
        final species = r['species'] as Map<String, dynamic>? ?? {};
        final family = species['family'] as Map<String, dynamic>? ?? {};
        final commonNames = species['commonNames'] as List<dynamic>? ?? [];

        final scientificName =
            species['scientificNameWithoutAuthor'] as String? ??
                species['scientificName'] as String? ??
                'Unknown';
        final commonName = commonNames.isNotEmpty
            ? commonNames.first.toString()
            : scientificName;
        final familyName =
            family['scientificNameWithoutAuthor'] as String? ?? '';
        final score = (r['score'] as num?)?.toDouble() ?? 0.0;

        // Extract image URL from PlantNet result if available
        final images = r['images'] as List<dynamic>? ?? [];
        String? imageUrl;
        if (images.isNotEmpty) {
          final firstImage = images.first as Map<String, dynamic>? ?? {};
          final url2m = firstImage['url'] as Map<String, dynamic>? ?? {};
          imageUrl = url2m['m'] as String? ?? url2m['o'] as String?;
        }

        return PlantCandidate(
          scientificName: scientificName,
          commonName: commonName,
          family: familyName,
          score: score,
          imageUrl: imageUrl,
        );
      }).toList();

      // Sort by score descending (should already be sorted by API)
      candidates.sort((a, b) => b.score.compareTo(a.score));

      if (candidates.isEmpty) {
        return IdentificationResult(
          status: IdentificationStatus.notFound,
          candidates: const [],
          bestMatch: null,
          rawResponse: jsonDecode(body) as Map<String, dynamic>,
        );
      }

      final best = candidates.first;
      final status = best.score >= 0.75
          ? IdentificationStatus.identified
          : best.score >= 0.3
              ? IdentificationStatus.uncertain
              : IdentificationStatus.notFound;

      return IdentificationResult(
        status: status,
        candidates: candidates,
        bestMatch: best,
        rawResponse: jsonDecode(body) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('[PlantNet] Failed to parse response: $e');
      return IdentificationResult(
        status: IdentificationStatus.error,
        candidates: const [],
        bestMatch: null,
        rawResponse: {'parse_error': e.toString()},
      );
    }
  }
}

// ============================================================================
// DEMO FALLBACK IMPLEMENTATION (used when no API key is present)
// ============================================================================

/// Offline demo implementation with curated botanical candidate pools.
/// Used as a fallback when no Pl@ntNet API key is configured.
class DemoPlantIdentificationService implements PlantIdentificationService {
  final Random _random = Random();

  static const List<List<PlantCandidate>> _candidatePools = [
    [
      PlantCandidate(
        scientificName: 'Bellis perennis',
        commonName: 'Common Daisy',
        family: 'Asteraceae',
        score: 0.94,
        imageUrl: 'https://images.unsplash.com/photo-1560717789-0ac7c58ac90a?auto=format&fit=crop&w=800&q=80',
      ),
      PlantCandidate(
        scientificName: 'Leucanthemum vulgare',
        commonName: 'Oxeye Daisy',
        family: 'Asteraceae',
        score: 0.73,
        imageUrl: 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&w=800&q=80',
      ),
      PlantCandidate(
        scientificName: 'Tripleurospermum inodorum',
        commonName: 'Scentless Chamomile',
        family: 'Asteraceae',
        score: 0.49,
      ),
      PlantCandidate(
        scientificName: 'Erigeron annuus',
        commonName: 'Daisy Fleabane',
        family: 'Asteraceae',
        score: 0.32,
      ),
    ],
    [
      PlantCandidate(
        scientificName: 'Taraxacum officinale',
        commonName: 'Common Dandelion',
        family: 'Asteraceae',
        score: 0.91,
        imageUrl: 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?auto=format&fit=crop&w=800&q=80',
      ),
      PlantCandidate(
        scientificName: 'Sonchus oleraceus',
        commonName: 'Common Sowthistle',
        family: 'Asteraceae',
        score: 0.67,
      ),
      PlantCandidate(
        scientificName: 'Hieracium pilosella',
        commonName: 'Mouse-ear Hawkweed',
        family: 'Asteraceae',
        score: 0.44,
      ),
      PlantCandidate(
        scientificName: 'Hypochaeris radicata',
        commonName: "Cat's Ear",
        family: 'Asteraceae',
        score: 0.28,
      ),
    ],
    [
      PlantCandidate(
        scientificName: 'Rosa canina',
        commonName: 'Dog Rose',
        family: 'Rosaceae',
        score: 0.89,
        imageUrl: 'https://images.unsplash.com/photo-1559563458-527698bf5295?auto=format&fit=crop&w=800&q=80',
      ),
      PlantCandidate(
        scientificName: 'Rosa rubiginosa',
        commonName: 'Sweet Briar',
        family: 'Rosaceae',
        score: 0.65,
      ),
      PlantCandidate(
        scientificName: 'Rubus fruticosus',
        commonName: 'Wild Blackberry',
        family: 'Rosaceae',
        score: 0.42,
      ),
    ],
    [
      PlantCandidate(
        scientificName: 'Lavandula angustifolia',
        commonName: 'English Lavender',
        family: 'Lamiaceae',
        score: 0.96,
        imageUrl: 'https://images.unsplash.com/photo-1528183429752-a97d0bf99b5a?auto=format&fit=crop&w=800&q=80',
      ),
      PlantCandidate(
        scientificName: 'Lavandula stoechas',
        commonName: 'French Lavender',
        family: 'Lamiaceae',
        score: 0.71,
      ),
      PlantCandidate(
        scientificName: 'Salvia officinalis',
        commonName: 'Common Sage',
        family: 'Lamiaceae',
        score: 0.48,
      ),
    ],
    [
      PlantCandidate(
        scientificName: 'Trifolium repens',
        commonName: 'White Clover',
        family: 'Fabaceae',
        score: 0.93,
        imageUrl: 'https://images.unsplash.com/photo-1589307004396-1c20163359d9?auto=format&fit=crop&w=800&q=80',
      ),
      PlantCandidate(
        scientificName: 'Trifolium pratense',
        commonName: 'Red Clover',
        family: 'Fabaceae',
        score: 0.68,
      ),
      PlantCandidate(
        scientificName: 'Medicago lupulina',
        commonName: 'Black Medick',
        family: 'Fabaceae',
        score: 0.43,
      ),
    ],
    [
      PlantCandidate(
        scientificName: 'Hedera helix',
        commonName: 'Common Ivy',
        family: 'Araliaceae',
        score: 0.90,
        imageUrl: 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?auto=format&fit=crop&w=800&q=80',
      ),
      PlantCandidate(
        scientificName: 'Hedera hibernica',
        commonName: 'Atlantic Ivy',
        family: 'Araliaceae',
        score: 0.72,
      ),
      PlantCandidate(
        scientificName: 'Parthenocissus tricuspidata',
        commonName: 'Boston Ivy',
        family: 'Vitaceae',
        score: 0.38,
      ),
    ],
  ];

  static const Map<String, String> _frenchCommonNames = {
    'bellis perennis': 'Pâquerette',
    'leucanthemum vulgare': 'Marguerite commune',
    'tripleurospermum inodorum': 'Camomille inodore',
    'erigeron annuus': 'Vergerette annuelle',
    'taraxacum officinale': 'Pissenlit commun',
    'sonchus oleraceus': 'Laiteron maraîcher',
    'hieracium pilosella': 'Piloselle',
    'hypochaeris radicata': 'Porcelle enracinée',
    'rosa canina': 'Églantier commun',
    'rosa rubiginosa': 'Églantier odorant',
    'rubus fruticosus': 'Ronce commune',
    'lavandula angustifolia': 'Lavande vraie',
    'lavandula stoechas': 'Lavande papillon',
    'salvia officinalis': 'Sauge officinale',
    'trifolium repens': 'Trèfle blanc',
    'trifolium pratense': 'Trèfle des prés',
    'medicago lupulina': 'Minette',
    'hedera helix': 'Lierre grimpant',
    'hedera hibernica': 'Lierre d\'Irlande',
    'parthenocissus tricuspidata': 'Vigne vierge',
  };

  @override
  Future<IdentificationResult> identifyPlant(
    Uint8List imageBytes,
    String fileName, {
    String language = 'en',
  }) async {
    await Future.delayed(const Duration(milliseconds: 1400));

    final poolIndex = imageBytes.isNotEmpty
        ? (imageBytes.length % _candidatePools.length)
        : _random.nextInt(_candidatePools.length);

    final selectedPool = _candidatePools[poolIndex];
    final isFrench = language.startsWith('fr');

    final localizedCandidates = selectedPool.map((c) {
      final frenchName = isFrench ? _frenchCommonNames[c.scientificName.toLowerCase()] : null;
      return PlantCandidate(
        scientificName: c.scientificName,
        commonName: frenchName ?? c.commonName,
        family: c.family,
        score: c.score,
        imageUrl: c.imageUrl,
      );
    }).toList();

    final bestMatch = localizedCandidates.first;

    return IdentificationResult(
      status: bestMatch.score > 0.75
          ? IdentificationStatus.identified
          : IdentificationStatus.uncertain,
      candidates: localizedCandidates,
      bestMatch: bestMatch,
      rawResponse: {
        'provider': 'mossy_demo_engine',
        'matched_pool': poolIndex,
        'image_size': imageBytes.length,
        'filename': fileName,
        'language': language,
      },
    );
  }
}
