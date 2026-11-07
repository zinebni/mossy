import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final discoveryStats = ref.watch(discoveryStatsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageGreen)),
            error: (e, _) => Center(child: Text('$e')),
            data: (profile) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.secondaryText),
                  onPressed: () => context.go('/settings'),
                ),
              ]),
              const SizedBox(height: 20),
              // Avatar + info
              MossyCard(
                child: Row(children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.sageGreen, width: 2.5),
                    ),
                    child: profile.avatarUrl != null
                        ? ClipOval(child: Image.network(profile.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36)))
                        : const Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(profile.username, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Explorer Level ${profile.explorerLevel}',
                        style: const TextStyle(color: AppColors.sageGreen, fontWeight: FontWeight.w600)),
                    if (authState.isDemoMode)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.butterYellow.withAlpha(60), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Demo Mode', style: TextStyle(fontSize: 11, color: AppColors.darkGreen)),
                      ),
                  ])),
                ]),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              // Level progress
              MossyCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Level ${profile.explorerLevel}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.sageGreen, fontSize: 16)),
                    const Spacer(),
                    Text('${profile.totalPoints} pts',
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: profile.levelProgress,
                      minHeight: 10,
                      backgroundColor: AppColors.mintGreen.withAlpha(80),
                      color: AppColors.sageGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${profile.pointsToNextLevel} pts to level ${profile.explorerLevel + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
                ]),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 16),
              // Stats grid
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.2,
                children: [
                  _StatCard(icon: Icons.eco_rounded, value: '${discoveryStats.totalDiscoveries}', label: 'Discoveries'),
                  _StatCard(icon: Icons.star_rounded, value: '${profile.totalPoints}', label: 'Total Points'),
                  _StatCard(icon: Icons.explore_rounded, value: '${discoveryStats.distinctFamilies}', label: 'Plant Families'),
                  _StatCard(icon: Icons.favorite_rounded, value: '${discoveryStats.favoriteCount}', label: 'Favourites'),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),
              Text('Achievements', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              achievementsAsync.when(
                loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageGreen))),
                error: (e, _) => Text('$e'),
                data: (achievements) => achievements.isEmpty
                    ? const Text('No achievements yet. Start exploring!', style: TextStyle(color: AppColors.secondaryText))
                    : GridView.count(
                        crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.85,
                        children: achievements.take(9).map((a) => _AchievementBadge(achievement: a)).toList(),
                      ),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 20),
              MossyCard(
                child: Row(children: [
                  const Icon(Icons.map_outlined, color: AppColors.sageGreen),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Discovery Map', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text('See where you found your plants', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
                ]),
                onTap: () => context.go('/map'),
              ).animate().fadeIn(delay: 300.ms),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)]),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(children: [
        Icon(icon, color: AppColors.sageGreen, size: 22),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.darkGreen)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
        ]),
      ]),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final dynamic achievement;
  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked as bool? ?? false;
    return Container(
      decoration: BoxDecoration(
        color: unlocked ? AppColors.mintGreen.withAlpha(60) : AppColors.disabledBackground.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? AppColors.sageGreen.withAlpha(80) : AppColors.border, width: 1.5),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: unlocked ? AppColors.sageGreen.withAlpha(30) : AppColors.disabledBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
            color: unlocked ? AppColors.sageGreen : AppColors.mutedText, size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          achievement.name as String? ?? '',
          textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.darkGreen : AppColors.mutedText),
        ),
      ]),
    );
  }
}
