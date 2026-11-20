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
/// Uses lightning-fast lightweight models (under 1-2s response time) with a
/// warm, playful, and kid-friendly tone that avoids boring lab textbook jargon.
class GeminiAiContentService implements AiContentService {
  final String apiKey;

  // Ultra-fast lightweight models (sub-second to ~2s latency)
  static const List<String> _candidateModels = [
    'gemini-3.5-flash-lite',
    'gemini-flash-lite-latest',
    'gemini-3.1-flash-lite',
  ];
  static const Duration _timeout = Duration(seconds: 10);

  GeminiAiContentService(this.apiKey);

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
        ? 'RÈGLE DE LANGUE : Rédige TOUTE ta réponse en FRANÇAIS, avec un ton super joueur, chaleureux et rigolo pour un enfant de 9-10 ans. ZÉRO jargon de laboratoire rébarbatif !'
        : 'LANGUAGE RULE: Write your ENTIRE response in English. Use a super warm, playful, funny tone like an enthusiastic nature camp counselor talking to a 9-10 year old kid. ZERO boring lab textbook jargon!';

    final prompt = '''
You are Mossy, a playful, witty, and enthusiastic nature companion for kids and everyday explorers!
$langNote

Plant to explore: "$commonName" (Scientific name: $scientificName, Family: $family)

TONE & CONTENT RULES (FOLLOW STRICTLY):
1. NOT A LAB TEXTBOOK: No robotic, academic, or scientific jargon (never say "photosynthesis", "inflorescence", "angiosperm", "calcium oxalate", "phenolic"). If you mention a cool feature, explain it in simple, funny words.
2. SHORT & PUNCHY: Do NOT write long paragraphs or walls of text. Keep each part to 1-2 short, snappy, lively sentences. Focus only on the coolest, most fun things!
3. IDENTITY / QUICK LOOK: Introduce the plant's funny personality, everyday vibe, or secret superpower.
4. STORY & WHERE IT LIVES: 2 short sentences on where in the world it lives (countries, rocky hills, gardens, sidewalks, living rooms) and why it's cool to see.
5. FUN & PRACTICAL USES: Concrete, fun ways people enjoy it (brewing cozy tea, making DIY skin masks, gifting baby cuttings in jars, fragrant closet pouches, pressing flowers) with safe grown-up guidance.
6. COOL FACTS: Playful trivia kids will giggle at or love telling friends at school (weird habits, bugs, funny records).
7. HOW TO GROW OR SPOT IT: Simple outdoor detective clues (leaf shape, texture, scent) and easy tips to grow or spot it.
8. REAL SAFE EXPLORER TIP: Give a REAL safety truth tailored to this plant! Can you put it in your mouth? Does it taste super bitter, spicy, or sour? Is it toxic (never eat it!) or safe? Does it have sharp thorns, prickles, or itchy sap? Tell kids straight, clearly, and simply.
9. RARITY: EXACTLY one lowercase English word from: common, uncommon, rare, epic, legendary.
10. RARITY REASON: One short funny/playful sentence in the response language.

Return ONLY a valid JSON object (no markdown fences, no extra text) with this EXACT structure:
{
  "introduction": "1-2 short, punchy, playful sentences introducing the plant's vibe or superpower.",
  "description": "2 short sentences: Where it lives in the world and what makes it look cool.",
  "funFacts": [
    "Practical fun use: A real thing people make or do with it (tea, crafts, decor, cuttings) with safe grown-up guidance",
    "Cool quirk or funny habit kids love",
    "Surprising bite-sized record or story to tell friends"
  ],
  "observationTips": [
    "Detective clue: A hands-on detail to look for or touch",
    "Growing or spotting tip"
  ],
  "safetyNote": "A REAL plant-specific safety truth (taste, mouth safety, bitterness, thorns, or touch safety).",
  "rarity": "common",
  "rarityReason": "One short playful sentence."
}
''';

