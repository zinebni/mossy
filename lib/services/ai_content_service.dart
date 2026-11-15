import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../shared/models/ai_content.dart';

/// Abstract interface for generating AI educational content and nature insights.
abstract class AiContentService {
  Future<AiContent> generateContent(
    String scientificName,
    String commonName,
    String family,
    String language,
  );
}

// ============================================================================
// REAL GEMINI API IMPLEMENTATION
// ============================================================================

/// Production implementation that calls Google Gemini API (REST) directly.
/// Requires a valid [apiKey] from https://aistudio.google.com
class GeminiAiContentService implements AiContentService {
  final String apiKey;

  static const String _model = 'gemini-2.0-flash';
  static const Duration _timeout = Duration(seconds: 30);

  GeminiAiContentService(this.apiKey);

  String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey';

  @override
  Future<AiContent> generateContent(
    String scientificName,
    String commonName,
    String family,
    String language,
  ) async {
    if (apiKey.isEmpty) {
      debugPrint('[Gemini] No API key — falling back to demo service.');
      return await DemoAiContentService()
          .generateContent(scientificName, commonName, family, language);
    }

    final langNote = language == 'fr'
        ? 'Respond entirely in French.'
        : 'Respond in English.';

    final prompt = '''
You are an enthusiastic botanical educator writing for a nature discovery app called Mossy.
$langNote

For the plant "$commonName" (scientific name: $scientificName, family: $family), provide structured botanical wisdom.

Return ONLY valid JSON (no markdown, no code blocks, no extra text) with this exact structure:
{
  "introduction": "A warm, engaging 2-sentence introduction to this plant",
  "description": "A detailed botanical description in 3-4 sentences covering morphology, habitat, and ecology",
  "funFacts": [
    "First fascinating fact about this plant",
    "Second fascinating fact",
    "Third fascinating fact"
  ],
  "observationTips": [
    "First practical field observation tip for naturalists",
    "Second observation tip"
  ],
  "safetyNote": "Brief safety note: is it toxic, edible, or safe to handle?"
}
''';

    try {
      debugPrint('[Gemini] Requesting content for $scientificName...');

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 1024,
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(_timeout);

      debugPrint('[Gemini] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseResponse(response.body, scientificName, commonName, family);
      } else {
        debugPrint('[Gemini] API error ${response.statusCode}: ${response.body}');
        // On API error, fall back to demo service
        return await DemoAiContentService()
            .generateContent(scientificName, commonName, family, language);
      }
    } on Exception catch (e) {
      debugPrint('[Gemini] Exception during content generation: $e');
      return await DemoAiContentService()
          .generateContent(scientificName, commonName, family, language);
    }
  }

