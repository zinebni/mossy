import 'package:flutter/foundation.dart';
import '../shared/models/ai_content.dart';
import 'supabase_service.dart';

/// Abstract interface for generating AI educational content and nature insights.
abstract class AiContentService {
  Future<AiContent> generateContent(
    String scientificName,
    String commonName,
    String family,
    String language,
  );
}

/// Realistic demo implementation with curated botanical knowledge for common plants.
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
        'The Romans used lavender to scent their public baths, giving rise to its botanical name from the Latin "lavare", meaning "to wash".',
        'Linalool, the primary terpene in lavender essential oil, has been clinically shown to reduce anxiety and promote restful sleep.',
        'Queen Victoria was a passionate lover of lavender and appointed an official royal lavender supplier.',
      ],
      observationTips: [
        'Gently rub a leaf between your thumb and forefinger to release the fragrant essential oils stored in microscopic glands.',
        'Watch for native bumblebees, honeybees, and butterflies that visit the purple flower spikes throughout warm sunny afternoons.',
      ],
      safetyNote:
          'Essential oils are very concentrated and should not be ingested directly without professional guidance.',
    ),
    'hedera helix': const AiContent(
      introduction:
          'Common Ivy is a magnificent evergreen climber that plays a vital ecological role in supporting forest biodiversity throughout winter.',
      description:
          'An evergreen woody vine that climbs using adventitious aerial rootlets. It possesses two distinct leaf types: juvenile palmately 3–5 lobed leaves on climbing stems, and mature unlobed diamond-shaped leaves on flowering branches.',
      funFacts: [
        'Ivy flowers very late in autumn (September–November), providing a crucial final nectar source for bees and hoverflies before hibernation.',
        'Contrary to common myth, English Ivy does not choke or feed on healthy tree sap; its rootlets merely grip the bark surface for support.',
        'In ancient Greece, ivy was sacred to Dionysus, the god of nature and celebration.',
      ],
      observationTips: [
        'Compare the lobed leaves low on the wall with the smooth, oval leaves near the flowering top.',
        'Check for small black winter berries that provide high-fat sustenance to birds during freezing months.',
      ],
      safetyNote:
          'Ivy berries and leaves contain falcarinol and saponins which are toxic to humans and pets if ingested.',
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

    // Dynamic high-quality fallback for other species
    return AiContent(
      introduction:
          '$commonName ($scientificName) is a fascinating member of the $family botanical family, celebrated for its unique ecological adaptations.',
      description:
          '$scientificName exhibits structural characteristics typical of $family. It thrives in temperate environments where its foliage captures sunlight efficiently and supports local pollinators.',
      funFacts: [
        'Members of the $family family have developed specialized survival strategies over millions of years of evolution.',
        '$commonName plays a key role in its native habitat by contributing to biodiversity and soil health.',
        'Botanists use microscopic flower structures in $family to classify new related varieties.',
      ],
      observationTips: [
        'Observe the leaf arrangement (alternate vs. opposite) along the stem.',
        'Look closely at petal symmetry and the color of pollen on the anthers.',
        'Check the underside of leaves for protective trichomes (plant hairs).',
      ],
      safetyNote:
          'Always wash your hands after handling unfamiliar plants and never consume wild flora without verified expert guidance.',
    );
  }
}

/// Production implementation of [AiContentService] calling
/// the Supabase `generate-discovery-content` Edge Function.
class SupabaseAiContentService implements AiContentService {
  final SupabaseService _supabaseService;
  final DemoAiContentService _demoFallback = DemoAiContentService();

  SupabaseAiContentService(this._supabaseService);

  @override
  Future<AiContent> generateContent(
    String scientificName,
    String commonName,
    String family,
    String language,
  ) async {
    if (_supabaseService.isDemoMode || !_supabaseService.isInitialized) {
      return await _demoFallback.generateContent(
          scientificName, commonName, family, language);
    }

    try {
      final response = await _supabaseService.invokeFunction(
        'generate-discovery-content',
        body: {
          'scientific_name': scientificName,
          'common_name': commonName,
          'family': family,
          'language': language,
        },
      );

      if (response != null &&
          (response.containsKey('introduction') ||
              response.containsKey('description'))) {
        return AiContent.fromJson(response);
      }

      return await _demoFallback.generateContent(
          scientificName, commonName, family, language);
    } catch (e) {
      debugPrint(
          '[Mossy] Failed to call generate-discovery-content: $e. Using fallback.');
      return await _demoFallback.generateContent(
          scientificName, commonName, family, language);
    }
  }
}