    for (final model in _candidateModels) {
      try {
        debugPrint('[Gemini] Requesting content for $scientificName with $model...');
        final apiUrl =
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

        final response = await http
            .post(
              Uri.parse(apiUrl),
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
                  'maxOutputTokens': 800,
                  'responseMimeType': 'application/json',
                },
              }),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          debugPrint('[Gemini] Generated in lightning speed with $model!');
          return _parseResponse(response.body, scientificName, commonName, family, isFrench);
        } else {
          debugPrint('[Gemini] Model $model returned status ${response.statusCode}, trying fallback...');
        }
      } catch (e) {
        debugPrint('[Gemini] Exception on $model: $e, trying fallback...');
      }
    }

    // If all online attempts fail or timeout, fall back to rich, instant demo service
    return DemoAiContentService().generateBotanicalWisdomSync(
      scientificName,
      commonName,
      family,
      isFrench,
    );
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

      final candidates = responseJson['candidates'] as List<dynamic>? ?? [];
      if (candidates.isEmpty) {
        throw Exception('No candidates in Gemini response');
      }

      final content = candidates.first['content'] as Map<String, dynamic>? ?? {};
      final parts = content['parts'] as List<dynamic>? ?? [];
      if (parts.isEmpty) {
        throw Exception('No parts in Gemini content');
      }

      final rawText = parts.first['text'] as String? ?? '';

      Map<String, dynamic> plantJson;
      try {
        plantJson = jsonDecode(rawText) as Map<String, dynamic>;
      } catch (_) {
        final cleaned = rawText
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '')
            .trim();
        plantJson = jsonDecode(cleaned) as Map<String, dynamic>;
      }

      final reasonRaw = plantJson['rarityReason'] ?? plantJson['rarity_reason'];
      final reason = reasonRaw is String ? reasonRaw.trim() : '';
      final rarity = DiscoveryRarity.tryParse(plantJson['rarity']);

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
      debugPrint('[Gemini] Parse error: $e — using botanical fallback');
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
// DEMO FALLBACK IMPLEMENTATION (used when offline or no API key)
// ============================================================================