  AiContent _parseResponse(
    String body,
    String scientificName,
    String commonName,
    String family,
  ) {
    try {
      final responseJson = jsonDecode(body) as Map<String, dynamic>;

      // Navigate Gemini response structure
      final candidates =
          responseJson['candidates'] as List<dynamic>? ?? [];
      if (candidates.isEmpty) {
        throw Exception('No candidates in Gemini response');
      }

      final content =
          candidates.first['content'] as Map<String, dynamic>? ?? {};
      final parts = content['parts'] as List<dynamic>? ?? [];
      if (parts.isEmpty) {
        throw Exception('No parts in Gemini content');
      }

      final rawText = parts.first['text'] as String? ?? '';
      debugPrint('[Gemini] Raw text length: ${rawText.length} chars');

      // Try direct JSON parse first (when responseMimeType worked)
      Map<String, dynamic> plantJson;
      try {
        plantJson = jsonDecode(rawText) as Map<String, dynamic>;
      } catch (_) {
        // Strip possible markdown code fences and retry
        final cleaned = rawText
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
        plantJson = jsonDecode(cleaned) as Map<String, dynamic>;
      }

      return AiContent(
        introduction: plantJson['introduction'] as String? ?? '',
        description: plantJson['description'] as String? ?? '',
        funFacts: _parseStringList(plantJson['funFacts']),
        observationTips: _parseStringList(plantJson['observationTips']),
        safetyNote: plantJson['safetyNote'] as String?,
      );
    } catch (e) {
      debugPrint('[Gemini] Failed to parse response: $e — using structured fallback');
      return _buildFallback(scientificName, commonName, family);
    }
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  AiContent _buildFallback(
    String scientificName,
    String commonName,
    String family,
  ) {
    return AiContent(
      introduction:
          '$commonName ($scientificName) is a remarkable member of the $family family, '
          'celebrated for its unique adaptations and ecological role in natural habitats.',
      description:
          '$scientificName exhibits structural characteristics typical of $family. '
          'It thrives where conditions suit its evolutionary heritage, contributing to '
          'local biodiversity and supporting a web of dependent organisms.',
      funFacts: [
        'Members of the $family family have diversified over millions of years into thousands of species worldwide.',
        '$commonName plays a valuable role in its ecosystem by providing resources for local wildlife.',
        'Botanists study $scientificName to better understand plant evolution and adaptation strategies.',
      ],
      observationTips: [
        'Examine the leaf arrangement (alternate, opposite, or whorled) along the stem for identification clues.',
        'Look at petal count and symmetry — these are key diagnostic features in $family.',
      ],
      safetyNote:
          'Always wash hands after handling unfamiliar plants and never consume wild flora without verified expert guidance.',
    );
  }
}

// ============================================================================
// DEMO FALLBACK IMPLEMENTATION (used when no API key is present)
// ============================================================================

/// Offline demo implementation with curated botanical knowledge for common plants.
/// Used as a fallback when no Gemini API key is configured.
class DemoAiContentService implements AiContentService {
  static final Map<String, AiContent> _curatedKnowledge = {
    'bellis perennis': const AiContent(
      introduction:
          'The cheerful Common Daisy is one of the most recognizable European wildflowers, opening its petals with the morning sun.',
      description:
          'Bellis perennis is a low-growing perennial herbaceous plant featuring spoon-shaped leaves arranged in a flat basal rosette. Its composite flower heads have bright white ray florets surrounding a vibrant yellow central disc of tubular florets.',
      funFacts: [
        'The name "Daisy" originates from the Old English "daeges eage", meaning "day\'s eye", because its petals open at dawn and close at dusk.',
        'Daisy leaves and petals are rich in Vitamin C and have traditionally been used in wild herbal salads.',
        'Each daisy blossom is not actually a single flower, but a composite head of over a hundred tiny flowers working together.',
      ],
      observationTips: [
        'Watch how the flower head tracks the sun as it moves across the sky (heliotropism).',
        'Look closely at the yellow center with a magnifying glass to spot tiny individual disc florets blooming from the outside inward.',
      ],
      safetyNote:
          'Generally non-toxic, but people with Asteraceae allergies should avoid contact or consumption.',
    ),
    'taraxacum officinale': const AiContent(
      introduction:
          'Often dismissed as a common lawn weed, the Dandelion is actually an extraordinary nutritional powerhouse and essential early food source for pollinators.',
      description:
          'A taprooted perennial herb belonging to the sunflower family. It features deeply toothed leaves forming a basal rosette and hollow, milky stems bearing brilliant yellow composite heads that transform into spherical seed clocks (pappus).',
      funFacts: [
        'The name comes from the French "dent-de-lion" (lion\'s tooth), referring to the serrated edges of its leaves.',
        'Every single part of the dandelion—from taproot to golden blossom—is edible and packed with vitamins A, C, and K.',
        'Dandelion seeds can travel more than 5 miles on gentle summer breezes thanks to their parachute-like pappus structures.',
      ],
      observationTips: [
        'Notice how morning flowers close tightly before rainfall to protect their pollen.',
        'Examine a seed head in gentle wind to see how aerodynamic the pappus fibers are.',
      ],
      safetyNote:
          'The milky latex sap can occasionally cause mild skin irritation in sensitive individuals.',
    ),
    'rosa canina': const AiContent(
      introduction:
          'The Wild Dog Rose is an ancient climbing hedgerow shrub that adorns countryside lanes with fragrant pastel pink and white blooms.',
      description:
          'A deciduous shrub growing up to 3 meters tall, armed with sharp curved thorns that help it climb through hedgerows. It bears pinnate leaves with 5–7 toothed leaflets, fragrant single flowers, and glossy scarlet oval hips in autumn.',
      funFacts: [
        'During World War II, British school children gathered tons of wild rose hips to make vitamin C syrup when citrus fruits were unavailable.',
        'Pliny the Elder recorded that the plant was named Dog Rose because a Roman soldier cured himself of rabies using its root.',
        'Rose hips contain up to 20 times more vitamin C by weight than oranges.',
      ],
      observationTips: [
        'Notice the hooked curved thorns, which act like natural climbing grappling hooks.',
        'In late autumn, check the bright red rose hips for feeding winter birds like blackbirds and thrushes.',
      ],
      safetyNote:
          'Hairs inside the rose hips can be irritant to the digestive tract if not removed before culinary use.',
    ),
    'lavandula angustifolia': const AiContent(
      introduction:
          'English Lavender is renowned worldwide for its soothing aromatic oils, silver-green foliage, and fragrant violet floral spires.',
      description:
          'A compact, strongly aromatic evergreen subshrub native to Mediterranean rocky hillsides. It features narrow, linear leaves covered in fine hairs and terminal spikes of deep purple to lilac two-lipped flowers rich in nectar.',
      funFacts: [
        'Lavender essential oil has been used since ancient Roman times for bathing, cooking, and as a natural moth repellent.',
        'Bees are strongly attracted to lavender — a single healthy bush can produce enough nectar to fill a large honey jar.',
        'The word "lavender" derives from the Latin "lavare" (to wash), since Romans scented their baths with its flowers.',
      ],
      observationTips: [
        'Count the number of flower whorls on a single spike — lavender typically has 6–10 stacked rings.',
        'Rub a leaf gently between your fingers to release the essential oils and appreciate the characteristic camphor-like fragrance.',
      ],
      safetyNote:
          'Generally safe — lavender oil is widely used in aromatherapy, though undiluted essential oil can irritate sensitive skin.',
    ),
    'trifolium repens': const AiContent(
      introduction:
          'White Clover is a beloved low-growing groundcover that enriches the soil by fixing atmospheric nitrogen into plant-accessible nutrients.',
      description:
          'A perennial herbaceous plant with creeping runners (stolons) that root at node joints. Its trifoliate leaves feature distinctive faint white crescent marks ("watermarks"), accompanied by spherical heads of sweet-smelling white or pale pink florets.',
      funFacts: [
        'White Clover has a symbiotic relationship with Rhizobium soil bacteria that turn atmospheric nitrogen into natural organic fertilizer.',
        'The odds of finding a genuine four-leaf clover mutation in nature are approximately 1 in 10,000.',
        'It is one of the most important honey plants in the world, producing exceptionally clear, delicate honey.',
      ],
      observationTips: [
        'Look closely at the leaflets for the white V-shaped watermark.',
        'Check the base of the clover patch in early morning to see how leaves fold upward at night (nyctinastic movements).',
      ],
      safetyNote:
          'Safe for humans in small amounts, but raw foliage should not be eaten in large quantities due to trace glycosides.',
    ),
    'hedera helix': const AiContent(
      introduction:
          'Common Ivy is an evergreen climbing vine that transforms bare walls and tree trunks into verdant tapestries throughout the year.',
      description:
          'A vigorous woody perennial that climbs using adhesive aerial rootlets. It produces two distinct leaf forms: deeply lobed juvenile leaves on climbing shoots and unlobed, oval adult leaves on flowering branches near the top.',
      funFacts: [
        'Ivy berries are a critical winter food source for birds such as wood pigeons, blackbirds, and thrushes when other food is scarce.',
        'The plant has been a symbol of fidelity and eternal life since ancient Greece, where athletes were crowned with ivy wreaths.',
        'Ivy can grow over 30 meters high and live for more than 400 years when established on a suitable support structure.',
      ],
      observationTips: [
        'Compare the lobed leaves low on the wall with the smooth, oval leaves near the flowering top.',
        'Check for small black winter berries that provide high-fat sustenance to birds during freezing months.',
      ],
      safetyNote:
          'Ivy berries and leaves contain falcarinol and saponins which are toxic to humans and pets if ingested.',
    ),
  };

