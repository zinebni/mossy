import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mascot_with_accessory.dart';
import 'widgets/garden_painter.dart';

class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardenAsync = ref.watch(gardenStateProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: gardenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageGreen)),
        error: (e, _) => Center(child: Text('$e')),
        data: (garden) => CustomScrollView(slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: false,
            backgroundColor: AppColors.mintGreen.withAlpha(60),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(children: [
                // Garden canvas
                Positioned.fill(
                  child: CustomPaint(painter: GardenPainter(level: garden.gardenLevel)),
                ),
                // Gradient overlay at bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.cream.withAlpha(230)]),
                    ),
                  ),
                ),
                // Level badge
                Positioned(top: 16, right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: AppColors.sageGreen, borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Level ${garden.gardenLevel}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your Garden', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                    Text(garden.stageName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText)),
                  ]),
                ),
                const MascotWithAccessory(
                  expression: MascotExpression.happy,
                  accessory: MascotAccessory.wateringCan,
                  size: 70, animate: false,
                ),
              ]),
              const SizedBox(height: 20),
              MossyCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Garden Progress', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('Level ${garden.gardenLevel}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.sageGreen)),
                    const Spacer(),
                    Text('Level ${garden.gardenLevel + 1}', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: garden.progressToNextLevel,
                      minHeight: 10,
                      backgroundColor: AppColors.mintGreen.withAlpha(80),
                      color: AppColors.sageGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${(garden.progressToNextLevel * 100).toStringAsFixed(0)}% to next level',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
                ]),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              MossyCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.sageGreen, size: 18),
                    const SizedBox(width: 8),
                    Text('How to Grow Your Garden', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 10),
                  for (final tip in [
                    '🌱  Identify new plants (+15 pts each)',
                    '🎯  Complete adventures (+10–50 pts)',
                    '🏆  Unlock achievements',
                    '⭐  Your garden grows with every discovery!',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(tip, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText)),
                    ),
                ]),
              ).animate().fadeIn(delay: 300.ms),
              if (garden.unlockedItems.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Unlocked Items', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: garden.unlockedItems.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.mintGreen.withAlpha(80), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.eco_rounded, size: 14, color: AppColors.sageGreen),
                      const SizedBox(width: 4),
                      Text(item, style: const TextStyle(fontSize: 12, color: AppColors.darkGreen)),
                    ]),
                  )).toList(),
                ),
              ],
            ])),
          ),
        ]),
      ),
    );
  }
}
