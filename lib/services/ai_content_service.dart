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

  // Uses gemini-3.8-flash: official current model replacing retired gemini-2.0-flash
  static const String _model = 'gemini-3.8-flash';
  static const Duration _timeout = Duration(seconds: 35);

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
        ? 'RÈGLE IMPÉRATIVE DE LANGUE : Tu DOIS rédiger TOUTE ta réponse en FRANÇAIS, avec un ton chaleureux, ludique et accessible pour des enfants de 10 ans et des explorateurs débutants. Explique les termes botaniques en mots simples dès qu\'ils apparaissent. Sois enthousiaste et fais ressentir la magie de la nature !'
        : 'MANDATORY LANGUAGE RULE: You MUST write your ENTIRE response in English. Use a warm, fun, friendly tone — like an enthusiastic nature guide talking to curious kids (around 10 years old) and everyday beginners. If you use a botanical term, explain it in simple everyday words right away.';

    final prompt = '''
You are Mossy, a super friendly and enthusiastic nature guide for the Mossy plant discovery app.
Your mission is to share real, exciting botanical wisdom with curious kids, families, and beginner explorers.
$langNote

Write about this specific plant:
- Common Name: "$commonName"
- Scientific Name: "$scientificName"
- Botanical Family: "$family"

CRITICAL RULES (FOLLOW STRICTLY - NO GENERIC BOILERPLATE):
1. ZERO GENERIC FILLER: Never say generic phrases like "makes food through photosynthesis", "grows in gardens, parks and wild places around the world", or generic "feeds bees and butterflies". Every sentence must be 100% SPECIFIC to this exact species!
2. WHERE IT LIVES: Name REAL geographical homes, native continents, specific countries, or distinct habitats where this exact plant grows (e.g., Mediterranean limestone hills, Amazon rainforest understory, damp European riverbanks, alpine rocky slopes).
3. FUN & PRACTICAL USES: Share real, concrete ways humans enjoy or use this specific plant (e.g., herbal tea infusions, calming sleep sachets, soothing aloe gel, flower pressing/crafts, culinary seasoning, natural dyes, bouquet gifting). Always frame safely (e.g., "always ask a grown-up before brewing or picking!").
4. COOL FACTS: 3 surprising, species-specific quirks, historical lore, records, or unusual adaptations unique to $scientificName.
5. HOW TO SPOT OR GROW IT: 2 hands-on, practical clues kids can look for outside (leaf texture like fuzzy vs waxy, square stems, aroma when gently touched, flowers) and simple care tips (sunlight/water).
6. SAFE EXPLORER TIP: A realistic safety note tailored specifically to $commonName (mention thorns, milky sap that can itch, bee visitors, or gentle reassurance if touch-safe).
7. RARITY: EXACTLY one lowercase English word from: common, uncommon, rare, epic, legendary.
8. RARITY REASON: ONE short, kid-friendly sentence in the target language explaining why it has this rarity in nature.

Return ONLY a valid JSON object (no markdown fences, no extra text) with this EXACT structure:
{
  "introduction": "2 punchy sentences: Hook the kid explorer! What is the single coolest or most magical superpower of this specific plant?",
  "description": "2-3 vivid sentences: Where does it live natively in the world? What does it look like, and how does it specifically interact with its environment?",
  "funFacts": [
    "Fact 1: Surprising species-specific quirk, record, or historical nickname",
    "Fact 2: Real-world practical use (tea, craft, scent, herbal tradition) with safe adult guidance",
    "Fact 3: An amazing relationship with specific insects, animals, or weather adaptations"
  ],
  "observationTips": [
    "Hands-on tip 1: Something concrete to touch, smell, count, or inspect (e.g. leaf veins, stem shape, flower petals)",
    "Hands-on tip 2: Where to spot it or practical care tip (light, soil, water)"
  ],
  "safetyNote": "1-2 friendly sentences tailored specifically to $commonName.",
  "rarity": "common",
  "rarityReason": "One kid-friendly sentence explaining this rarity."
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
                'maxOutputTokens': 1500,
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(_timeout);

      debugPrint('[Gemini] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseResponse(response.body, scientificName, commonName, family, isFrench);
      } else {
        debugPrint('[Gemini] API error ${response.statusCode}: ${response.body}');
        // On API error, fall back to rich demo service
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
    bool isFrench,
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
      // Tolerant parse: bad casing/text -> null, handled by caller's safe fallback.
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
      debugPrint('[Gemini] Failed to parse response: $e — using botanical fallback');
      return DemoAiContentService().generateBotanicalWisdomSync(
        scientificName,
        commonName,
        family,
        isFrench,
      );
    }
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return const [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}


// ============================================================================
// DEMO FALLBACK IMPLEMENTATION (used when no API key is present or offline)
// ============================================================================

/// Offline demo implementation with curated fun botanical knowledge for common plants
/// and a family-specific botanical wisdom generator.
/// Tone: warm, playful, kid-friendly — never generic textbook filler.
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
      rarity: DiscoveryRarity.common,
      rarityReason: 'Seen on lawns and grassy parks almost every sunny day!',
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
    'monstera deliciosa': AiContent(
      introduction:
          'Step into the rainforest with the Swiss Cheese Plant — famous for its giant glossy leaves with natural peek-a-boo holes! 🌿 '
          'In the jungle, it climbs sky-high into tree canopies using thick rope-like aerial roots.',
      description:
          'Native to the warm tropical rainforests of southern Mexico and Central America, Monstera scrambles up towering trees to catch rays of sunlight. '
          'Its unique leaf holes (called fenestrations) allow ferocious tropical rainstorms and winds to blow right through without tearing the leaves! '
          'In its native wild habitat, it even produces an edible fruit that tastes like a blend of sweet pineapple and banana.',
      funFacts: const [
        'The name "deliciosa" comes from its wild tropical fruit, which tastes like sweet fruit salad when fully ripe! 🍍🍌',
        'Its aerial roots act like living grappling ropes that drink raindrops and moisture straight out of misty jungle air.',
        'Young Monstera leaves start completely solid and heart-shaped — the iconic splits only form as the plant gets older and reaches for brighter light!',
      ],
      observationTips: const [
        'Inspect the leaf: are there closed holes inside the leaf, or deep cuts along the outer edge? Count how many "windows" you can find!',
        'Gently touch the thick, glossy surface — notice how water droplets bead up and slide off like a waterproof raincoat.',
      ],
      safetyNote:
          '🌿 Fun and safe to gently caress, but the leaves contain tiny calcium oxalate crystals that sting if chewed. Admire with your eyes, never nibble, and keep away from pets!',
      rarity: DiscoveryRarity.rare,
      rarityReason: 'A majestic tropical native, mostly spotted in cozy indoor jungles and botanical greenhouses!',
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
      rarity: DiscoveryRarity.common,
      rarityReason: 'Présente dans presque toutes les pelouses au premier rayon de soleil !',
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
      rarity: DiscoveryRarity.uncommon,
      rarityReason: 'Pousse le long des haies champêtres et des sentiers forestiers.',
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
      rarity: DiscoveryRarity.rare,
      rarityReason: 'Aime le plein soleil méditerranéen et les sols rocailleux bien drainés.',
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
      rarityReason: 'Très répandu dans l\'herbe, mais le trèfle à 4 feuilles est légendaire !',
    ),
    'hedera helix': AiContent(
      introduction:
          'Le Lierre, c\'est le grimpeur ultime de la nature — il escalade les murs, les arbres et les clôtures avec ses propres petites ventouses, sans clou ni corde ! 🧗 '
          'Et malgré son air envahissant, c\'est l\'une des plantes les plus précieuses pour la faune en hiver.',
      description:
          'Le Lierre tapisse les sols de forêts, habille les vieux bâtiments et drape les arbres dans les parcs et les bois de toute l\'Europe. '
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
    'monstera deliciosa': AiContent(
      introduction:
          'Bienvenue dans la jungle avec le Faux Philodendron — célèbre pour ses feuilles géantes perforées comme des fenêtres naturelles ! 🌿 '
          'Dans la forêt tropicale, il grimpe le long des arbres géants grâce à de solides racines aériennes en forme de cordes.',
      description:
          'Originaire des forêts chaudes et humides du Mexique et d\'Amérique centrale, le Monstera s\'élève vers la cime des arbres pour capter le soleil. '
          'Les fentes et trous uniques dans ses feuilles (appelés fenestrations) permettent aux pluies diluviennes et aux bourrasques de passer sans déchirer la feuille ! '
          'Dans son milieu sauvage d\'origine, il produit même un fruit savoureux au goût de salade d\'ananas et de banane.',
      funFacts: const [
        'Son nom "deliciosa" vient de son fruit tropical sauvage, délicieux comme une salade de fruits tropicaux quand il est parfaitement mûr ! 🍍🍌',
        'Ses racines aériennes fonctionnent comme des cordes d\'escalade capables d\'avaler les gouttes de pluie et la brume de la jungle.',
        'Les toutes jeunes feuilles de Monstera naissent entières et en forme de cœur — les fentes magiques n\'apparaissent qu\'en grandissant !',
      ],
      observationTips: const [
        'Inspecte la feuille : y a-t-il des trous fermés à l\'intérieur ou des découpes jusqu\'au bord ? Compte combien de "fenêtres" tu vois !',
        'Touche doucement sa surface luisante et épaisse : les gouttes d\'eau glissent dessus comme sur un ciré imperméable.',
      ],
      safetyNote:
          '🌿 Très agréable à caresser délicatement, mais ses feuilles contiennent des micro-cristaux piquants si on les croque. On admire avec les yeux, on ne goûte jamais et on tient éloigné des animaux !',
      rarity: DiscoveryRarity.rare,
      rarityReason: 'Une liane tropicale spectaculaire, reine des serres et des intérieurs chaleureux !',
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
    await Future.delayed(const Duration(milliseconds: 300));

    final key = scientificName.trim().toLowerCase();
    final isFrench = language.startsWith('fr');

    if (isFrench) {
      if (_curatedKnowledgeFr.containsKey(key)) {
        return _curatedKnowledgeFr[key]!;
      }
      return generateBotanicalWisdomSync(scientificName, commonName, family, true);
    }

    if (_curatedKnowledge.containsKey(key)) {
      return _curatedKnowledge[key]!;
    }

    return generateBotanicalWisdomSync(scientificName, commonName, family, false);
  }

  /// Synchronous fallback wisdom generator tailored to the plant's family and genus.
  /// Eliminates rigid boilerplate while preserving child-friendly wonder and accuracy.
  AiContent generateBotanicalWisdomSync(
    String scientificName,
    String commonName,
    String family,
    bool isFrench,
  ) {
    final famLower = family.trim().toLowerCase();
    final sciLower = scientificName.trim().toLowerCase();
    final name = commonName.isNotEmpty ? commonName : scientificName;
    final rarity = RarityEngine.assign(scientificName: scientificName, family: family);

    // 1. LAMIACEAE (Mint / Lavender / Sage / Rosemary / Thyme family)
    if (famLower.contains('lamiac') || famLower.contains('labiat') || sciLower.contains('mentha') || sciLower.contains('salvia')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Découvre $name — un trésor aromatique de la famille des Lamiacées ($family) aux tiges carrées magiques ! 🌿 '
              'Fais-la rouler entre tes doigts : ses tiges ont 4 angles bien nets que les explorateurs reconnaissent au premier toucher.',
          description:
              'Originaire des coteaux ensoleillés de la Méditerranée et des collines rocailleuses, cette plante stocke des huiles précieuses dans de minuscules glandes sur ses feuilles. '
              'Dès que le soleil la réchauffe, elle diffuse un parfum revigorant qui guide les bourdons et les abeilles vers ses fleurs étagées.',
          funFacts: [
            'Les tiges de la famille de la menthe sont toujours à section carrée avec quatre côtés plats — un secret botanique infaillible pour l\'identifier !',
            'Depuis l\'Antiquité, on utilise ses feuilles pour préparer des infusions bienfaisantes, parfumer les plats et glisser des sachets odorants dans le linge.',
            'Son parfum intense sert de bouclier naturel : il éloigne les insectes indésirables tout en attirant les insectes pollinisateurs amis ! 🐝',
          ],
          observationTips: [
            'Frotte très délicatement une feuille entre ton pouce et ton index, puis sens tes doigts : tu libères instantanément ses huiles aromatiques !',
            'Regarde de près l\'épi de fleurs : les petites fleurs à deux lèvres forment des couronnes empilées étage par étage.',
          ],
          safetyNote:
              '✅ Douce et sans danger à caresser ! Si tu veux préparer une tisane ou cuisiner avec ses feuilles, demande toujours l\'aide d\'un adulte.',
          rarity: rarity,
          rarityReason: 'Précieuse plante aromatique qui aime la chaleur et les sols bien drainés.',
        );
      }
      return AiContent(
        introduction:
            'Say hello to $name — an aromatic wonder from the mint family ($family) with square stems you can feel! 🌿 '
            'Roll the stem gently between your fingers: it has four distinct flat corners that nature detectives recognize instantly.',
        description:
            'Native to sunny Mediterranean hillsides and rocky slopes, this plant stores fragrant essential oils in microscopic glands across its foliage. '
            'When warmed by the afternoon sun, it fills the air with a soothing aroma that guides bees and butterflies straight to its stacked flower spikes.',
        funFacts: [
          'The square stem with four flat sides is the secret trademark of the Lamiaceae family — feel it between two fingers to test it yourself!',
          'People have treasured leaves from this family for thousands of years to brew relaxing herbal teas, season comforting meals, and make fragrant drawer sachets.',
          'The rich aroma is the plant\'s natural armor: it repels hungry garden pests while welcoming friendly pollinating bees! 🐝',
        ],
        observationTips: [
          'Gently rub a leaf between your thumb and index finger, then smell your fingertips — you\'ll release a burst of natural aromatic oils!',
          'Look closely at the flower spike: the two-lipped blossoms are arranged in neat stacked rings called whorls.',
        ],
        safetyNote:
            '✅ Very gentle and safe to touch! If you want to brew herbal tea or harvest leaves for cooking, always ask a grown-up to help.',
        rarity: rarity,
        rarityReason: 'Loves sunny spots and well-drained soil, making it a delightful fragrant find.',
      );
    }

    // 2. ASTERACEAE (Daisy / Sunflower / Dandelion / Thistle family)
    if (famLower.contains('asterac') || famLower.contains('composit')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Voici $name — un champion du travail d\'équipe de la famille des Astéracées ($family) ! 🌼 '
              'Ce que tu prends pour une seule fleur est en réalité une vraie métropole de dizaines de minuscules fleurettes réunies.',
          description:
              'S\'épanouissant dans les prairies ouvertes et les clairières baignées de lumière, cette fleur est dite "composée". '
              'Chaque faux pétale sur les bords est une fleurette à part entière, et le cœur central en regroupe des dizaines d\'autres qui s\'ouvrent progressivement pour régaler les papillons.',
          funFacts: [
            'Le cœur floral fonctionne comme une horloge solaire : ses fleurettes s\'ouvrent en spirale géométrique parfaite depuis l\'extérieur vers le centre !',
            'Beaucoup de ces fleurs suivent la course du soleil au cours de la journée pour garder leur pollen bien tiède.',
            'On adore presser ces jolies fleurs dans des vieux livres pour confectionner des marque-pages ou tresser des couronnes de fées.',
          ],
          observationTips: [
            'Prends une loupe et observe le disque central : vois-tu les dizaines de minuscules corolles en forme d\'étoiles ?',
            'Surveille la fleur au crépuscule ou quand un nuage d\'orage approche : observe si ses pétales se referment pour protéger son cœur !',
          ],
          safetyNote:
              '✅ Douce et amusante à admirer. Lave-toi toujours les mains après tes expéditions en plein air et demande un coup de main pour les bricolages nature.',
          rarity: rarity,
          rarityReason: 'Fleurit joyeusement dans les espaces herbeux et les prairies ensoleillées.',
        );
      }
      return AiContent(
        introduction:
            'Meet $name — a master of teamwork from the daisy family ($family)! 🌼 '
            'What looks like one single flower head is actually a bustling community of dozens of tiny flowers working together as a team.',
        description:
            'Thriving in sunny open meadows and grassy clearings, this plant produces composite blooms. '
            'The colorful outer "petals" are individual strap-shaped florets, while the disk in the middle holds a crowd of mini tube-shaped flowers bursting with sweet nectar for visiting bees.',
        funFacts: [
          'The center disk opens in a mesmerizing mathematical spiral (the Fibonacci sequence!) from the outside edges inward to the core.',
          'Many blooms in this family track the sun from east to west throughout the day like living solar dishes to keep pollinator visitors cozy.',
          'Generations of nature lovers have pressed these cheerful blossoms inside heavy books to make greeting cards and pressed flower bookmarks.',
        ],
        observationTips: [
          'Use a magnifying glass to inspect the center disk: count how many tiny star-shaped flower tubes have already opened!',
          'Check back in the evening: does the flower curl its petals closed to sleep through the night? Note the time in your explorer log!',
        ],
        safetyNote:
            '✅ Safe and friendly to explore! Always wash your hands after outdoor adventures, and ask a grown-up before picking wild flowers.',
        rarity: rarity,
        rarityReason: 'A cheerful sun-loving bloom often spotted in grassy meadows and fields.',
      );
    }

    // 3. ROSACEAE (Rose / Apple / Strawberry / Blackberry family)
    if (famLower.contains('rosac')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Découvre $name — un membre enchanteur de la famille des Rosacées ($family) réputé pour ses fleurs délicates et ses fruits savoureux ! 🌹 '
              'C\'est la célèbre famille botanique qui nous offre les fraises des bois, les pommes et les églantines.',
          description:
              'S\'épanouissant le long des lisières de forêts et des haies champêtres, cette plante associe des fleurs à 5 pétales disposés en étoile et des tiges vigoureuses. '
              'Après la floraison, ses fleurs se métamorphosent souvent en baies ou en fruits charnus riches en vitamines que les oiseaux adorent picorer en automne.',
          funFacts: [
            'Presque toutes les fleurs sauvages de la famille des roses possèdent exactement 5 pétales disposés en étoile harmonieuse !',
            'Ses fruits (comme les cynorrhodons ou les baies) servaient traditionnellement à préparer des sirops vitaminés et des gelées parfumées.',
            'Ses tiges développent souvent de petits aiguillons incurvés qui lui permettent de grimper vers la lumière et d\'éloigner les herbivores.',
          ],
          observationTips: [
            'Compte les pétales d\'une fleur bien éclose : tu devrais en compter exactement 5 ! Regarde aussi les petites feuilles vertes sous la fleur (les sépales).',
            'Observe attentivement la tige sans appuyer fort : regarde si les aiguillons sont droits ou courbés comme des crochets d\'escalade.',
          ],
          safetyNote:
              '⚠️ Attention aux petites épines sur les tiges ! On observe avec douceur et on demande toujours l\'accord d\'un adulte avant de cueillir ou goûter des baies sauvages.',
          rarity: rarity,
          rarityReason: 'Embellit les haies de campagne et les sous-bois éclairés.',
        );
      }
      return AiContent(
        introduction:
            'Say hello to $name — a charming member of the rose family ($family) celebrated for its five-petaled blossoms and sweet fruits! 🌹 '
            'This famous plant family gives us some of the world\'s favorite treats, from wild strawberries to crisp garden apples.',
        description:
            'Thriving along woodland borders and countryside hedgerows, this plant combines star-shaped five-petaled flowers with resilient climbing stems. '
            'Once pollinated by buzzing bumblebees, its blossoms transform into vitamin-packed fruits or hips that provide vital nourishment for songbirds in autumn.',
        funFacts: [
          'Wild flowers in the rose family almost always show off exactly 5 delicate petals arranged like a neat little botanical star!',
          'Traditional country herbalists harvested autumn rosehips and wild berries to simmer into delicious syrups packed with vitamin C.',
          'Curved prickles along the stems work like natural mountaineering grappling hooks, helping the plant scramble up toward the sunshine.',
        ],
        observationTips: [
          'Count the petals on an open flower: do you find 5 delicate petals? Check underneath for the star of green sepals supporting them!',
          'Carefully trace the stems with your eyes to see how the protective prickles point downwards to anchor the climbing branches.',
        ],
        safetyNote:
            '⚠️ Watch out for sharp prickles or thorns! Admire gently with your eyes, and always ask a grown-up before picking or tasting wild berries.',
        rarity: rarity,
        rarityReason: 'Scrambles along countryside hedgerows and sunny woodland edges.',
      );
    }

    // 4. ARACEAE (Aroid / Monstera / Philodendron / Pothos family)
    if (famLower.contains('arac') || sciLower.contains('monstera') || sciLower.contains('philodendron')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Bienvenue dans la jungle avec $name — une fascinante liane tropicale de la famille des Aracées ($family) ! 🌴 '
              'Dans les forêts chaudes, elle escalade les troncs géants grâce à de solides racines aériennes.',
          description:
              'Originaire des forêts tropicales humides d\'Amérique centrale et du Sud, cette plante développe de grandes feuilles lustrées adaptées à la pénombre de la canopée. '
              'Ses racines aériennes fonctionnent comme des cordes d\'escalade qui captent l\'eau de pluie et l\'humidité brumeuse directement dans l\'air.',
          funFacts: [
            'Les découpes et trous dans ses feuilles permettent aux fortes pluies et aux bourrasques tropicales de passer au travers sans déchirer le limbe !',
            'Ses racines aériennes cherchent d\'abord l\'obscurité pour trouver le tronc d\'un arbre hôte, avant de grimper vers la cime lumineuse.',
            'C\'est l\'une des plantes compagnes les plus choyées en intérieur pour purifier l\'air et apporter une touche d\'aventure dans la maison.',
          ],
          observationTips: [
            'Observe le contour des feuilles : note si elles sont entières en cœur ou découpées en lanières graphiques.',
            'Dépoussière délicatement la surface avec un chiffon doux humide pour admirer son éclat vert profond.',
          ],
          safetyNote:
              '🌿 Agréable à caresser doucement, mais les feuilles contiennent des micro-cristaux qui piquent si on les croque. On admire avec les yeux, on ne goûte jamais et on tient éloigné des animaux !',
          rarity: rarity,
          rarityReason: 'Plante tropicale majestueuse qui recrée une ambiance de forêt tropicale.',
        );
      }
      return AiContent(
        introduction:
            'Step into the jungle with $name — a fascinating tropical climber from the arum family ($family)! 🌴 '
            'In humid tropical forests, it scales towering tree trunks using thick rope-like aerial roots.',
        description:
            'Native to the warm, shaded understory of Central and South American rainforests, this plant produces broad glossy foliage adapted to filtered jungle light. '
            'Its strong aerial roots act like living moisture cables, absorbing raindrops and morning mist straight from the humid tropical breeze.',
        funFacts: [
          'Natural splits and windows in the leaves allow fierce tropical rainstorms and wind gusts to blow right through without tearing the foliage!',
          'Young aerial roots actively seek darkness (negative phototropism) to locate a solid tree trunk, then climb upward toward the bright canopy above.',
          'It is one of the world\'s most beloved indoor green companions, bringing tropical vibes and fresh air into cozy homes and schools.',
        ],
        observationTips: [
          'Examine the leaf margins: are the edges smooth and heart-shaped, or deeply split into artistic jungle ribbons?',
          'Wipe the broad glossy surface gently with a damp cloth to help the leaf catch every beam of indoor daylight.',
        ],
        safetyNote:
            '🌿 Safe and enjoyable to gently stroke, but the foliage contains natural oxalate crystals that sting if chewed. Strictly admire — never nibble, and keep away from pets!',
        rarity: rarity,
        rarityReason: 'A striking tropical specimen that thrives in warm, bright indoor spaces.',
      );
    }

    // 5. FABACEAE / LEGUMINOSAE (Pea / Bean / Clover / Wisteria family)
    if (famLower.contains('fabac') || famLower.contains('legumin') || sciLower.contains('trifolium')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Voici $name — une super-héroïne du sol de la famille des Fabacées ($family) ! 🍀 '
              'Elle possède le pouvoir secret d\'enrichir la terre tout en nourrissant les abeilles avec ses fleurs en forme de papillon.',
          description:
              'Poussant dans les prairies et les collines tempérées du monde entier, cette plante coopère avec de minuscules bactéries amies (les Rhizobiums) logées dans ses racines. '
              'Ensemble, elles captent l\'azote de l\'air pour fabriquer un engrais naturel gratuit qui nourrit toutes les plantes voisines.',
          funFacts: [
            'Ses fleurs ont une forme poétique de papillon avec un grand pétale dressé (l\'étendard) et deux pétales latéraux (les ailes) !',
            'Ses graines se développent dans des gousses qui s\'enroulent et sautent avec un petit "pop" sec pour catapulter les graines au loin !',
            'C\'est la même grande famille bienfaisante qui nous donne les petits pois croquants, les lentilles et les haricots du potager.',
          ],
          observationTips: [
            'Regarde la fleur de très près : tu distingues la forme d\'ailes de papillon prêtes à s\'envoler ?',
            'Observe les feuilles : sont-elles découpées en 3 folioles (comme le trèfle) ou en rangées soignées le long de la tige ?',
          ],
          safetyNote:
              '✅ Douce et sans danger à manipuler. Demande toujours l\'avis d\'un adulte avant de goûter des pois ou des gousses du jardin.',
          rarity: rarity,
          rarityReason: 'Pousse dans les prairies fraîches et nourrit naturellement la terre.',
        );
      }
      return AiContent(
        introduction:
            'Meet $name — a true soil superhero from the legume family ($family)! 🍀 '
            'It has the secret power of healing the soil while feeding hungry bees with its butterfly-shaped blossoms.',
        description:
            'Spreading through sunny meadows and gentle slopes worldwide, this plant works in partnership with friendly underground root bacteria called Rhizobia. '
            'Together, they pull nitrogen out of the air to make natural fertilizer that boosts and nourishes the surrounding earth.',
        funFacts: [
          'Its blossoms are shaped like tiny landing butterflies, featuring an upright banner petal at the top and two wing petals at the sides!',
          'When seed pods dry in the sunshine, they twist tightly and pop open with a snap, catapulting seeds across the meadow like miniature cannons!',
          'This generous botanical family gives us favorite healthy kitchen treats, including sweet garden peas, crunchy beans, and lentils.',
        ],
        observationTips: [
          'Examine a blossom up close: can you spot the butterfly "wings" and the central "boat keel" where nectar hides?',
          'Check the foliage: are the leaves split into three sweet leaflets (trifoliate) or arranged in neat feathery ladders?',
        ],
        safetyNote:
            '✅ Gentle and safe to handle! Always consult a knowledgeable grown-up before harvesting or tasting garden peas and pods.',
        rarity: rarity,
        rarityReason: 'Enriches meadow soil and provides sweet nectar for wild bees.',
      );
    }

    // 6. PINACEAE / CUPRESSACEAE / CONIFERS (Pine, Fir, Spruce, Cypress)
    if (famLower.contains('pinac') || famLower.contains('cupress') || sciLower.contains('pinus')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Découvre $name — un fier géant de la forêt de la famille des Conifères ($family) ! 🌲 '
              'Il brave la neige, le vent et le froid hivernal grâce à ses aiguilles cireuses persistantes et sa résine parfumée.',
          description:
              'Vivant sur les crêtes rocheuses et dans les grandes forêts du Nord, cet arbre remplace les larges feuilles fragiles par des aiguilles couvertes d\'une cire protectrice. '
              'Ses graines grandissent à l\'abri d\'écailles solides formant des pommes de pin qui s\'ouvrent et se ferment selon la météo.',
          funFacts: [
            'Les pommes de pin sont de véritables baromètres naturels : elles se ferment hermétiquement sous la pluie et s\'ouvrent au soleil sec pour libérer leurs graines ailées !',
            'Sa résine dorée et collante agit comme un pansement magique pour cicatriser l\'écorce de l\'arbre s\'il est égratigné par le vent.',
            'L\'odeur fraîche et boisée de ses aiguilles provient d\'huiles essentielles appelées terpènes, qui purifient l\'air de la forêt.',
          ],
          observationTips: [
            'Respire tes doigts après avoir effleuré un rameau d\'aiguilles : cette bonne odeur boisée rappelle les balades en forêt en montagne !',
            'Ramasse une pomme de pin au sol : est-elle grande ouverte (signe d\'air sec) ou toute resserrée (signe d\'humidité) ?',
          ],
          safetyNote:
              '🌲 Attention à la résine collante sur les doigts et aux pointes d\'aiguilles ! Manipule les rameaux avec douceur.',
          rarity: rarity,
          rarityReason: 'Grand protecteur de la forêt qui garde sa belle couleur verte tout l\'hiver.',
        );
      }
      return AiContent(
        introduction:
            'Discover $name — an evergreen forest sentinel from the conifer family ($family)! 🌲 '
            'It braves freezing snow, howling winds, and winter frost with tough waxy needles and aromatic protective resin.',
        description:
            'Rooted across brisk northern woodlands and rocky mountain ridges, this tree swaps fragile broad leaves for slender needles coated in waterproof wax. '
            'Its seeds stay protected inside woody cones that act like clever botanical weather forecast stations.',
        funFacts: [
          'Pinecones are natural weather forecasters: they seal tightly shut when it rains and pop wide open on dry sunny days so breezes carry winged seeds away!',
          'Golden sticky tree resin acts like a healing liquid bandage, sealing cracks and protecting the trunk against invading fungi and bugs.',
          'The invigorating forest fragrance comes from natural aromatic compounds called terpenes, which help clean the surrounding woodland air.',
        ],
        observationTips: [
          'Sniff your fingers after gently brushing the needles: enjoy that crisp, refreshing evergreen aroma!',
          'Look for fallen cones beneath the branches: are the woody scales closed tight (damp weather) or flared wide open (dry weather)?',
        ],
        safetyNote:
            '🌲 Watch out for sticky resin that clings to fingers and sharp needle tips; explore branches and cones with gentle hands.',
        rarity: rarity,
        rarityReason: 'An enduring evergreen that keeps mountain forests vibrant and green all year.',
      );
    }

    // 7. CACTACEAE / CRASSULACEAE (Cacti & Succulents)
    if (famLower.contains('cact') || famLower.contains('crassul') || sciLower.contains('aloe') || sciLower.contains('sedum')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Voici $name — un champion des terres arides de la famille des Succulentes ($family) ! 🏜️ '
              'Véritable réservoir vivant, cette plante stocke sa propre réserve d\'eau dans ses feuilles charnues pour survivre des mois sans pluie.',
          description:
              'Évoluant sur les rochers ensoleillés et les pentes désertiques, elle possède un super-pouvoir d\'économie d\'eau. '
              'Elle garde ses pores fermés pendant la chaleur brûlante du jour pour ne rien évaporer, et respire tranquillement la nuit à la fraîche.',
          funFacts: [
            'Le voile poudré et bleuté sur ses feuilles s\'appelle la pruine : c\'est une crème solaire minérale 100% naturelle fabriquée par la plante !',
            'Une simple feuille tombée sur de la terre peut fabriquer ses propres racines et donner naissance à un bébé plante tout neuf !',
            'Certaines espèces comme l\'Aloe vera renferment un gel apaisant utilisé depuis des millénaires pour rafraîchir la peau après le soleil.',
          ],
          observationTips: [
            'Effleure très délicatement une feuille charnue : sens comme elle est ferme et gonflée d\'eau de réserve comme une gourde végétale.',
            'Observe ses reflets de couleur : vert d\'eau, bleuté ou teinté de rose sous le soleil éclatant.',
          ],
          safetyNote:
              '🏜️ Très douce pour les succulentes à feuilles lisses ! Pour les cactus à piquants, admire strictement avec les yeux pour éviter les épines.',
          rarity: rarity,
          rarityReason: 'Un champion de la survie qui stocke l\'eau comme un trésor.',
        );
      }
      return AiContent(
        introduction:
            'Meet $name — a master desert survivor from the succulent family ($family)! 🏜️ '
            'A living water canteen, this incredible plant stores its own private moisture reservoir inside plump, fleshy leaves to thrive for months without rain.',
        description:
            'Thriving across sun-drenched canyon rocks and arid slopes, it uses a smart water-saving superpower. '
            'It keeps its pores tightly sealed during the blazing daytime heat to avoid losing moisture, breathing peacefully in the cool desert night.',
        funFacts: [
          'The powdery bluish-white coating on the leaves is called farina: it works like natural mineral sunscreen to reflect scorching UV rays!',
          'A single healthy succulent leaf resting on moist soil can sprout fresh roots and grow into an entirely new baby plant! 🌱',
          'Beloved species like Aloe vera store a cooling clear gel inside their leaves that people have used for thousands of years to soothe sun-warmed skin.',
        ],
        observationTips: [
          'Very gently touch a plump leaf: feel how firm and juicy it is compared to a paper-thin regular garden leaf.',
          'Notice how water droplets bead up on the waxy surface and roll off like little crystal spheres.',
        ],
        safetyNote:
            '🏜️ Smooth succulents are gentle and safe to touch! If exploring a spiny cactus, admire strictly with your eyes to avoid prickly spines.',
        rarity: rarity,
        rarityReason: 'A sun-loving survivor with plump leaves designed to store precious water.',
      );
    }

    // 8. GENERAL DYNAMIC FALLBACK (Tailored to any other family without generic boilerplate)
    if (isFrench) {
      return AiContent(
        introduction:
            'Fais la connaissance de $name — un spécimen captivant de la famille des $family ($scientificName) ! 🌿 '
            'Chaque détail de sa silhouette est une astuce ingénieuse développée au fil du temps pour s\'épanouir dans son milieu.',
        description:
            'Évoluant dans son habitat naturel caractéristique, cette plante déploie des feuilles et des fleurs adaptées aux caprices de la météo locale. '
            'Elle offre un havre précieux pour la petite faune du quartier, servant d\'abri pour les coccinelles et de piste d\'envol pour les insectes ailés.',
        funFacts: [
          'Les botanistes reconnaissent les $family en examinant le tracé des nervures sur les feuilles et la symétrie harmonieuse de leurs pétales.',
          'Beaucoup d\'espèces de ce groupe sont choyées par les jardiniers pour créer de superbes bouquets séchés ou des coins nature au jardin.',
          'La manière dont ses feuilles s\'attachent à la tige (face à face ou décalées) est comme une empreinte digitale végétale unique !',
        ],
        observationTips: [
          'Effleure délicatement une feuille : est-elle lisse, veloutée comme du duvet ou un peu cireuse ?',
          'Compte les pétales d\'une fleur éclose et esquisse la forme de sa feuille dans ton carnet d\'explorateur de la nature !',
        ],
        safetyNote:
            '🧤 Conseil d\'explorateur : lave-toi toujours les mains après tes sorties nature et demande l\'aide d\'un adulte avant de cueillir des plantes sauvages.',
        rarity: rarity,
        rarityReason: 'Observée dans son milieu naturel par les explorateurs attentifs !',
      );
    }

    return AiContent(
      introduction:
          'Say hello to $name — a captivating discovery from the $family family ($scientificName)! 🌿 '
          'Every curve of its leaves and stem is a clever design evolved over generations to thrive in its outdoor home.',
      description:
          'Thriving in its native natural habitat, this plant unfurls distinctive foliage and blossoms tailored to its local climate. '
          'It provides essential shelter and nectar for neighborhood wildlife, serving as a cozy rest stop for ladybugs and wandering pollinators.',
      funFacts: [
        'Botanists identify members of the $family family by studying the intricate vein patterns across the leaves and the symmetry of their petals.',
        'Many species in this botanical circle have been treasured across generations for colorful garden borders, pressed-flower crafts, and bouquet gifting.',
        'The way its leaves attach along the stem — either alternating or in opposite pairs — is like a unique botanical fingerprint!',
      ],
      observationTips: [
        'Gently stroke a leaf with your fingertip: is the texture glossy, fuzzy like soft velvet, or finely ribbed with veins?',
        'Count the petals on an open bloom and sketch its silhouette in your nature field journal!',
      ],
      safetyNote:
          '🧤 Explorer safety tip: Always wash your hands after outdoor expeditions, and check with a grown-up before picking wild plants or trying DIY nature crafts.',
      rarity: rarity,
      rarityReason: 'Spotted and celebrated in its natural outdoor habitat!',
    );
  }
}