/// Offline demo implementation with curated fun botanical knowledge for common plants
/// and a family-specific botanical wisdom generator.
/// Tone: warm, playful, kid-friendly — never generic textbook filler.
class DemoAiContentService implements AiContentService {
  static final Map<String, AiContent> _curatedKnowledge = {
    'bellis perennis': AiContent(
      introduction:
          'Meet the Common Daisy — the ultimate lawn superstar that opens its bright sunny eye at dawn and takes a cozy nap at dusk! 🌼',
      description:
          'You can spot these cheerful little bloomers in parks, lawns, and grassy meadows all across Europe. Up close, each "daisy" is actually a mega-party of over 100 tiny flowers packed together!',
      funFacts: const [
        'People have made daisy-chain crowns for centuries — you can make one too by gently linking the stems with a tiny slit!',
        'The name "Daisy" comes from Old English "day\'s eye" because it opens wide in the morning light like a waking eye. 👁️',
        'Hungry bees and tiny hoverflies treat daisies like a miniature highway rest-stop buffet for sweet nectar.',
      ],
      observationTips: const [
        'Check on the same daisy at noon and again at sunset: watch how it folds its petals closed to sleep! 😴',
        'Use a magnifying glass to look at the yellow center: count how many mini star-flowers you can see inside!',
      ],
      safetyNote:
          '✅ Totally safe to touch and braid into crowns! Petals can taste slightly bitter, so leave the snacking to the bees and wash your hands after rolling in the grass.',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Pops up in almost every green lawn on sunny mornings!',
    ),
    'taraxacum officinale': AiContent(
      introduction:
          'Say hello to the Dandelion — the backyard stunt pilot with the coolest built-in parachute delivery system on Earth! 🦁',
      description:
          'These sunny little rebels grow in lawns, meadows, and even punch right through sidewalk cracks to wave at you! When flowers fade, they turn into fluffy white globe parachutes.',
      funFacts: const [
        'Grown-ups roast the roots to make a cozy caramel-flavored drink, and make sweet sunny jelly out of the yellow flower heads!',
        'Its seeds can catch a warm breeze and fly more than 5 kilometers away — engineers study them to design better flying drones! 🚁',
        'The name comes from French "dent-de-lion" (lion\'s tooth) because the spiky leaf edges look like fierce little jaws!',
      ],
      observationTips: const [
        'Find a fluffy puffball and blow gently: count how many puffs it takes to launch all the tiny parachutes into the sky! ⏰',
        'Look at the leaves: notice how they form a rosette funnel that channels rainwater straight down to the root like a slide!',
      ],
      safetyNote:
          '🌿 Safe to touch, but snapping the stem releases white milky sap that tastes super bitter and can make sensitive skin itch. Wash hands after playing!',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Spotted everywhere from schoolyards to pavement cracks!',
    ),
    'rosa canina': AiContent(
      introduction:
          'Look out for the Wild Dog Rose — a fairytale rambler packed with sweet pink blossoms and bright red berries called rose hips! 🌹',
      description:
          'It scrambles through hedgerows and woodland borders across Europe, using curved prickles like mountaineering grappling hooks. In autumn, the branches glow with shiny red fruits.',
      funFacts: const [
        'Rose hips pack 20 times more vitamin C than oranges! You can simmer them with an adult into delicious vitamin syrup.',
        'Beware of pranksters: the tiny hairs inside rose hips used to be collected by kids to make itchy itch-powder! 😆',
        'Wild roses always show off exactly 5 delicate petals arranged in a neat star shape.',
      ],
      observationTips: const [
        'Carefully look at the stem without squeezing: notice how the prickles curve downward like climbing hooks!',
        'In autumn, count how many red hips are on one branch and see if you can spot a robin having a berry snack. 🐦',
      ],
      safetyNote:
          '⚠️ Ouch! Sharp curved prickles can snatch your clothes and scratch fingers. Never chew the inside of rose hips raw — the tiny hairs are super itchy!',
      rarity: DiscoveryRarity.uncommon,
      rarityReason: 'Scrambles along wild country hedgerows and sunny woodland edges.',
    ),
    'lavandula angustifolia': AiContent(
      introduction:
          'Meet English Lavender — the superhero of chill vibes and the fluffiest purple relaxation machine on the planet! 💜',
      description:
          'Originally from sunny rocky hills around the Mediterranean, it now throws fragrant purple fashion shows in gardens everywhere. Bees go absolutely bonkers for its sweet nectar.',
      funFacts: const [
        'Stuff dried lavender flowers into small cloth pouches and tuck them in your closet — it makes clothes smell incredible AND scares away moths!',
        'Ancient Roman kids and grown-ups tossed sprigs into their bathwater because it was nature\'s first bubble-bath perfume! 🛁',
        'Lavender stems have tiny microscopic oil tanks on the leaves that burst with perfume when the warm sun shines.',
      ],
      observationTips: const [
        'Gently rub a leaf between your thumb and finger, then smell your hand: you just unlocked its pure essential oil perfume!',
        'Check the stem: roll it between your fingers to feel its square, four-sided shape — a secret signature of the mint family.',
      ],
      safetyNote:
          '✅ Non-toxic and super gentle to touch! Munching on raw garden stems tastes very bitter and soapy, so save the lavender treats for baked cookies with an adult.',
      rarity: DiscoveryRarity.rare,
      rarityReason: 'Loves hot sun and rocky soil — wild lavender is a special treasure!',
    ),
    'trifolium repens': AiContent(
      introduction:
          'Meet White Clover — the lawn superhero that secretly feeds the soil while offering lucky hunters a 1-in-10,000 challenge! 🍀',
      description:
          'It creeps happily through lawns, parks, and roadsides worldwide. Underground, its roots host friendly microbe buddies that pull natural plant food right out of thin air!',
      funFacts: const [
        'Farmers love clover because it heals and fertilizes tired soil naturally without needing chemicals!',
        'Bumblebees and honeybees make some of the sweetest, lightest honey in the world from white clover blossoms.',
        'Your odds of finding a lucky four-leaf clover are roughly 1 in 10,000 — but dedicated clover detectives sometimes find whole patches!',
      ],
      observationTips: const [
        'Crawl through the grass and search slowly: look for white smiling crescent marks on each little leaflet!',
        'Visit a clover patch at dusk: watch how the leaves fold upward together like little hands going to sleep for the night! 😴',
      ],
      safetyNote:
          '✅ Gentle and safe to touch! You can even nibble a washed flower petal for a mild sweet taste, but don\'t eat raw clover leaves by the handful.',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Covers grassy lawns everywhere, but 4-leaf ones are legendary!',
    ),
    'monstera deliciosa': AiContent(
      introduction:
          'Hey jungle scout! Meet the Swiss Cheese Plant — the leafy prankster equipped with giant green cartoon speed-holes! 🌿',
      description:
          'Native to the warm tropical rainforests of Central America, it scales giant trees with rope-like aerial roots and has become the ultimate rockstar houseplant.',
      funFacts: [
        'Plant lovers love snipping a baby leaf stem and growing roots in water jars like trading living green Pokémon cards!',
        'In the wild, it grows an edible tropical fruit that tastes like a mashup of pineapple, banana, and strawberry! 🍍🍌',
        'The crazy holes and slits in the leaves allow hurricane winds and jungle storms to blow right through without tearing the plant.',
      ],
      observationTips: [
        'Go on a detective count: how many holes and edge cuts can you spot on one giant leaf?',
        'Look for thick brown aerial roots hanging down like giant noodles trying to tickle the floor.',
      ],
      safetyNote:
          '🚫 Keep it out of your mouth! Chewing raw Monstera leaves makes your tongue and throat feel super spicy and tingly like a swarm of fire ants. Admire strictly with your eyes, and keep away from pets!',
      rarity: DiscoveryRarity.rare,
      rarityReason: 'A majestic tropical native loved in botanical greenhouses and cozy indoor jungles.',
    ),
    'urtica dioica': AiContent(
      introduction:
          'Watch your ankles! Meet the Stinging Nettle — the sharp-witted backyard rebel that guards its territory with invisible micro-needles! ⚡',
      description:
          'It thrives in rich soil near old stone walls, shady woods, and garden edges worldwide. Beneath its toothy green leaves hides an army of glass-like stinging hairs.',
      funFacts: [
        'With an adult, you can boil nettle leaves into a delicious green soup or tea — cooking completely destroys the sting and reveals a yummy spinach flavor!',
        'Ancient warriors made armor cloth and tough rope from nettle stems because its plant fibers are as strong as canvas!',
        'It is a five-star nursery for colorful butterfly caterpillars who munch the leaves safely without getting stung.',
      ],
      observationTips: [
        'Use a magnifying glass from a safe distance: spot the hollow glass-like needles waiting like tiny hypodermic syringes!',
        'Look near old compost heaps and damp ditches — nettles love rich, damp soil where other plants fear to grow.',
      ],
      safetyNote:
          '⚡ Ouch! Never touch with bare hands! The tiny hairs inject a drop of stinging fluid that makes your skin itch, tingle, and burn for hours. Definitely never put it raw in your mouth!',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Pops up along every country trail, fence line, and wild ditch!',
    ),
  };

