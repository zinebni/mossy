import 'dart:ui' show Color;

/// Rarity tier of a plant discovery.
enum DiscoveryRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  /// Tolerant parsing for stored values and AI output: ignores casing, accents,
  /// punctuation and surrounding text noise; understands French labels.
  /// Anything unrecognised (or null) returns null — never throws.
  static DiscoveryRarity? tryParse(dynamic value) {
    if (value is! String) return null;
    var s = value.toLowerCase();
    const accents = {'é': 'e', 'è': 'e', 'ê': 'e', 'à': 'a', 'â': 'a', 'î': 'i', 'ô': 'o', 'û': 'u', 'ù': 'u', 'ç': 'c'};
    accents.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp(r'[^a-z ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    switch (s) {
      case 'common':
      case 'commun':
        return DiscoveryRarity.common;
      case 'uncommon':
      case 'peu commun':
        return DiscoveryRarity.uncommon;
      case 'rare':
        return DiscoveryRarity.rare;
      case 'epic':
      case 'epique':
        return DiscoveryRarity.epic;
      case 'legendary':
      case 'legendaire':
        return DiscoveryRarity.legendary;
    }
    return null;
  }

  /// Base XP for identifying any plant.
  static const int basePoints = 15;

  /// Extra XP on top of [basePoints].
  int get bonusPoints {
    switch (this) {
      case DiscoveryRarity.common:
        return 0;
      case DiscoveryRarity.uncommon:
        return 5;
      case DiscoveryRarity.rare:
        return 15;
      case DiscoveryRarity.epic:
        return 30;
      case DiscoveryRarity.legendary:
        return 60;
    }
  }

  /// Total XP awarded for saving a discovery of this tier.
  int get totalPoints => basePoints + bonusPoints;

  /// Rare, epic and legendary finds trigger the celebration.
  bool get isCelebratory => index >= DiscoveryRarity.rare.index;

  /// Uncommon and above get a visible badge (common stays clean).
  bool get showsBadge => index >= DiscoveryRarity.uncommon.index;

  String label(bool isFr) {
    switch (this) {
      case DiscoveryRarity.common:
        return isFr ? 'Commun' : 'Common';
      case DiscoveryRarity.uncommon:
        return isFr ? 'Peu commun' : 'Uncommon';
      case DiscoveryRarity.rare:
        return 'Rare';
      case DiscoveryRarity.epic:
        return isFr ? 'Épique' : 'Epic';
      case DiscoveryRarity.legendary:
        return isFr ? 'Légendaire' : 'Legendary';
    }
  }

  String get emoji {
    switch (this) {
      case DiscoveryRarity.common:
        return '🌱';
      case DiscoveryRarity.uncommon:
        return '🍃';
      case DiscoveryRarity.rare:
        return '💎';
      case DiscoveryRarity.epic:
        return '🔮';
      case DiscoveryRarity.legendary:
        return '👑';
    }
  }

  /// Main accent color of the tier.
  Color get color {
    switch (this) {
      case DiscoveryRarity.common:
        return const Color(0xFF8A9A86);
      case DiscoveryRarity.uncommon:
        return const Color(0xFF4FA55A);
      case DiscoveryRarity.rare:
        return const Color(0xFF3A8DDE);
      case DiscoveryRarity.epic:
        return const Color(0xFF9B5DE5);
      case DiscoveryRarity.legendary:
        return const Color(0xFFF2A81D);
    }
  }

  /// Soft tinted background for badges.
  Color get softColor => color.withAlpha(36);
}

/// Deterministic rarity assignment. Works fully offline and gives the same
/// result for the same species on every device, so old records without a
/// stored rarity can simply be recomputed.
class RarityEngine {
  RarityEngine._();

  /// Everyday species are always common.
  static const Set<String> _everydaySpecies = {
    'bellis perennis',
    'taraxacum officinale',
    'trifolium repens',
    'hedera helix',
    'plantago major',
    'poa annua',
    'urtica dioica',
  };

  /// Very widespread families cannot exceed "uncommon".
  static const Set<String> _widespreadFamilies = {
    'poaceae',
    'plantaginaceae',
  };

  /// Naturally striking / uncommon-to-see families start at "rare".
  static const Set<String> _treasureFamilies = {
    'orchidaceae',
    'droseraceae',
    'nepenthaceae',
    'sarraceniaceae',
    'cactaceae',
    'magnoliaceae',
    'paeoniaceae',
  };

  /// Simple, reliable tier for NEW discoveries when Gemini fails, times out or
  /// returns an invalid value: everyday species are common, everything else
  /// uncommon. Never rare+, so a failed lookup can't hand out surprise bonuses.
  static DiscoveryRarity safeFallback({required String scientificName}) {
    return _everydaySpecies.contains(scientificName.trim().toLowerCase())
        ? DiscoveryRarity.common
        : DiscoveryRarity.uncommon;
  }

  /// FNV-1a: stable across runs/platforms (unlike String.hashCode).
  static int _fnv(String s) {
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }

  static DiscoveryRarity assign({
    required String scientificName,
    String family = '',
  }) {
    final name = scientificName.trim().toLowerCase();
    final fam = family.trim().toLowerCase();
    if (name.isEmpty) return DiscoveryRarity.common;
    if (_everydaySpecies.contains(name)) return DiscoveryRarity.common;

    final bucket = _fnv(name) % 100;
    var tier = bucket < 50
        ? DiscoveryRarity.common
        : bucket < 78
            ? DiscoveryRarity.uncommon
            : bucket < 92
                ? DiscoveryRarity.rare
                : bucket < 98
                    ? DiscoveryRarity.epic
                    : DiscoveryRarity.legendary;

    if (_widespreadFamilies.contains(fam) &&
        tier.index > DiscoveryRarity.uncommon.index) {
      tier = DiscoveryRarity.uncommon;
    }
    if (_treasureFamilies.contains(fam) &&
        tier.index < DiscoveryRarity.rare.index) {
      tier = DiscoveryRarity.rare;
    }
    return tier;
  }
}
