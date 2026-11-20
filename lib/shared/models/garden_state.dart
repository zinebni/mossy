import 'dart:math' as math;

/// Represents the state of a user's virtual garden.
class GardenState {
  static const int minLevel = 1;
  static const int maxLevel = 10;

  /// Points thresholds required to reach each garden level (index = level - 1).
  static const List<int> _levelThresholds = [
    0, 50, 150, 300, 500, 750, 1050, 1400, 1800, 2250,
  ];

  /// Returns the cumulative point threshold required to unlock [level].
  static int pointsForLevel(int level) {
    final idx = (level - 1).clamp(0, _levelThresholds.length - 1);
    return _levelThresholds[idx];
  }

  /// Calculates garden level (1 to 10) directly from points.
  static int calculateLevel(int points) {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (points >= _levelThresholds[i]) {
        return (i + 1).clamp(minLevel, maxLevel);
      }
    }
    return minLevel;
  }

  /// Decorative botanical items unlocked per garden level.
  static const Map<int, List<String>> levelItemUnlocks = {
    1: ['tiny_sprout', 'wooden_sign'],
    2: ['moss_carpet', 'stepping_stones'],
    3: ['wildflower_patch', 'stone_birdbath'],
    4: ['fern_cluster', 'wooden_bench'],
    5: ['butterfly_bush', 'wind_chimes'],
    6: ['flowering_shrub', 'cobblestone_path'],
    7: ['sunlit_pond', 'lantern_post'],
    8: ['wooden_bridge', 'hummingbird_feeder'],
    9: ['ancient_oak_canopy', 'firefly_glow'],
    10: ['grand_fountain', 'mossy_botanical_shrine'],
  };

  /// Returns all cumulative items unlocked for [level].
  static List<String> defaultUnlockedItemsForLevel(int level) {
    final clamped = level.clamp(minLevel, maxLevel);
    final items = <String>{};
    for (int l = 1; l <= clamped; l++) {
      if (levelItemUnlocks.containsKey(l)) {
        items.addAll(levelItemUnlocks[l]!);
      }
    }
    return items.toList();
  }

  /// Comprehensive mapping of item IDs to English names.
  static const Map<String, String> _enNames = {
    'tiny_sprout': 'Tiny Sprout 🌱',
    'wooden_sign': 'Wooden Sign 🪵',
    'moss_patch_starter': 'Moss Patch 🌿',
    'moss_carpet': 'Moss Carpet 🌿',
    'stepping_stones': 'Stepping Stones 🪨',
    'wildflower_patch': 'Wildflowers 🌸',
    'stone_birdbath': 'Stone Birdbath ⛲',
    'fern_cluster': 'Fern Cluster 🪴',
    'wooden_bench': 'Cozy Bench 🪑',
    'butterfly_bush': 'Butterfly Bush 🦋',
    'wind_chimes': 'Wind Chimes 🎐',
    'flowering_shrub': 'Flowering Shrub 🌺',
    'cobblestone_path': 'Cobblestone Path 🛤️',
    'sunlit_pond': 'Sunlit Pond 💧',
    'lantern_post': 'Lantern Post 🏮',
    'wooden_bridge': 'Wooden Bridge 🌉',
    'hummingbird_feeder': 'Hummingbird Feeder 🕊️',
    'ancient_oak_canopy': 'Ancient Oak Canopy 🌳',
    'firefly_glow': 'Firefly Glow ✨',
    'grand_fountain': 'Grand Fountain ⛲',
    'mossy_botanical_shrine': 'Botanical Shrine 🏛️',
    'moss_stone': 'Moss Stone 🪨',
    'stone_path': 'Stone Path 🪨',
    'flower_arch': 'Flower Arch 🌹',
    'sunflower_patch': 'Sunflower Patch 🌻',
  };

  /// Comprehensive mapping of item IDs to French names.
  static const Map<String, String> _frNames = {
    'tiny_sprout': 'Petite pousse 🌱',
    'wooden_sign': 'Panneau en bois 🪵',
    'moss_patch_starter': 'Carré de mousse 🌿',
    'moss_carpet': 'Tapis de mousse 🌿',
    'stepping_stones': 'Pas japonais 🪨',
    'wildflower_patch': 'Fleurs sauvages 🌸',
    'stone_birdbath': 'Bain d\'oiseaux ⛲',
    'fern_cluster': 'Bosquet de fougères 🪴',
    'wooden_bench': 'Banc en bois 🪑',
    'butterfly_bush': 'Arbuste à papillons 🦋',
    'wind_chimes': 'Carillon éolien 🎐',
    'flowering_shrub': 'Arbuste fleuri 🌺',
    'cobblestone_path': 'Chemin pavé 🛤️',
    'sunlit_pond': 'Bassin ensoleillé 💧',
    'lantern_post': 'Lanterne de jardin 🏮',
    'wooden_bridge': 'Ponton en bois 🌉',
    'hummingbird_feeder': 'Mangeoire d\'oiseaux 🕊️',
    'ancient_oak_canopy': 'Grand chêne vénérable 🌳',
    'firefly_glow': 'Lueur de lucioles ✨',
    'grand_fountain': 'Grande fontaine ⛲',
    'mossy_botanical_shrine': 'Sanctuaire botanique 🏛️',
    'moss_stone': 'Pierre de mousse 🪨',
    'stone_path': 'Sentier de pierres 🪨',
    'flower_arch': 'Arche fleurie 🌹',
    'sunflower_patch': 'Champ de tournesols 🌻',
  };

  /// Normalizes item identifiers (handling spaces, dashes, emojis, and reverse display names).
  static String normalizeItemId(String raw) {
    var key = raw.trim().toLowerCase();
    // Strip emojis
    key = key.replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true), '').trim();
    final slug = key.replaceAll(' ', '_').replaceAll('-', '_');

    if (slug == 'cozy_bench') return 'wooden_bench';

    if (_frNames.containsKey(slug) || _enNames.containsKey(slug)) {
      return slug;
    }

    // Reverse lookup matching by normalized slug
    for (final entry in _enNames.entries) {
      final cleanEnSlug = entry.value
          .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true), '')
          .trim()
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_');
      if (cleanEnSlug == slug) return entry.key;
    }
    for (final entry in _frNames.entries) {
      final cleanFrSlug = entry.value
          .replaceAll(RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true), '')
          .trim()
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('-', '_');
      if (cleanFrSlug == slug) return entry.key;
    }
    return slug;
  }

  /// Format item IDs into kid-friendly readable labels.
  static String formatItemName(String itemId, [bool isFr = false]) {
    final normId = normalizeItemId(itemId);
    if (isFr && _frNames.containsKey(normId)) return _frNames[normId]!;
    if (!isFr && _enNames.containsKey(normId)) return _enNames[normId]!;
    if (_frNames.containsKey(normId) && isFr) return _frNames[normId]!;
    if (_enNames.containsKey(normId)) return _enNames[normId]!;

    return normId
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  /// Kid-friendly descriptions for unlocked items in English and French.
  static String formatItemDescription(String itemId, [bool isFr = false]) {
    final normId = normalizeItemId(itemId);
    const enDescriptions = {
      'tiny_sprout': 'A cheerful little green sprout stretching happily toward the sun.',
      'wooden_sign': 'A carved rustic wooden sign welcoming visitors to your haven.',
      'moss_patch_starter': 'A velvety green carpet that keeps the earth moist and cozy.',
      'moss_carpet': 'A plush emerald moss carpet perfect for resting and looking closely.',
      'stepping_stones': 'Smooth round stones creating a fun path to skip along.',
      'wildflower_patch': 'Bright colorful wildflowers dancing and nodding in the gentle breeze.',
      'stone_birdbath': 'A cool granite birdbath where robins and finches splash happily.',
      'fern_cluster': 'Feathery green ferns that unfurl like playful forest spirals.',
      'wooden_bench': 'A cozy cedar bench where Mossy loves to sit and observe nature.',
      'butterfly_bush': 'Fragrant purple flower clusters that attract fluttery butterflies.',
      'wind_chimes': 'Melodic chimes that sing soft, peaceful notes with every breeze.',
      'flowering_shrub': 'A lush bush covered in vibrant blossoms and sweet sweet nectar.',
      'cobblestone_path': 'A timeless pebble trail leading deep into the secret garden.',
      'sunlit_pond': 'A sparkling pond with clear water and floating lotus pads.',
      'lantern_post': 'A warm lantern post glowing softly during evening explorations.',
      'wooden_bridge': 'An arched footbridge crossing gracefully over the crystal waters.',
      'hummingbird_feeder': 'A nectar feeder welcoming speedy, sparkling hummingbirds.',
      'ancient_oak_canopy': 'A grand guardian oak spreading sheltering leafy branches.',
      'firefly_glow': 'Magical golden fireflies twinkling like fallen stars among the leaves.',
      'grand_fountain': 'A breathtaking stone fountain spraying dancing water into the air.',
      'mossy_botanical_shrine': 'The legendary centerpiece celebrating your complete nature mastery.',
      'moss_stone': 'A tranquil boulder covered in soft emerald moss cushions.',
      'sunflower_patch': 'Tall, smiling sunflowers following the golden daylight all day long.',
      'stone_path': 'Smooth river stones paving a gentle garden walkway.',
      'flower_arch': 'A romantic flowering trellis covered in sweet blooming climbing roses.',
    };
    const frDescriptions = {
      'tiny_sprout': 'Une petite pousse verte joyeuse qui s\'étire vers la lumière.',
      'wooden_sign': 'Un panneau en bois rustique qui accueille les explorateurs.',
      'moss_patch_starter': 'Un velouté de mousse verte gardant le sol frais et douillet.',
      'moss_carpet': 'Un tapis d\'émeraude moelleux parfait pour observer la nature de près.',
      'stepping_stones': 'De doux pas de pierre invitant à sautiller le long du chemin.',
      'wildflower_patch': 'Des fleurs des champs colorées dansant au gré de la brise légère.',
      'stone_birdbath': 'Un bassin en granit où les petits oiseaux viennent s\'abreuver.',
      'fern_cluster': 'De jolies fougères ondulantes déroulant leurs spirales vertes.',
      'wooden_bench': 'Un banc en cèdre confortable où Mossy adore se poser et rêver.',
      'butterfly_bush': 'Un buisson parfumé aux grappes de fleurs attirant les papillons.',
      'wind_chimes': 'Un carillon éolien tintant doucement au souffle du vent.',
      'flowering_shrub': 'Un arbuste étincelant de pétales vifs et de doux parfums.',
      'cobblestone_path': 'Un sentier pavé plein de charme menant au cœur du sanctuaire.',
      'sunlit_pond': 'Un bassin étincelant avec des nénuphars et une eau cristalline.',
      'lantern_post': 'Une lanterne chaleureuse qui éclaire les découvertes crépusculaires.',
      'wooden_bridge': 'Une passerelle en arche enjambant le ruisseau avec grâce.',
      'hummingbird_feeder': 'Une mangeoire fleurie accueillant les oiseaux mouches scintillants.',
      'ancient_oak_canopy': 'Un grand chêne protecteur qui murmure les secrets de la forêt.',
      'firefly_glow': 'Des lucioles dorées dansant comme des étoiles filantes dans la nuit.',
      'grand_fountain': 'Une magnifique fontaine sculptée faisant jaillir une eau pure et vive.',
      'mossy_botanical_shrine': 'Le cœur sacré de la nature célébrant vos exploits d\'explorateur.',
      'moss_stone': 'Un rocher paisible garni d\'un doux velours de mousse verdoyante.',
      'sunflower_patch': 'De grands tournesols souriants suivant fidèlement le soleil.',
      'stone_path': 'Des pierres lisses traçant une belle promenade dans le jardin.',
      'flower_arch': 'Une arche fleurie couverte de roses grimpantes très parfumées.',
    };
    if (isFr && frDescriptions.containsKey(normId)) return frDescriptions[normId]!;
    if (enDescriptions.containsKey(normId)) return enDescriptions[normId]!;
    return isFr
        ? 'Un merveilleux élément décoratif pour votre sanctuaire naturel.'
        : 'A wonderful botanical element that enriches your nature sanctuary.';
  }

  /// Returns the emoji representing this unlocked item.
  static String getItemEmoji(String itemId) {
    final normId = normalizeItemId(itemId);
    const emojis = {
      'tiny_sprout': '🌱',
      'wooden_sign': '🪵',
      'moss_patch_starter': '🌿',
      'moss_carpet': '🌿',
      'stepping_stones': '🪨',
      'wildflower_patch': '🌸',
      'stone_birdbath': '⛲',
      'fern_cluster': '🪴',
      'wooden_bench': '🪑',
      'butterfly_bush': '🦋',
      'wind_chimes': '🎐',
      'flowering_shrub': '🌺',
      'cobblestone_path': '🛤️',
      'sunlit_pond': '💧',
      'lantern_post': '🏮',
      'wooden_bridge': '🌉',
      'hummingbird_feeder': '🕊️',
      'ancient_oak_canopy': '🌳',
      'firefly_glow': '✨',
      'grand_fountain': '⛲',
      'mossy_botanical_shrine': '🏛️',
      'moss_stone': '🪨',
      'sunflower_patch': '🌻',
      'stone_path': '🪨',
      'flower_arch': '🌹',
    };
    return emojis[normId] ?? '🌿';
  }

  /// Returns the level required to unlock this item.
  static int getItemLevel(String itemId) {
    final normId = normalizeItemId(itemId);
    for (final entry in levelItemUnlocks.entries) {
      if (entry.value.contains(normId)) return entry.key;
    }
    return 1;
  }

  final String userId;
  final int gardenLevel; // 1 to 10
  final int totalPoints;
  final List<String> unlockedItems;
  final DateTime updatedAt;

  GardenState({
    required this.userId,
    this.gardenLevel = 1,
    this.totalPoints = 0,
    this.unlockedItems = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  String get stageName {
    switch (gardenLevel) {
      case 1: return 'Empty Plot';
      case 2: return 'Moss Patch';
      case 3: return 'First Sprouts';
      case 4: return 'Flower Garden';
      case 5: return 'Wild Meadow';
      case 6: return 'Woodland Edge';
      case 7: return 'Growing Forest';
      case 8: return 'Nature Sanctuary';
      case 9: return 'Lush Paradise';
      case 10: return 'Botanical Wonderland';
      default: return 'Garden';
    }
  }

  /// Accurate progress 0.0–1.0 towards next garden level.
  double get progressToNextLevel {
    if (gardenLevel >= maxLevel) return 1.0;
    final start = pointsForLevel(gardenLevel);
    final end = pointsForLevel(gardenLevel + 1);
    if (end <= start) return 1.0;
    final currentPts = totalPoints >= start ? totalPoints : start;
    return ((currentPts - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Points remaining until next garden level.
  int get pointsToNextLevel {
    if (gardenLevel >= maxLevel) return 0;
    final end = pointsForLevel(gardenLevel + 1);
    return (end - totalPoints).clamp(0, 99999);
  }

  GardenState copyWith({
    String? userId,
    int? gardenLevel,
    int? totalPoints,
    List<String>? unlockedItems,
    DateTime? updatedAt,
  }) {
    return GardenState(
      userId: userId ?? this.userId,
      gardenLevel: gardenLevel ?? this.gardenLevel,
      totalPoints: totalPoints ?? this.totalPoints,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GardenState.fromJson(Map<String, dynamic> json) {
    final rawLevel = json['garden_level'] as int? ?? 1;
    final pts = (json['total_points'] as int?) ?? 0;
    final calculated = pts > 0 ? calculateLevel(pts) : rawLevel;
    final effectiveLevel = math.max(rawLevel, calculated).clamp(minLevel, maxLevel);
    final rawItems = (json['unlocked_items'] as List?)
        ?.map((e) => e.toString())
        .toList() ?? <String>[];
    final allItems = <String>{
      ...defaultUnlockedItemsForLevel(effectiveLevel),
      ...rawItems,
    }.toList();

    return GardenState(
      userId: json['user_id'] as String? ?? '',
      gardenLevel: effectiveLevel,
      totalPoints: pts > 0 ? pts : pointsForLevel(effectiveLevel),
      unlockedItems: allItems,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'garden_level': gardenLevel,
        'total_points': totalPoints,
        'unlocked_items': unlockedItems,
        'updated_at': updatedAt.toIso8601String(),
      };
}