  static final Map<String, AiContent> _curatedKnowledgeFr = {
    'bellis perennis': AiContent(
      introduction:
          'Coucou l\'explorateur ! Voici la Pâquerette, la reine des pelouses qui ouvre grand son œil au soleil et fait la sieste au crépuscule ! 🌼',
      description:
          'Elle illumine les parcs, les prés et les jardins d\'Europe. De près, chaque fleur est en fait une colonie joyeuse de plus de 100 mini-fleurs réunies en équipe !',
      funFacts: const [
        'On tresse des couronnes de fées avec ses tiges depuis des siècles en faisant une petite fente avec l\'ongle !',
        'Son nom anglais "Daisy" vient de "day\'s eye" (l\'œil du jour) parce qu\'elle s\'ouvre dès les premiers rayons du matin. 👁️',
        'Les abeilles et les syrphes la traitent comme une station-service miniature pour faire le plein de nectar frais.',
      ],
      observationTips: const [
        'Observe la même pâquerette à midi puis à 20h : regarde comme ses pétales blancs se referment pour dormir ! 😴',
        'Zoome avec une loupe sur le cœur jaune : compte combien de petites étoiles dorées tu arrives à distinguer.',
      ],
      safetyNote:
          '✅ 100% sûre à toucher et tresser ! Les pétales ont un léger goût amer, alors laisse le goûter aux abeilles et lave-toi les mains après avoir joué dans l\'herbe.',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Présente dans presque toutes les pelouses dès le premier rayon de soleil !',
    ),
    'taraxacum officinale': AiContent(
      introduction:
          'Fais coucou au Pissenlit — le cascadeur tout-terrain équipé du meilleur système de parachutes de toute la nature ! 🦁',
      description:
          'Ce petit rebelle pousse dans les prés, les parcs et perce même le goudron des trottoirs pour nous saluer ! Dès que sa fleur jaune fane, elle se transforme en boule de duvet blanc.',
      funFacts: const [
        'Les grands font torréfier ses racines pour préparer une boisson au goût de caramel, et cuisinent de la gelée dorée avec les fleurs !',
        'Chaque graine a son propre parachute qui peut voler à plus de 5 kilomètres au vent — les scientifiques l\'étudient pour créer des drones ! 🚁',
        'Son nom vient de "dents de lion" car les découpes de ses feuilles ressemblent à de petites mâchoires féroces !',
      ],
      observationTips: const [
        'Cueille une boule blanche et souffle doucement : compte combien de souffles il faut pour faire décoller tous les parachutes ! ⏰',
        'Regarde la tige coupée : remarque comme elle est creuse comme une paille de boisson géante.',
      ],
      safetyNote:
          '🌿 Sans danger à manipuler, mais sa sève blanche a un goût super amer et peut faire des taches marron sur les doigts. Lave-toi bien les mains après la récolte !',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Pousse partout, des cours de récré aux trottoirs de ville !',
    ),
    'rosa canina': AiContent(
      introduction:
          'Attention les yeux, voici l\'Églantier — le rosier sauvage de conte de fées qui adore chatouiller les promeneurs ! 🌹',
      description:
          'Il grimpe dans les haies de campagne grâce à ses épines recourbées comme des crampons d\'alpiniste. En automne, il brille de petites baies rouge vif appelées cynorrhodons.',
      funFacts: const [
        'Ses fruits rouges contiennent 20 fois plus de vitamine C que les oranges ! On en fait du sirop délicieux avec un adulte.',
        'Ses fruits cachent à l\'intérieur le célèbre "poil à gratter" naturel que les enfants utilisaient pour faire des blagues ! 😆',
        'Ses fleurs sauvages ont toujours exactement 5 pétales doux comme de la soie rose.',
      ],
      observationTips: const [
        'Regarde bien la tige sans appuyer : vois comme ses aiguillons sont courbés vers le bas pour l\'aider à grimper !',
        'En hiver, compte les baies rouges sur une branche et guette les merles qui viennent s\'en régaler comme de petits bonbons. 🐦',
      ],
      safetyNote:
          '⚠️ Aïe ! Ses épines en crochets griffent facilement les doigts et les vêtements. Ne mange jamais l\'intérieur des fruits cru : les petits poils grattent affreusement la langue !',
      rarity: DiscoveryRarity.uncommon,
      rarityReason: 'Grimpe le long des haies champêtres et des sentiers de forêt.',
    ),
    'lavandula angustifolia': AiContent(
      introduction:
          'Salut l\'explorateur ! Voici la Lavande, la reine incontestée de la zen-attitude et le parfum le plus doux de la nature ! 💜',
      description:
          'Née sur les collines rocailleuses du soleil méditerranéen, elle décore les jardins de ses épis violets. Les bourdons en sont tellement fous qu\'ils y dansent toute la journée.',
      funFacts: const [
        'Glisse des fleurs séchées dans un petit pochon en tissu dans ton armoire : ça sent le propre et ça fait fuir les mites !',
        'Les Romains en mettaient des brassées entières dans leurs bains chauds pour inventer le tout premier bain moussant parfumé ! 🛁',
        'Fais rouler sa tige entre tes doigts : elle a 4 côtés bien carrés, la marque secrète des plantes de la menthe !',
      ],
      observationTips: const [
        'Frotte une petite feuille grise entre deux doigts et respire : tu viens de libérer son parfum magique d\'huiles essentielles !',
        'Observe les fleurs de près : chaque épi est un gratte-ciel miniature où les abeilles s\'arrêtent à chaque étage.',
      ],
      safetyNote:
          '✅ Très douce et sans aucun danger à caresser ! Croquer une branche crue a un goût super amer et savonneux, alors réserve la lavande pour les sablés faits avec un grand.',
      rarity: DiscoveryRarity.rare,
      rarityReason: 'Aime le plein soleil chaud et les sols caillouteux bien secs.',
    ),
    'monstera deliciosa': AiContent(
      introduction:
          'Bienvenue dans la jungle avec le Monstera — le farceur végétal troué comme une tranche géante d\'emmental ! 🌿',
      description:
          'Originaire des forêts chaudes du Mexique, il grimpe aux arbres avec de grosses racines-cordes et s\'invite dans nos salons pour y mettre une ambiance tropicale cartoon.',
      funFacts: [
        'Les amoureux des plantes s\'échangent des boutures dans des pots d\'eau comme des cartes Pokémon vivantes !',
        'Dans la vraie jungle, son fruit sauvage a le goût d\'une salade d\'ananas, de banane et de fraise bien mûre ! 🍍🍌',
        'Ses trous permettent aux énormes tempêtes tropicales de traverser les feuilles sans les déchirer.',
      ],
      observationTips: [
        'Fais l\'inspecteur : compte combien de trous et de découpes tu trouves sur une seule grande feuille !',
        'Cherche les racines marron qui pendent dans le vide comme des nouilles géantes cherchant le sol.',
      ],
      safetyNote:
          '🚫 Pas dans la bouche ! Croquer une feuille de Monstera pique affreusement la langue et la gorge comme des piqûres de fourmis rouges. On admire seulement avec les yeux, et loin des animaux !',
      rarity: DiscoveryRarity.rare,
      rarityReason: 'Une star tropicale reine des serres botaniques et des intérieurs douillets.',
    ),
    'urtica dioica': AiContent(
      introduction:
          'Attention les mollets ! Voici la Grande Ortie — la rebelle de nos campagnes qui défend son coin avec des micro-seringues invisibles ! ⚡',
      description:
          'Elle pousse près des vieux murs de pierre, au fond du jardin et dans les fossés humides. Sous ses feuilles dentées se cache une armée de poils piquants prêts à faire sursauter.',
      funFacts: [
        'Avec un adulte, cuisine-la en soupe ou en galettes : la cuisson détruit complètement le piquant et c\'est un régal digne d\'un banquet de chevaliers !',
        'Les anciens tissaient ses tiges pour fabriquer des vêtements aussi solides et résistants que de la toile de jean !',
        'C\'est l\'hôtel 5 étoiles préféré des chenilles de papillons qui s\'y régalent à l\'abri des prédateurs.',
      ],
      observationTips: [
        'Prends une loupe sans trop t\'approcher : observe les petits poils translucides dressés comme des aiguilles en verre !',
        'Regarde au fond du jardin près des vieux tas de bois : c\'est son spot secret préféré.',
      ],
      safetyNote:
          '⚡ Aïe aïe aïe ! Ne la touche JAMAIS à mains nues ! Ses poils microscopiques injectent un venin qui brûle et démange la peau pendant des heures. Et surtout, interdiction totale de la mettre crue dans la bouche !',
      rarity: DiscoveryRarity.common,
      rarityReason: 'Pousse le long de tous les chemins de campagne et adore surprendre les marcheurs !',
    ),
  };

