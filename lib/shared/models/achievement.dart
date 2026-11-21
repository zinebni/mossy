import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;
  final String category;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.maxProgress = 1,
    this.category = 'General',
  });

  double get progressPercentage {
    if (maxProgress <= 0) return 0.0;
    return (progress / maxProgress).clamp(0.0, 1.0);
  }

  /// French localized titles for all standard achievements.
  static const Map<String, String> _frTitles = {
    'ach-first-discovery': 'Première Découverte',
    'ach-curious-explorer': 'Explorateur Curieux',
    'ach-flower-collector': 'Collectionneur de Fleurs',
    'ach-nature-enthusiast': 'Passionné de Nature',
    'ach-botanical-expert': 'Expert Botanique',
    'ach-adventure-seeker': 'Aventurier en Herbe',
    'ach-mission-master': 'Maître des Missions',
    'ach-garden-keeper': 'Gardien du Jardin',
    'ach-master-gardener': 'Maître Jardinier',
    'ach-botanist': 'Apprenti Botaniste',
  };

  /// French localized descriptions for all standard achievements.
  static const Map<String, String> _frDescriptions = {
    'ach-first-discovery': 'Enregistrez votre première découverte botanique dans le carnet.',
    'ach-curious-explorer': 'Découvrez et identifiez 5 spécimens de plantes différents.',
    'ach-flower-collector': 'Rassemblez 10 découvertes végétales dans votre carnet nature.',
    'ach-nature-enthusiast': 'Atteignez le cap remarquable de 25 découvertes de plantes.',
    'ach-botanical-expert': 'Constituez une collection magistrale de 50 découvertes de plantes.',
    'ach-adventure-seeker': 'Accomplissez 3 missions d\'exploration ou quêtes nature.',
    'ach-mission-master': 'Accomplissez avec succès 15 défis et missions nature.',
    'ach-garden-keeper': 'Développez votre sanctuaire virtuel jusqu\'au niveau 2.',
    'ach-master-gardener': 'Nourrissez votre sanctuaire végétal jusqu\'au niveau 5.',
    'ach-botanist': 'Identifiez des plantes issues de 3 familles botaniques différentes.',
  };

  /// Returns localized title based on active language.
  String localizedTitle([bool isFr = false]) {
    if (isFr && _frTitles.containsKey(id)) {
      return _frTitles[id]!;
    }
    return title;
  }

  /// Returns localized description based on active language.
  String localizedDescription([bool isFr = false]) {
    if (isFr && _frDescriptions.containsKey(id)) {
      return _frDescriptions[id]!;
    }
    return description;
  }

  /// Kid-friendly emoji for celebration dialogs.
  String get emoji {
    switch (id) {
      case 'ach-first-discovery': return '🌱';
      case 'ach-curious-explorer': return '🧭';
      case 'ach-flower-collector': return '🌸';
      case 'ach-nature-enthusiast': return '🌲';
      case 'ach-botanical-expert': return '🌳';
      case 'ach-adventure-seeker': return '🎒';
      case 'ach-mission-master': return '🎖️';
      case 'ach-garden-keeper': return '🏡';
      case 'ach-master-gardener': return '🌺';
      case 'ach-botanist': return '🔬';
      default: return '🏆';
    }
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    int? maxProgress,
    String? category,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
      category: category ?? this.category,
    );
  }
}