  @override
  Future<AiContent> generateContent(
    String scientificName,
    String commonName,
    String family,
    String language,
  ) async {
    // Simulate brief AI generation latency
    await Future.delayed(const Duration(milliseconds: 900));

    final key = scientificName.trim().toLowerCase();
    if (_curatedKnowledge.containsKey(key)) {
      return _curatedKnowledge[key]!;
    }

    // Dynamic fallback for species not in the curated set
    return AiContent(
      introduction:
          '$commonName ($scientificName) is a fascinating member of the $family botanical family, '
          'celebrated for its unique ecological adaptations.',
      description:
          '$scientificName exhibits structural characteristics typical of $family. '
          'It thrives in temperate environments where its foliage captures sunlight efficiently '
          'and supports local pollinators.',
      funFacts: [
        'Members of the $family family have developed specialized survival strategies over millions of years of evolution.',
        '$commonName plays a key role in its native habitat by contributing to biodiversity and soil health.',
        'Botanists use microscopic flower structures in $family to classify new related varieties.',
      ],
      observationTips: [
        'Observe the leaf arrangement (alternate vs. opposite) along the stem.',
        'Look closely at petal symmetry and the color of pollen on the anthers.',
      ],
      safetyNote:
          'Always wash your hands after handling unfamiliar plants and never consume wild flora without verified expert guidance.',
    );
  }
}