  @override
  Future<AiContent> generateContent(
    String scientificName,
    String commonName,
    String family,
    String language,
  ) async {
    // Instant simulation latency (100ms)
    await Future.delayed(const Duration(milliseconds: 100));

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
  /// Playful, kid-level, short, and punchy — eliminates robotic textbook jargon!
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

    // 1. LAMIACEAE (Mint / Lavender / Sage / Rosemary / Thyme)
    if (famLower.contains('lamiac') || famLower.contains('labiat') || sciLower.contains('mentha') || sciLower.contains('salvia')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Coucou l\'explorateur ! Découvre $name — un membre magique de la famille de la menthe aux tiges carrées secrètes ! 🌿',
          description:
              'Originaire des collines ensoleillées de Méditerranée, elle diffuse un parfum tonique dès que le soleil la réchauffe. Ses fleurs étagées accueillent les bourdons comme sur un tapis rouge.',
          funFacts: [
            'Fais-toi préparer une tisane bienfaisante ou des petits sachets odorants pour parfumer ton armoire avec un adulte.',
            'Fais rouler sa tige entre tes doigts : elle a 4 côtés bien carrés ! C\'est le passeport secret de cette famille.',
            'Son parfum puissant sert de bouclier naturel pour éloigner les insectes pénibles tout en appelant les gentilles abeilles.',
          ],
          observationTips: [
            'Frotte très doucement une feuille entre ton pouce et ton index, puis sens tes doigts : ça sent le grand air !',
            'Observe l\'épi de fleurs : les petites corolles forment des étages soignés où les insectes font la queue.',
          ],
          safetyNote:
              '✅ Douce et sûre à toucher ! Mais croquer une feuille crue au jardin a un goût très fort, savonneux ou amer. Demande à un adulte avant de goûter.',
          rarity: rarity,
          rarityReason: 'Une plante aromatique pleine d\'énergie qui adore le plein soleil !',
        );
      }
      return AiContent(
        introduction:
            'Hey there, explorer! Meet $name — an aromatic treasure from the mint family with secret square stems! 🌿',
        description:
            'Native to sunny Mediterranean hills, it fills the air with a fresh aroma whenever the sun hits its leaves. Hungry bumblebees line up at its stacked blossoms for sweet afternoon snacks.',
        funFacts: [
          'People love brewing cozy herbal teas or making scented drawer pouches with dried leaves to keep clothes smelling fresh.',
          'Roll the stem between two fingers: it has four flat corners! That square shape is the secret family trademark.',
          'The rich natural aroma acts like a fragrant superhero shield that repels garden pests while welcoming friendly bees.',
        ],
        observationTips: [
          'Gently rub a leaf between your thumb and finger, then take a sniff: you just unlocked its pure essential oil perfume!',
          'Look closely at the flower spike: the blossoms are stacked in neat little rings like landing decks.',
        ],
        safetyNote:
            '✅ Safe and gentle to touch! Raw garden leaves can taste super strong, soapy, or bitter, so always check with an adult before brewing herbal tea.',
        rarity: rarity,
        rarityReason: 'A sunny outdoor favorite that loves warm rocks and garden borders.',
      );
    }

    // 2. ASTERACEAE (Daisy / Sunflower / Dandelion / Thistle)
    if (famLower.contains('asterac') || famLower.contains('composit')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Fais coucou à $name — un champion du travail d\'équipe de la famille des marguerites et pissenlits ! 🌼',
          description:
              'Poussant dans les prés ouverts et les clairières, ce que tu prends pour une fleur est en réalité une vraie fête de dizaines de micro-fleurs réunies.',
          funFacts: [
            'Presse ses jolies fleurs dans un vieux livre lourd pour fabriquer des marque-pages ou d\'adorables cartes fleuries.',
            'Beaucoup de ces fleurs tournent leur tête vers le soleil toute la journée pour garder leur pollen bien tiède.',
            'Ses graines volent souvent au vent sur de minuscules parachutes plumeux pour conquérir de nouveaux horizons.',
          ],
          observationTips: [
            'Regarde le disque central à la loupe : admire les dizaines de minuscules étoiles dorées qui s\'ouvrent petit à petit.',
            'Surveille la fleur en fin d\'après-midi : elle se referme souvent comme des paupières pour passer la nuit au chaud ! 😴',
          ],
          safetyNote:
              '🌿 Sûre à caresser ! Attention : la sève de tige ou les feuilles crues peuvent avoir un goût très amer, et méfie-toi des chardons qui ont des piquants pointus.',
          rarity: rarity,
          rarityReason: 'Fleurit joyeusement dans les prés herbeux au moindre rayon de soleil.',
        );
      }
      return AiContent(
        introduction:
            'Say hello to $name — a master of teamwork from the daisy family! 🌼',
        description:
            'Spotted in sunny meadows and grassy clearings worldwide, what looks like one single bloom is actually a whole crowd of dozens of tiny flowers working together.',
        funFacts: [
          'Nature explorers love pressing these blooms inside heavy books to make greeting cards and bookmark treasures.',
          'Many blooms in this family track the sun from east to west across the sky like living solar dishes.',
          'When flowers fade, they often turn into fluffy parachute globes that launch seeds into the breeze like tiny gliders.',
        ],
        observationTips: [
          'Use a magnifying glass on the center disk: count how many mini star-flowers have opened today!',
          'Check back at dusk: watch how the outer petals curl inward to tuck the flower in for bed.',
        ],
        safetyNote:
            '🌿 Safe and fun to touch! Raw stems or milky sap can taste super bitter like a sour lemon, and watch out for prickly thistle spikes on some cousins.',
        rarity: rarity,
        rarityReason: 'A cheerful sunny bloom you can spot in grassy lawns and meadows.',
      );
    }

    // 3. ROSACEAE (Roses / Berries / Apple family)
    if (famLower.contains('rosac')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Voici $name — un membre enchanteur de la famille des roses, réputé pour ses 5 pétales en étoile et ses baies colorées ! 🌹',
          description:
              'Elle grimpe le long des haies de campagne et des lisières de bois. Ses fleurs parfumées se métamorphosent en fruits rouges ou baies savoureuses adorés des oiseaux.',
          funFacts: [
            'Avec un adulte, on peut préparer de délicieuses gelées parfumées ou des tisanes douces avec ses pétales séchés.',
            'Presque toutes les fleurs sauvages de cette famille ont exactement 5 pétales disposés en étoile parfaite !',
            'Ses tiges s\'équipent d\'épines en forme de crochets pour s\'accrocher et grimper vers la lumière.',
          ],
          observationTips: [
            'Compte les pétales d\'une fleur bien ouverte : tu devrais en trouver 5 tout doux comme du velours.',
            'Regarde la forme des épines le long de la tige sans appuyer : vois comme elles pointent vers le bas.',
          ],
          safetyNote:
              '⚠️ Aïe ! Attention aux petites épines qui accrochent vite les doigts. Ne croque jamais de baies sauvages sans l\'accord d\'un adulte compétent !',
          rarity: rarity,
          rarityReason: 'Décore les haies sauvages et les sous-bois de ses couleurs éclatantes.',
        );
      }
      return AiContent(
        introduction:
            'Meet $name — a charming member of the rose family famous for star-shaped blossoms and sweet autumn berries! 🌹',
        description:
            'Scrambling through countryside hedgerows and woodland borders, its five-petaled blossoms turn into vitamin-rich hips and berries that feed wild songbirds in autumn.',
        funFacts: [
          'Traditional herbalists make sweet floral teas and vitamin syrups from autumn rosehips with grown-up help.',
          'Wild blossoms in the rose family almost always show off exactly 5 delicate petals arranged in a neat little star!',
          'Curved prickles along the branches work like tiny mountain-climbing hooks to scramble toward the sun.',
        ],
        observationTips: [
          'Count the petals on an open bloom: verify the magic number 5! Check underneath for the little green star cup.',
          'Carefully trace the stems with your eyes to see how the protective prickles point downwards.',
        ],
        safetyNote:
            '⚠️ Mind the prickles! Sharp thorns love snatching clothes and scratching skin. Always ask an adult before picking or tasting wild berries.',
        rarity: rarity,
        rarityReason: 'Rambles along countryside trails and sunny woodland borders.',
      );
    }

    // 4. ARACEAE (Monstera / Philodendron / Arum)
    if (famLower.contains('arac') || sciLower.contains('monstera') || sciLower.contains('philodendron')) {
      if (isFrench) {
        return AiContent(
          introduction:
              'Bienvenue dans la jungle avec $name — une fascinante liane tropicale aux feuilles découpées comme un dessin animé ! 🌴',
          description:
              'Originaire des forêts chaudes tropicales, elle escalade les troncs d\'arbres géants grâce à de solides racines aériennes en forme de cordes.',
          funFacts: [
            'On adore couper une tige pour la faire raciner dans un bocal d\'eau et l\'offrir à un copain pour sa chambre !',
            'Ses fentes et fenêtres dans les feuilles permettent aux bourrasques de tempête de passer sans abîmer la plante.',
            'Ses racines aériennes absorbent la pluie et la brume directement dans l\'air de la jungle.',
          ],
          observationTips: [
            'Trace du regard le bord découpé des feuilles : compte combien de découpes ou de trous tu aperçois !',
            'Dépoussière délicatement la surface avec un chiffon doux humide pour lui redonner son éclat verni.',
          ],
          safetyNote:
              '🚫 Ne mets JAMAIS ces feuilles dans ta bouche ! Les croquer provoque une brûlure très piquante sur la langue comme des piqûres d\'ortie. On admire avec les yeux et loin des animaux.',
          rarity: rarity,
          rarityReason: 'Une liane tropicale spectaculaire qui transforme un salon en mini jungle !',
        );
      }
      return AiContent(
        introduction:
            'Step into the jungle with $name — an amazing tropical climber with cartoon-like cutout leaves! 🌴',
        description:
            'Hailing from warm tropical rainforests, it scrambles up giant jungle trees with rope-like aerial roots and brings vibrant jungle energy to living rooms.',
        funFacts: [
          'Plant lovers take baby stem cuttings in jars of water to grow new roots and gift green baby plants to friends!',
          'Natural splits in the foliage allow fierce jungle storms and tropical winds to blow through without tearing the leaves.',
          'Aerial roots act like moisture cables that drink morning raindrops straight out of humid air.',
        ],
        observationTips: [
          'Count the leaf splits or peek-a-boo holes on one mature leaf: each one is completely unique!',
          'Gently stroke the glossy surface: notice how water droplets slide off like a waterproof rain jacket.',
        ],
        safetyNote:
            '🚫 Do NOT put in your mouth! Chewing raw leaves makes your tongue and throat feel super spicy and tingly like a swarm of fire ants. Strictly admire with your eyes and keep away from pets.',
        rarity: rarity,
        rarityReason: 'A striking tropical climber that thrives in bright indoor spaces.',
      );
    }

    // 5. GENERAL ADAPTIVE FALLBACK (For any other plant family)
    if (isFrench) {
      return AiContent(
        introduction:
            'Fais la connaissance de $name — une super découverte végétale de la famille des $family ($scientificName) ! 🌿',
        description:
            'Évoluant dans son coin de nature favori, cette plante déploie des feuilles et des fleurs adaptées au climat local pour servir de refuge aux coccinelles et aux insectes amis.',
        funFacts: [
          'Les amoureux de la nature aiment observer ses détails uniques ou dessiner sa silhouette dans leur carnet d\'explorateur.',
          'La manière dont ses feuilles s\'attachent à la tige (face à face ou décalées) est comme sa carte d\'identité végétale secrète !',
          'Ses fleurs et ses feuilles fabriquent des parfums et des couleurs pour attirer les bons pollinisateurs.',
        ],
        observationTips: [
          'Caresse délicatement une feuille : est-elle toute lisse, douce comme du velours ou un peu rugueuse ?',
          'Compte les pétales d\'une fleur bien éclose et compare sa forme avec les fleurs voisines.',
        ],
        safetyNote:
            '🧤 Règle d\'or de l\'explorateur : Ne mets jamais une plante sauvage inconnue dans ta bouche — beaucoup sont très amères, piquantes ou toxiques pour le ventre. Lave-toi les mains après tes sorties !',
        rarity: rarity,
        rarityReason: 'Observée et célébrée dans son milieu naturel par un explorateur attentif !',
      );
    }

    return AiContent(
      introduction:
          'Say hello to $name — a captivating plant discovery from the $family family ($scientificName)! 🌿',
      description:
          'Thriving in its favorite outdoor habitat, this plant grows clever leaves and blossoms tailored to its local weather, offering shelter to visiting ladybugs and insects.',
      funFacts: [
        'Nature explorers love inspecting its leaf shapes and sketching its blossom patterns into their field notebooks.',
        'The way its leaves sprout along the stem — either alternating or in opposite pairs — is like a secret botanical fingerprint!',
        'Its colors and gentle scent guide helpful flying bugs straight to its flowers for lunch.',
      ],
      observationTips: [
        'Gently stroke a leaf with your finger: is the surface glossy, fuzzy like soft velvet, or finely ribbed with veins?',
        'Count the petals on an open bloom and notice how they catch the sunlight.',
      ],
      safetyNote:
          '🧤 Explorer golden rule: Never put unknown wild plants in your mouth — many taste horribly bitter, burning spicy, or can upset your tummy. Wash your hands after exploring nature!',
      rarity: rarity,
      rarityReason: 'Spotted and celebrated in its natural outdoor home!',
    );
  }
}
