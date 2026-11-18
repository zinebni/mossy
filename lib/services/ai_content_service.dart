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

    final isFrench = language.startsWith('fr');
    final langNote = isFrench
        ? 'RÈGLE IMPÉRATIVE DE LANGUE : Tu DOIS rédiger l\'intégralité absolue de ta réponse en FRANÇAIS (France). Tous les champs textuels (introduction, description, funFacts, observationTips, safetyNote) DOIVENT impérativement être écrits en français soigné, éducatif et poétique.'
        : 'MANDATORY LANGUAGE RULE: You MUST write your entire response in English. All text fields (introduction, description, funFacts, observationTips, safetyNote) MUST be written in clear, engaging English.';

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

  static final Map<String, AiContent> _curatedKnowledgeFr = {
    'bellis perennis': const AiContent(
      introduction:
          'La joyeuse Pâquerette est l\'une des fleurs sauvages les plus emblématiques de nos prairies, ouvrant ses pétales dès l\'apparition des premiers rayons du soleil.',
      description:
          'Bellis perennis est une plante herbacée vivace formant une rosette basale de feuilles spatulées. Ses capitules floraux portent des fleurons ligulés blanc pur teintés de pourpre autour d\'un cœur éclatant de fleurons tubulaires jaunes.',
      funFacts: [
        'Son nom français "Pâquerette" vient de sa floraison abondante autour de la fête de Pâques au printemps.',
        'Ses feuilles et pétales sont riches en vitamine C et étaient traditionnellement dégustés en salades sauvages revigorantes.',
        'Chaque fleur de pâquerette n\'est pas une fleur unique, mais une inflorescence composée réunissant plus d\'une centaine de fleurs minuscules.',
      ],
      observationTips: [
        'Observez comment le capitule suit le soleil d\'est en ouest tout au long de la journée (héliotropisme).',
        'À l\'aide d\'une loupe, découvrez les minuscules fleurons du disque jaune qui s\'ouvrent progressivement de l\'extérieur vers le centre.',
      ],
      safetyNote:
          'Plante généralement inoffensive, mais les personnes allergiques aux Astéracées doivent éviter le contact direct.',
    ),
    'taraxacum officinale': const AiContent(
      introduction:
          'Souvent qualifié de simple mauvaise herbe, le Pissenlit est en réalité un trésor nutritionnel exceptionnel et une source précoce de nectar vitale pour les pollinisateurs.',
      description:
          'Une plante vivace à racine pivotante de la famille des Astéracées. Elle présente des feuilles découpées en rosette et des tiges creuses à sève laiteuse portant de superbes capitules jaunes qui se métamorphosent en globes soyeux d\'aigrettes.',
      funFacts: [
        'Son nom "Pissenlit" fait référence à ses propriétés diurétiques bien connues en phytothérapie traditionnelle.',
        'Chaque partie du pissenlit—des racines torréfiées aux fleurs dorées—est comestible et gorgée de vitamines A, C et K.',
        'Les graines peuvent voyager à plus de 8 kilomètres portées par la brise grâce à leur aigrette en parachute naturel.',
      ],
      observationTips: [
        'Remarquez comment les fleurs se referment hermétiquement avant la pluie pour protéger leur précieux pollen.',
        'Observez la structure géométrique parfaite du capitule plumeux avant la dispersion des graines par le vent.',
      ],
      safetyNote:
          'Le latex blanc qui s\'écoule de la tige peut provoquer de légères irritations cutanées chez les personnes sensibles.',
    ),
    'rosa canina': const AiContent(
      introduction:
          'L\'Églantier ou rosier sauvage est un arbuste vigoureux qui orne les haies champêtres de délicates fleurs rose pâle au parfum subtil.',
      description:
          'Un arbrisseau épineux atteignant jusqu\'à 3 mètres de hauteur, muni d\'aiguillons recourbés qui lui permettent de grimper. Il porte des feuilles pennées, de grandes fleurs à 5 pétales et de superbes baies rouge vif appelées cynorrhodons en automne.',
      funFacts: [
        'Le cynorrhodon est surnommé "gratte-cul" en raison des petits poils irritants entourant ses graines.',
        'Les baies d\'églantier contiennent jusqu\'à 20 fois plus de vitamine C que les oranges fraîches.',
        'Pline l\'Ancien rapportait que sa racine était jadis utilisée pour guérir les morsures de chiens enragés.',
      ],
      observationTips: [
        'Remarquez les aiguillons crochus agissant comme de véritables grappins d\'escalade naturelle.',
        'À la fin de l\'automne, observez les merles et grives qui viennent se nourrir des cynorrhodons mûrs.',
      ],
      safetyNote:
          'Les poils entourant les graines internes doivent impérativement être retirés avant toute préparation culinaire.',
    ),
    'lavandula angustifolia': const AiContent(
      introduction:
          'La Lavande vraie est célèbre dans le monde entier pour ses huiles essentielles apaisantes, son feuillage vert argenté et ses épis floraux bleu-violet.',
      description:
          'Un sous-arbrisseau aromatique vivace originaire des collines rocailleuses méditerranéennes. Ses feuilles étroites sont couvertes de poils fins et ses tiges portent des épis denses de fleurs bilabiées riches en nectar.',
      funFacts: [
        'Les Romains parfumaient déjà leurs thermes et leurs vêtements avec la lavande, d\'où son nom issu du latin "lavare" (laver).',
        'Un seul buisson de lavande en pleine floraison peut nourrir des centaines d\'abeilles chaque jour.',
        'L\'huile essentielle de lavande fine est reconnue pour ses vertus calmantes et purifiantes exceptionnelles.',
      ],
      observationTips: [
        'Frottez délicatement une feuille entre vos doigts pour libérer les essences aromatiques camphrées.',
        'Comptez les verticilles de fleurs le long d\'un épi : on en dénombre généralement entre 6 et 10 anneaux superposés.',
      ],
      safetyNote:
          'Plante sécuritaire, bien que l\'huile essentielle pure doive être diluée avant application cutanée chez les enfants.',
    ),
    'trifolium repens': const AiContent(
      introduction:
          'Le Trèfle blanc est un couvre-sol nourricier qui enrichit naturellement la terre en fixant l\'azote de l\'air dans le sol.',
      description:
          'Une plante herbacée vivace rampante qui s\'étend par des tiges stolonifères. Ses feuilles trifoliées arborent souvent une marque blanche caractéristique en croissant, accompagnées de têtes florales globuleuses blanches très parfumées.',
      funFacts: [
        'Le trèfle vit en symbiose avec des bactéries Rhizobium qui transforment l\'azote de l\'air en engrais naturel.',
        'La probabilité de trouver spontanément un trèfle à quatre feuilles dans la nature est d\'environ 1 sur 10 000.',
        'C\'est l\'une des plantes mellifères les plus précieuses au monde pour la production d\'un miel clair et délicat.',
      ],
      observationTips: [
        'Examinez les feuilles au crépuscule pour observer leur repliement nocturne protecteur (sommeil foliaire).',
        'Recherchez la marque en V blanc argenté présente sur chaque foliole.',
      ],
      safetyNote:
          'Comestible en petites quantités, mais évitez de consommer de grandes quantités de feuilles crues en raison de traces de glycosides.',
    ),
    'hedera helix': const AiContent(
      introduction:
          'Le Lierre grimpant est une liane persistante essentielle à la biodiversité forestière, offrant fleurs tardives et baies hivernales.',
      description:
          'Une vigoureuse liane ligneuse qui s\'accroche aux supports grâce à de petits crampons aériens non parasites. Il présente deux types de feuilles distincts : lobées sur les rameaux grimpants et ovales entières sur les rameaux fertiles.',
      funFacts: [
        'Le lierre ne suce pas la sève des arbres : il s\'en sert uniquement de tuteur pour capter la lumière du ciel.',
        'Ses fleurs automnales constituent l\'ultime festin de nectar pour les papillons et abeilles avant l\'hiver.',
        'Un pied de lierre bien établi peut vivre plus de 400 ans et grimper jusqu\'à 30 mètres de hauteur.',
      ],
      observationTips: [
        'Comparez la forme des feuilles palmées du bas avec les feuilles ovales non lobées situées au sommet ensoleillé.',
        'À la fin de l\'hiver, repérez les baies noires qui sauvent de nombreux oiseaux du gel.',
      ],
      safetyNote:
          'Toutes les parties du lierre (notamment les baies noires) sont toxiques en cas d\'ingestion pour l\'humain et les animaux de compagnie.',
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
    final isFrench = language.startsWith('fr');

    if (isFrench) {
      if (_curatedKnowledgeFr.containsKey(key)) {
        return _curatedKnowledgeFr[key]!;
      }

      // French dynamic fallback
      return AiContent(
        introduction:
            '$commonName ($scientificName) est une plante captivante de la famille des $family, réputée pour ses remarquables adaptations écologiques.',
        description:
            '$scientificName présente les traits caractéristiques de la famille botanique des $family. Elle prospère dans les milieux tempérés où son feuillage capte la lumière pour nourrir l\'écosystème local.',
        funFacts: [
          'Les espèces de la famille des $family ont développé des stratégies de survie uniques au fil de millions d\'années d\'évolution.',
          '$commonName joue un rôle essentiel dans son habitat en favorisant la pollinisation et la vitalité du sol.',
          'Les botanistes analysent la morphologie florale des $family pour répertorier de nouvelles sous-espèces.',
        ],
        observationTips: [
          'Observez l\'agencement des feuilles (alternes ou opposées) le long de la tige principale.',
          'Examinez la structure des pétales et la couleur du pollen pour affiner votre identification de terrain.',
        ],
        safetyNote:
            'Lavez-vous toujours les mains après manipulation et ne consommez jamais de végétaux sauvages sans confirmation experte.',
      );
    }

    if (_curatedKnowledge.containsKey(key)) {
      return _curatedKnowledge[key]!;
    }

    // Dynamic English fallback
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
