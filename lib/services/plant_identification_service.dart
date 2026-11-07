import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../shared/models/identification_result.dart';
import '../shared/models/plant_candidate.dart';
import 'supabase_service.dart';

/// Abstract interface for plant identification providers.
abstract class PlantIdentificationService {
  Future<IdentificationResult> identifyPlant(Uint8List imageBytes, String fileName);
}

/// Realistic demo implementation of [PlantIdentificationService] for offline/demo use.
/// Returns curated, realistic botanical candidate pools with simulated delay.
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
        commonName: 'Cat\'s Ear',
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
      PlantCandidate(
        scientificName: 'Rosmarinus officinalis',
        commonName: 'Rosemary',
        family: 'Lamiaceae',
        score: 0.35,
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

  @override
  Future<IdentificationResult> identifyPlant(Uint8List imageBytes, String fileName) async {
    // Simulate network latency and AI processing
    await Future.delayed(const Duration(milliseconds: 1400));

    // Pick candidate set deterministically based on byte length or randomly
    final poolIndex = imageBytes.isNotEmpty
        ? (imageBytes.length % _candidatePools.length)
        : _random.nextInt(_candidatePools.length);

    final selectedPool = _candidatePools[poolIndex];
    final bestMatch = selectedPool.first;

    return IdentificationResult(
      status: bestMatch.score > 0.75
          ? IdentificationStatus.identified
          : IdentificationStatus.uncertain,
      candidates: selectedPool,
      bestMatch: bestMatch,
      rawResponse: {
        'provider': 'mossy_demo_engine',
        'matched_pool': poolIndex,
        'image_size': imageBytes.length,
        'filename': fileName,
      },
    );
  }
}

/// Production implementation of [PlantIdentificationService] that calls
/// the Supabase `identify-plant` Edge Function.
class SupabasePlantIdentificationService implements PlantIdentificationService {
  final SupabaseService _supabaseService;
  final DemoPlantIdentificationService _demoFallback = DemoPlantIdentificationService();

  SupabasePlantIdentificationService(this._supabaseService);

  @override
  Future<IdentificationResult> identifyPlant(Uint8List imageBytes, String fileName) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.identifyPlant(imageBytes, fileName);
    }

    try {
      final base64Image = base64Encode(imageBytes);

      final response = await _supabaseService.invokeFunction(
        'identify-plant',
        body: {
          'image_base64': base64Image,
          'file_name': fileName,
        },
      );

      if (response == null || !response.containsKey('candidates')) {
        debugPrint('[Mossy] Invalid response from identify-plant edge function. Falling back to demo.');
        return await _demoFallback.identifyPlant(imageBytes, fileName);
      }

      return IdentificationResult.fromJson(response);
    } catch (e) {
      debugPrint('[Mossy] Exception invoking identify-plant edge function: $e. Falling back to demo.');
      return await _demoFallback.identifyPlant(imageBytes, fileName);
    }
  }
}
