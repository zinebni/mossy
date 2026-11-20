import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../shared/models/ai_content.dart';
import '../shared/models/discovery_rarity.dart';

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
        ? 'RÈGLE IMPÉRATIVE DE LANGUE : Tu DOIS rédiger TOUTE ta réponse en FRANÇAIS, avec un ton chaleureux, ludique et accessible pour les enfants et les débutants. Explique les termes botaniques en langage courant dès qu\'ils apparaissent. Sois enthousiaste et fais ressentir la magie de la nature !'
        : 'MANDATORY LANGUAGE RULE: You MUST write your ENTIRE response in English. Use a warm, fun, friendly tone — like an enthusiastic nature guide talking to curious kids and beginners. If you use a botanical term, explain it in simple everyday words right away.';

    final prompt = '''
You are Mossy, a super friendly and enthusiastic nature guide for the Mossy plant discovery app.
Your job is to make plant discovery feel magical, fun, and exciting — like a nature adventure — for kids, families, and everyday explorers.
$langNote

Write about the plant "$commonName" (scientific name: $scientificName, family: $family).

TONE RULES (follow these strictly):
- Write like a kind, fun teacher talking to a curious 10-year-old, NOT like a science textbook.
- Use simple, vivid words. If you must use a scientific term, explain it right away in plain language.
- Be enthusiastic! Use gentle exclamations and imagery. Keep sentences short and punchy.
- Always frame edible/DIY ideas safely (e.g., "ask a grown-up first!"). No medical claims.

Return ONLY valid JSON (no markdown, no code blocks, no extra text) with this EXACT structure:
{
  "introduction": "2 sentences: What is the coolest, most exciting thing about this plant? Hook the reader! Lead with wonder.",
  "description": "2-3 sentences: Where does it live in the world? What does it look like? What does it do for nature (feed bees, make fruit, smell amazing)? Keep it visual and vivid.",
  "funFacts": [
    "A surprising delight kids would love — pollinators, records, folklore, or quirky behaviour",
    "A fun real-life use — tea, decoration, natural scent, herbal tradition — always framed safely (ask a grown-up!)",
    "A wow nature fact: seed travel, age, speed of growth, or an amazing animal relationship"
  ],
  "observationTips": [
    "Something a kid can actually DO outside: smell it, count petals, spot bugs on it, compare leaf shapes — concrete and hands-on",
    "A second fun tip: how to find it in a garden or park, or a simple nature activity to try with it"
  ],
  "safetyNote": "1-2 friendly sentences. Is it safe to touch? Should you check with a grown-up before picking or tasting? Keep it warm and not scary.",
  "rarity": "EXACTLY one lowercase English word from: common, uncommon, rare, epic, legendary (keep this value in English even when writing in French)",
  "rarityReason": "ONE short, kid-friendly sentence explaining why it has that rarity (where you can find it and how often). Written in the response language."
}

RARITY GUIDE (be honest and conservative - most plants are common or uncommon):
- common: seen almost every day on a walk, in lawns, gardens or parks.
- uncommon: fairly widespread but not in every garden or park; a nice find.
- rare: lives in specific habitats or regions; you have to go looking for it.
- epic: scarce, protected, or only grows in special places; a very special find.
- legendary: extremely rare, endangered, or almost never seen in the wild (use very sparingly, well under 2% of plants).
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
                'maxOutputTokens': 1500,
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

      final reasonRaw = plantJson['rarityReason'] ?? plantJson['rarity_reason'];
      final reason = reasonRaw is String ? reasonRaw.trim() : '';
      // Tolerant parse: bad casing/text -> null, handled by the caller's safe fallback.
      final rarity = DiscoveryRarity.tryParse(plantJson['rarity']);
      if (rarity == null) {
        debugPrint('[Gemini] Missing/invalid rarity "${plantJson['rarity']}" - caller will use safe fallback.');
      }

      return AiContent(
        introduction: plantJson['introduction'] as String? ?? '',
        description: plantJson['description'] as String? ?? '',
        funFacts: _parseStringList(plantJson['funFacts']),
        observationTips: _parseStringList(plantJson['observationTips']),
        safetyNote: plantJson['safetyNote'] as String?,
        rarity: rarity,
        rarityReason: rarity != null && reason.isNotEmpty ? reason : null,
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
          'Say hello to $commonName — one of nature\'s coolest members of the $family family! '
          'This plant has been living on Earth way longer than any of us, and it\'s full of amazing secrets waiting to be discovered.',
      description:
          'You can find $commonName (its science name is $scientificName) growing in gardens, parks, and wild places around the world. '
          'It belongs to the $family family — a big group of plants that all share special features. '
          'Like all plants, it makes its own food using sunlight — a superpower called photosynthesis!',
      funFacts: [
        'The $family family is one of the most widespread plant families on Earth, with thousands of species on every continent!',
        '$commonName is loved by pollinators like bees and butterflies who visit it for nectar and pollen — tiny meals that keep our whole food web alive.',
        'Plants like $scientificName have been living on this planet for millions of years — they were here long before humans existed!',
      ],
      observationTips: [
        'Get up close and count the petals — most plants in the $family family have a special petal pattern. How many can you find?',
        'Look very carefully at the leaves: are they smooth or fuzzy? Do they grow opposite each other or one by one? Being a nature detective is all about noticing the small stuff!',
      ],
      safetyNote:
          '🧤 Explorer safety tip: Always wash your hands after touching plants outside, and never taste a wild plant unless a knowledgeable grown-up says it\'s safe. When in doubt, just admire — don\'t nibble!',
    );
  }
}


// ============================================================================
// DEMO FALLBACK IMPLEMENTATION (used when no API key is present)
// ============================================================================

/// Offline demo implementation with curated fun botanical knowledge for common plants.
/// Tone: warm, playful, kid-friendly — not academic.
/// Used as a fallback when no Gemini API key is configured.
class DemoAiContentService implements AiContentService {
  static final Map<String, AiContent> _curatedKnowledge = {
    'bellis perennis': AiContent(
      introduction:
          'Meet the Common Daisy — one of the cheeriest little flowers you\'ll ever find peeking up from a lawn! 🌼 '
          'It opens its sunny petals with the morning light and closes them like a sleepy eye at dusk.',
      description:
          'You can spot daisies in grassy meadows, garden lawns, and parks all across Europe and beyond. '
          'Up close, what looks like one flower is actually over 100 tiny flowers all packed together — the yellow centre is a crowd of mini blooms, and each white "petal" is its own little flower too! '
          'Bees and hoverflies absolutely love visiting them for a quick snack of nectar.',
      funFacts: const [
        'The name "Daisy" comes from the Old English "daeges eage", meaning "day\'s eye" — because it opens at dawn and closes at night, just like an eye blinking! 👁️',
        'Did you know daisy petals and young leaves are edible? People added them to salads for centuries — but always ask a grown-up before tasting anything wild!',
        'Each daisy is not one flower — it\'s a community of over 100 tiny flowers all working together as a team. Nature is wild! 🤯',
      ],
      observationTips: const [
        'Try watching the same daisy at different times of day — does it open wide in the sun and close at night? That\'s called "sleeping" and it\'s totally real! 😴',
        'Grab a magnifying glass and zoom into the yellow centre — you\'ll see hundreds of tiny tube-shaped flowers. Count how many you can spot!',
      ],
      safetyNote:
          '✅ Daisies are generally safe to touch. If you\'re curious about nibbling a petal, check with a grown-up first — especially if you have allergies, since daisies are related to ragweed.',
    ),
    'taraxacum officinale': AiContent(
      introduction:
          'The Dandelion might look like a pesky weed to some, but it\'s actually one of nature\'s most incredible superplants! 🦁 '
          'From its lion-tooth leaves to its magical puffball seeds, this plant is packed with surprises.',
      description:
          'Dandelions pop up in lawns, meadows, roadsides, and even cracks in pavements all around the world — they\'re tough survivors! '
          'That white fluffy ball you love to blow? Each tiny strand is a seed attached to its own parachute, ready to drift on the breeze to find a new home. '
          'Bees especially love dandelions in early spring when other flowers haven\'t bloomed yet — they\'re like a first breakfast for hungry bees! 🐝',
      funFacts: const [
        'The name comes from French "dent-de-lion", meaning "lion\'s tooth" — look at those spiky leaf edges and you\'ll totally see it! 🦷',
        'Every single part of a dandelion is edible — flowers can be made into syrup, leaves go in salads, and roots can be roasted into a coffee-like drink. Try it with a grown-up!',
        'A dandelion seed can travel more than 5 kilometres on a gentle breeze, thanks to its clever parachute design — engineers actually study it to design better drones! 🚁',
      ],
      observationTips: const [
        'Find a dandelion puffball and blow gently — count how many puffs it takes to clear all the seeds! Folklore says the number tells you what hour it is. ⏰',
        'Look for dandelions in early morning and watch the flowers close before rain — they\'re like little weather forecasters! Does yours close before the clouds come?',
      ],
      safetyNote:
          '🌿 Dandelions are safe to touch and even eat — but the milky white sap from the stem can irritate sensitive skin. Always wash your hands after handling, and check with a grown-up before tasting wild plants!',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Dandelions pop up everywhere from meadows to cracks in the sidewalk!',
    ),
    'rosa canina': AiContent(
      introduction:
          'The Wild Dog Rose is like a fairy-tale shrub — adorned with delicate pink blossoms and bright red berries called rose hips! 🌹 '
          'It\'s been growing in hedgerows and wild places for thousands of years, and birds absolutely adore it.',
      description:
          'You\'ll find Dog Roses scrambling through hedgerows, woodland edges, and roadsides across Europe, using their hooked thorns like natural grappling hooks to climb. '
          'In early summer the soft pink flowers smell gorgeous and attract lots of bees and butterflies. '
          'By autumn, they transform into shiny red rose hips — little fruits packed with more vitamin C than oranges! 🍊',
      funFacts: const [
        'Rose hips contain up to 20 times more vitamin C than oranges! During WWII, British children collected them to make vitamin C syrup when oranges were too hard to find.',
        'Rose hip syrup is delicious — you can make it with a grown-up by simmering hips with water and sugar. Just remove the tickly hairs inside first!',
        'The plant\'s name "Dog Rose" is ancient — the Roman writer Pliny said a soldier cured a dog bite using its root. Whether true or not, it\'s a great story! 🐕',
      ],
      observationTips: const [
        'Look closely at the thorns — they\'re curved like fish hooks, not straight like pins. Run a finger VERY carefully along the stem (without pressing!) to feel the shape. So clever!',
        'In autumn, count the red hips on one branch and look for birds like robins and thrushes pecking at them. How many birds can you spot in 5 minutes? 🐦',
      ],
      safetyNote:
          '⚠️ Rose hips are great for wildlife but be careful — the tiny hairs inside the fruit are super itchy! Always cook or strain them with a grown-up\'s help. Never eat anything unprocessed from the wild without checking first.',
      rarity: DiscoveryRarity.uncommon,
      rarityReason: 'Often found rambling along country hedgerows and woodland edges.',
    ),
    'lavandula angustifolia': AiContent(
      introduction:
          'Lavender is basically nature\'s calmness in plant form — one sniff of those purple spikes and you instantly feel more relaxed! 💜 '
          'It\'s been a favourite of bees, perfumers, and herbalists for thousands of years.',
      description:
          'Originally from rocky Mediterranean hillsides, lavender now grows in gardens all over the world thanks to its incredible scent and beautiful purple flowers. '
          'Bees go absolutely crazy for it — a single lavender bush can feed hundreds of bees on a sunny summer day. '
          'The tiny leaves are covered in microscopic hairs that hold all those magical aromatic oils.',
      funFacts: const [
        'The word "lavender" comes from Latin "lavare" meaning "to wash" — ancient Romans added it to their bathwater for a lovely smell. 🛁 You can still buy lavender bath products today!',
        'You can make a simple lavender sachet to put in your wardrobe — dried flowers in a small cloth pouch keep clothes smelling fresh AND keep moths away. Nature\'s own air freshener!',
        'Lavender fields in full bloom can host tens of thousands of bees on a sunny day — the humming is so loud you can hear it from metres away! 🐝',
      ],
      observationTips: const [
        'Rub a single lavender leaf gently between your fingers and then smell your hand — that\'s the essential oil releasing! Do you think it smells calm? Like flowers? Like herbs?',
        'Count the little flower rings stacked up along one spike — you should find between 6 and 10 whorls. Each tiny flower has its own little bee landing pad! 🌸',
      ],
      safetyNote:
          '✅ Lavender is very safe to touch and smell — even kids and pets are fine around it. If you want to use lavender oil from a bottle, ask a grown-up to dilute it first, as pure essential oils can irritate skin.',
      rarity: DiscoveryRarity.rare,
      rarityReason: 'Needs plenty of hot sun and well-drained soil, making wild lavender a special find!',
    ),
    'trifolium repens': AiContent(
      introduction:
          'White Clover is a tiny lawn superhero — it secretly makes the soil healthier just by growing! 🍀 '
          'And if you find a four-leaf clover, congratulations: you just beat 1-in-10,000 odds!',
      description:
          'You\'ll find White Clover creeping through lawns, meadows, and roadsides almost everywhere in the world. '
          'It has an incredible superpower: it works with tiny soil bacteria called Rhizobium (think of them as a friendly underground team!) to pull nitrogen out of the air and turn it into natural fertiliser. '
          'Its sweet white flowers are one of the most important sources of nectar for honeybees in the whole world.',
      funFacts: const [
        'Clover is a natural soil-booster — farmers plant it on purpose to feed the earth without chemicals. It\'s basically nature\'s own fertiliser factory! 🌿',
        'White clover honey is light, sweet, and delicate — one of the most popular kinds of honey in the world, all thanks to this small but mighty plant!',
        'Your chances of randomly finding a four-leaf clover are about 1 in 10,000 — but patient searchers have found patches with many! The world record is 166 found in one hour. 🍀',
      ],
      observationTips: const [
        'Lie down in the grass and look through a clover patch slowly — search for a four-leaf mutation! Each leaflet has a little white crescent mark like a smile. 😊',
        'Visit a clover patch in the morning and watch how the leaves fold upward at night to sleep — this is called "leaf sleep" and it\'s totally real! Come back at dusk to see it happen.',
      ],
      safetyNote:
          '✅ White clover is safe to touch and even nibble a flower or two for fun! Just don\'t eat large amounts of raw leaves. Always wash your hands after rolling in the grass — and enjoy the hunt!',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Super common in green grass everywhere, but 4-leaf clovers are legendary!',
    ),
    'hedera helix': AiContent(
      introduction:
          'Common Ivy is nature\'s ultimate climber — it can scale walls, trees, and fences using its own tiny sticky pads, no nails or rope needed! 🧗 '
          'And despite looking like it\'s taking over, it\'s actually one of the most important plants for wildlife in winter.',
      description:
          'You\'ll find Ivy carpeting forest floors, climbing old buildings, and draping over trees in parks and woodlands across Europe and beyond. '
          'It has two totally different leaf shapes on the same plant — spiky and lobed near the bottom, smooth and oval near the top where it flowers. '
          'In late autumn when almost nothing else blooms, Ivy produces tiny flowers that are a vital last feast for butterflies and bees before winter. 🦋',
      funFacts: const [
        'Ivy doesn\'t steal food from trees — it only uses them as a climbing frame to reach the light. It\'s not a parasite, just a very determined climber!',
        'The dark blue-black berries are critically important winter food for birds like wood pigeons, blackbirds, and thrushes when snow covers everything else. Birds then spread ivy seeds everywhere! 🐦',
        'A well-established ivy can live for over 400 years and climb 30 metres high — that\'s taller than a 10-storey building!',
      ],
      observationTips: const [
        'Look for two completely different leaf shapes on the SAME plant — spiky star-shaped ones low down and smooth oval ones near the top. Can you find both? It\'s like a shape scavenger hunt!',
        'In winter, look for clusters of dark berries and watch patiently for birds coming to eat them. How many different bird species can you spot visiting the same ivy plant in 10 minutes? 🐦',
      ],
      safetyNote:
          '⚠️ Important: Ivy berries and leaves are toxic to humans and pets if eaten — never taste them! It\'s safe to touch ivy (though some people\'s skin reacts), but always wash your hands well afterwards.',
      rarity: DiscoveryRarity.uncommon,
      rarityReason: 'Climbs on old stone walls and ancient trees in deep forests.',
    ),
  };

  static final Map<String, AiContent> _curatedKnowledgeFr = {
    'bellis perennis': AiContent(
      introduction:
          'La Pâquerette, c\'est la petite étoile des prairies — elle ouvre ses pétales le matin comme des yeux qui se réveillent ! 🌼 '
          'Son nom vient d\'ailleurs de la fête de Pâques, car elle fleurit joyeusement au printemps.',
      description:
          'On trouve la Pâquerette partout : dans les pelouses, les prairies et les parcs de toute l\'Europe. '
          'Ce qui ressemble à une seule fleur est en réalité plus de 100 minuscules fleurs regroupées — les "pétales" blancs sont chacun une fleur à part entière, et le cœur jaune en est plein d\'autres ! '
          'Les abeilles et les syrphes adorent y butiner pour siroter du nectar. 🐝',
      funFacts: const [
        'Son nom vient de "daeges eage" en vieil anglais, qui signifie "œil du jour" — parce qu\'elle s\'ouvre à l\'aube et se ferme la nuit ! 👁️',
        'Les pétales et jeunes feuilles de Pâquerette sont comestibles — on les glissait dans des salades depuis des siècles. Demande à un adulte avant de goûter une plante sauvage !',
        'Chaque fleur de Pâquerette, c\'est une équipe de plus de 100 toutes petites fleurs qui travaillent ensemble. La nature est incroyable ! 🤯',
      ],
      observationTips: const [
        'Observe la même Pâquerette à différentes heures de la journée — est-ce qu\'elle se ferme la nuit ? C\'est son "sommeil" et c\'est tout à fait réel ! 😴',
        'Prends une loupe et zoome sur le cœur jaune — tu verras des dizaines de petites fleurs en tube. Combien peux-tu en compter ?',
      ],
      safetyNote:
          '✅ La Pâquerette est généralement sans danger. Si tu veux goûter un pétale, demande d\'abord à un adulte — surtout si tu es allergique aux plantes de la famille des Astéracées.',
    ),
    'taraxacum officinale': AiContent(
      introduction:
          'Le Pissenlit a l\'air d\'une simple mauvaise herbe, mais c\'est en réalité l\'une des super-plantes les plus incroyables de la nature ! 🦁 '
          'De ses feuilles en dents de lion à ses graines parachutes magiques, il regorge de surprises.',
      description:
          'Les Pissenlits poussent dans les pelouses, les prairies, les bords de route et même les fissures des trottoirs — de vrais survivants ! '
          'Cette boule blanche et duvetteuse que tu adores souffler ? Chaque brin est une graine avec son propre parachute, prête à voyager au vent pour trouver un nouveau foyer. '
          'Les abeilles adorent les Pissenlits au début du printemps, quand peu d\'autres fleurs sont encore écloses — ils sont comme leur premier petit-déjeuner ! 🐝',
      funFacts: const [
        'Son nom vient de "dent de lion" — regarde les bords dentelés de ses feuilles et tu comprends tout de suite ! 🦷',
        'Toutes les parties du Pissenlit sont comestibles — les fleurs en sirop, les feuilles en salade, les racines torréfiées comme une boisson chaude. Essaie avec un adulte !',
        'Une graine de Pissenlit peut voyager à plus de 5 kilomètres sur une légère brise, grâce à son système de parachute que les ingénieurs étudient pour concevoir des drones ! 🚁',
      ],
      observationTips: const [
        'Trouve une boule de graines et souffle doucement — compte combien de souffles il faut pour tout disperser ! La légende dit que le nombre indique l\'heure. ⏰',
        'Observe les fleurs tôt le matin : est-ce qu\'elles se referment avant la pluie ? Les Pissenlits sont de vrais petits météorologues !',
      ],
      safetyNote:
          '🌿 Le Pissenlit est sans danger à toucher et même à manger — mais le suc laiteux de la tige peut irriter les peaux sensibles. Lavez-vous les mains après et demandez à un adulte avant de goûter des plantes sauvages !',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Le pissenlit pousse partout, des prés aux trottoirs !',
    ),
    'rosa canina': AiContent(
      introduction:
          'L\'Églantier, c\'est l\'arbuste de conte de fées — avec ses jolies fleurs roses et ses baies rouge vif appelées cynorrhodons ! 🌹 '
          'Il pousse dans les haies et les chemins sauvages depuis des millénaires, et les oiseaux l\'adorent.',
      description:
          'L\'Églantier grimpe dans les haies, les lisières de bois et les bords de route grâce à ses épines recourbées qui l\'accrochent comme des grappins naturels. '
          'En début d\'été, ses fleurs roses parfumées attirent de nombreuses abeilles et papillons. '
          'En automne, elles se transforment en cynorrhodons rouges brillants — des petits fruits bourrés de vitamine C, encore plus que les oranges ! 🍊',
      funFacts: const [
        'Les cynorrhodons contiennent jusqu\'à 20 fois plus de vitamine C que les oranges ! Pendant la Seconde Guerre mondiale, les enfants britanniques en collectaient pour faire du sirop.',
        'On peut faire un délicieux sirop de cynorrhodon avec un adulte — on fait mijoter les baies avec de l\'eau et du sucre. Il faut d\'abord enlever les petits poils irritants à l\'intérieur.',
        'Le nom "Églantier" vient du latin, et Pline l\'Ancien raconte qu\'un soldat romain s\'est guéri d\'une morsure de chien grâce à sa racine. Vraie ou non, c\'est une chouette histoire ! 🐕',
      ],
      observationTips: const [
        'Regarde de près les épines — elles sont recourbées comme des hameçons, pas droites comme des aiguilles. Approche ton doigt très doucement (sans appuyer !) pour sentir la forme. Malin !',
        'En automne, compte les cynorrhodons rouges sur une branche et guette les oiseaux comme les merles qui viennent les picorer. Combien en vois-tu en 5 minutes ? 🐦',
      ],
      safetyNote:
          '⚠️ Les cynorrhodons sont excellents pour les animaux, mais attention — les poils fins à l\'intérieur des baies grattent beaucoup ! Fais-les toujours cuire ou filtrer avec l\'aide d\'un adulte avant de les consommer.',
    ),
    'lavandula angustifolia': AiContent(
      introduction:
          'La Lavande, c\'est la plante du calme par excellence — une seule bouffée de ses épis violets et on se sent tout de suite apaisé ! 💜 '
          'C\'est le régal préféré des abeilles, des parfumeurs et des herboristes depuis des millénaires.',
      description:
          'Originaire des collines rocailleuses de Méditerranée, la Lavande pousse maintenant dans les jardins du monde entier grâce à son parfum incroyable et ses fleurs violettes. '
          'Les abeilles en raffolent — un seul buisson de lavande peut nourrir des centaines d\'abeilles une journée de soleil. '
          'Ses petites feuilles sont couvertes de poils microscopiques qui retiennent toutes ces huiles aromatiques magiques.',
      funFacts: const [
        'Le mot "lavande" vient du latin "lavare" qui signifie "laver" — les Romains la mettaient déjà dans leur eau de bain pour sentir bon ! 🛁',
        'Tu peux fabriquer un sachet de lavande à glisser dans ton armoire — des fleurs séchées dans un petit tissu gardent les vêtements frais ET éloignent les mites. Le désodorisant de la nature !',
        'Les champs de lavande en fleurs peuvent accueillir des dizaines de milliers d\'abeilles par beau temps — le bourdonnement est si fort qu\'on l\'entend de loin ! 🐝',
      ],
      observationTips: const [
        'Frotte doucement une feuille de lavande entre tes doigts puis sens ta main — c\'est l\'huile essentielle qui se libère ! Ça sent le calme ? Les fleurs ? Les herbes ?',
        'Compte les petits anneaux de fleurs empilés sur un épi — tu devrais en trouver entre 6 et 10. Chaque minuscule fleur a sa propre piste d\'atterrissage pour les abeilles ! 🌸',
      ],
      safetyNote:
          '✅ La lavande est très sûre à toucher et à sentir. Si tu veux utiliser de l\'huile essentielle de lavande, demande à un adulte de la diluer d\'abord.',
    ),
    'trifolium repens': AiContent(
      introduction:
          'Le Trèfle blanc est un vrai super-héros de pelouse — il rend le sol plus riche juste en poussant ! 🍀 '
          'Et si tu trouves un trèfle à quatre feuilles, félicitations : tu viens de réussir un exploit à 1 chance sur 10 000 !',
      description:
          'On trouve le Trèfle blanc rampant dans les pelouses, les prairies et les bords de chemin presque partout dans le monde. '
          'Il coopère avec de petites bactéries du sol appelées Rhizobium — une équipe amie sous la terre ! — pour transformer l\'azote de l\'air en engrais naturel. '
          'Ses jolies fleurs blanches parfumées sont l\'une des sources de nectar les plus précieuses au monde pour les abeilles mellifères.',
      funFacts: const [
        'Le Trèfle renforce naturellement la terre — les agriculteurs en plantent exprès pour nourrir le sol sans produits chimiques. Une vraie usine à engrais naturels ! 🌿',
        'Le miel de trèfle blanc est léger, doux et délicat — l\'un des miels les plus populaires du monde, tout ça grâce à cette petite plante !',
        'Tes chances de trouver un trèfle à quatre feuilles par hasard sont d\'environ 1 sur 10 000 — mais le record du monde est de 166 trouvés en une heure ! 🍀',
      ],
      observationTips: const [
        'Allonge-toi dans l\'herbe et cherche lentement dans un patch de trèfles — guette une feuille à quatre folioles ! Chaque foliole a un petit croissant blanc en forme de sourire. 😊',
        'Visite un patch de trèfle le soir et observe comment les feuilles se replient pour "dormir" — c\'est le "sommeil foliaire" et c\'est 100% réel ! Reviens à l\'aube pour les voir se rouvrir.',
      ],
      safetyNote:
          '✅ Le Trèfle blanc est sans danger à toucher et même à grignoter une petite fleur ! Évite juste de manger de grandes quantités de feuilles crues. Lave-toi les mains après — et profite de la chasse !',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Très répandu dans l''herbe, mais le trèfle à 4 feuilles est légendaire !',
    ),
    'hedera helix': AiContent(
      introduction:
          'Le Lierre, c\'est le grimpeur ultime de la nature — il escalade les murs, les arbres et les clôtures avec ses propres petites ventouses, sans clou ni corde ! 🧗 '
          'Et malgré son air envahissant, c\'est l\'une des plantes les plus précieuses pour la faune en hiver.',
      description:
          'Le Lierre tapisse les sols de forêts, habille les vieux bâtiments et drapé les arbres dans les parcs et les bois de toute l\'Europe. '
          'Il a deux formes de feuilles complètement différentes sur la même plante — étoilées et lobées en bas, lisses et ovales en haut où il fleurit. '
          'En fin d\'automne, le Lierre produit de petites fleurs qui sont un festin vital pour les papillons et les abeilles avant l\'hiver. 🦋',
      funFacts: const [
        'Le Lierre ne vole pas la nourriture des arbres — il les utilise juste comme échafaudage pour atteindre la lumière. Ce n\'est pas un parasite, juste un grimpeur très déterminé !',
        'Les baies bleu-noir sont une nourriture hivernale indispensable pour les merles, les palombes et les grives quand la neige recouvre tout. Les oiseaux dispersent ensuite les graines partout ! 🐦',
        'Un Lierre bien établi peut vivre plus de 400 ans et grimper à 30 mètres de hauteur — plus haut qu\'un immeuble de 10 étages !',
      ],
      observationTips: const [
        'Cherche deux formes de feuilles complètement différentes sur la MÊME plante — des étoilées en bas et des ovales lisses en haut. Tu peux les trouver toutes les deux ? C\'est une chasse aux formes !',
        'En hiver, guette les grappes de baies sombres et observe patiemment les oiseaux venir les manger. Combien d\'espèces d\'oiseaux différentes peux-tu repérer en 10 minutes ? 🐦',
      ],
      safetyNote:
          '⚠️ Important : les baies et les feuilles de Lierre sont toxiques pour les humains et les animaux si on les mange — ne les goûte jamais ! Toucher le Lierre est généralement sans danger, mais lave toujours bien tes mains après.',
      rarity: DiscoveryRarity.uncommon,
      rarityReason: 'Grimpe le long des vieux murs et des grands arbres en forêt.',
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

      // French dynamic fallback — fun, kid-friendly tone
      return AiContent(
        introduction:
            'Découvre $commonName — un membre fascinant de la famille des $family ! 🌿 '
            'Cette plante incroyable cache plein de secrets que les explorateurs de la nature adorent percer.',
        description:
            '$commonName (son nom scientifique est $scientificName) pousse dans des jardins, des parcs et des espaces sauvages à travers le monde. '
            'Comme toutes les plantes, elle fabrique sa propre nourriture à partir de la lumière du soleil — un super-pouvoir qu\'on appelle la photosynthèse ! '
            'Elle appartient à la grande famille des $family, un groupe de plantes qui partagent toutes des caractéristiques spéciales.',
        funFacts: [
          'La famille des $family compte des milliers d\'espèces sur tous les continents de la Terre — une vraie famille mondiale ! 🌍',
          '$commonName est adorée des pollinisateurs comme les abeilles et les papillons qui viennent y chercher du nectar et du pollen — de précieux repas qui font tourner tout l\'écosystème.',
          'Des plantes comme $scientificName vivent sur notre planète depuis des millions d\'années — elles étaient là bien avant les humains !',
        ],
        observationTips: [
          'Approche-toi et compte les pétales — est-ce qu\'il y en a 4, 5 ou plus ? C\'est un super indice pour identifier les plantes !',
          'Regarde très attentivement les feuilles : sont-elles lisses ou velues ? Poussent-elles face à face ou une par une ? Être détective de la nature, c\'est remarquer les petits détails !',
        ],
        safetyNote:
            '🧤 Conseil d\'explorateur : lave toujours tes mains après avoir touché des plantes dehors, et ne goûte jamais une plante sauvage sans qu\'un adulte compétent dise que c\'est sans danger. Dans le doute, on admire — on ne croque pas !',
        rarity: RarityEngine.assign(scientificName: scientificName, family: family),
        rarityReason: 'Observée dans son milieu naturel par les explorateurs !',
      );
    }

    if (_curatedKnowledge.containsKey(key)) {
      return _curatedKnowledge[key]!;
    }

    // English dynamic fallback — fun, kid-friendly tone
    return AiContent(
      introduction:
          'Say hello to $commonName — a fascinating member of the $family family! 🌿 '
          'This incredible plant has been living on Earth way longer than any of us, and it\'s full of amazing secrets waiting to be discovered.',
      description:
          '$commonName (its science name is $scientificName) grows in gardens, parks, and wild places around the world. '
          'Like all plants, it makes its own food using sunlight — a superpower called photosynthesis! '
          'It belongs to the $family family, a big group of plants that all share special features.',
      funFacts: [
        'The $family family has thousands of species found on every continent on Earth — a truly global plant family! 🌍',
        '$commonName is loved by pollinators like bees and butterflies who visit for nectar and pollen — tiny meals that keep our whole food web alive.',
        'Plants like $scientificName have been living on this planet for millions of years — they were here long before humans existed!',
      ],
      observationTips: [
        'Get up close and count the petals — most plants in the $family family have a special petal pattern. How many can you find?',
        'Look very carefully at the leaves: are they smooth or fuzzy? Do they grow opposite each other or one by one? Being a nature detective is all about noticing the small stuff!',
      ],
      safetyNote:
          '🧤 Explorer safety tip: Always wash your hands after touching plants outside, and never taste a wild plant unless a knowledgeable grown-up says it\'s safe. When in doubt, just admire — don\'t nibble!',
    );
  }
}

