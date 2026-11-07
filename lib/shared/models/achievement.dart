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
