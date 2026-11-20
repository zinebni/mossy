import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/achievement.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/celebration_dialogs.dart';
import '../../../services/sound_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final profileAsync = ref.watch(userProfileProvider);
    final achievementsAsync = ref.watch(achievementsProvider);
    final discoveryStats = ref.watch(discoveryStatsProvider);
    final authState = ref.watch(authProvider);

    // Eagerly resolve profile from userProfileProvider or fallback directly to active auth state
    final profile = profileAsync.valueOrNull ?? authState.user;

    ref.listen<Achievement?>(latestBadgeAwardProvider, (prev, next) {
      if (next != null) {
        BadgeUnlockAlert.show(context, achievement: next, isFr: isFr);
      }
    });

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: always rendered and responsive regardless of loading state
                _buildTopBar(context, l10n),
                const SizedBox(height: 20),

                if (profile == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.sageGreen),
                          const SizedBox(height: 16),
                          Text(
                            isFr ? 'Chargement du profil...' : 'Loading profile...',
                            style: const TextStyle(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // 1. Avatar + Username + Explorer Level
                  _buildAvatarCard(context, profile, l10n),
                  const SizedBox(height: 16),

                  // 2. Level Progress Bar
                  _buildLevelCard(context, profile, isFr),
                  const SizedBox(height: 16),

                  // 3. Stats Grid
                  _buildStatsGrid(l10n, profile, discoveryStats, isFr),
                  const SizedBox(height: 20),

                  // 4. Achievements Section
                  Text(
                    l10n?.achievements ?? 'Achievements',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  achievementsAsync.when(
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.sageGreen,
                        ),
                      ),
                    ),
                    error: (e, _) => Text('$e'),
                    data: (achievements) => achievements.isEmpty
                        ? Text(
                            isFr
                                ? 'Aucun succès pour le moment. Commencez à explorer !'
                                : 'No achievements yet. Start exploring!',
                            style: const TextStyle(color: AppColors.secondaryText),
                          )
                        : GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                            children: achievements
                                .take(9)
                                .map((a) => _AchievementBadge(achievement: a, isFr: isFr))
                                .toList(),
                          ),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 20),

                  // 5. Discovery Map Shortcut
                  MossyCard(
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, color: AppColors.sageGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.discoveryMap ?? 'Discovery Map',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                isFr
                                    ? 'Découvrez où vous avez trouvé vos plantes'
                                    : 'See where you found your plants',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.mutedText),
                      ],
                    ),
                    onTap: () => context.push('/map'),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations? l10n) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        const SizedBox(width: 4),
        Text(
          l10n?.profile ?? 'Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.darkGreen,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: AppColors.secondaryText),
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }

  Widget _buildAvatarCard(BuildContext context, UserProfile profile, AppLocalizations? l10n) {
    final avatarUrl = profile.avatarUrl;
    final hasValidHttpAvatar =
        avatarUrl != null && avatarUrl.isNotEmpty && avatarUrl.startsWith('http');

    return MossyCard(
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.mintGreen,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.sageGreen, width: 2.5),
            ),
            child: hasValidHttpAvatar
                ? ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        color: AppColors.sageGreen,
                        size: 36,
                      ),
                    ),
                  )
                : const Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.username,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  l10n?.explorerLevel(profile.explorerLevel) ??
                      'Explorer Level ${profile.explorerLevel}',
                  style: const TextStyle(
                    color: AppColors.sageGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildLevelCard(BuildContext context, UserProfile profile, bool isFr) {
    return MossyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${isFr ? 'Niveau' : 'Level'} ${profile.explorerLevel}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.sageGreen,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${profile.totalPoints} pts',
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
            ],
          ),
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
          Text(
            '${profile.pointsToNextLevel} ${isFr ? 'pts vers le niveau' : 'pts to level'} ${profile.explorerLevel + 1}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.mutedText),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildStatsGrid(AppLocalizations? l10n, UserProfile profile,
      DiscoveryStats discoveryStats, bool isFr) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _StatCard(
          icon: Icons.eco_rounded,
          value: '${discoveryStats.totalDiscoveries}',
          label: l10n?.totalDiscoveries ?? 'Discoveries',
        ),
        _StatCard(
          icon: Icons.star_rounded,
          value: '${profile.totalPoints}',
          label: l10n?.totalPoints ?? 'Total Points',
        ),
        _StatCard(
          icon: Icons.explore_rounded,
          value: '${discoveryStats.distinctFamilies}',
          label: isFr ? 'Familles de plantes' : 'Plant Families',
        ),
        _StatCard(
          icon: Icons.favorite_rounded,
          value: '${discoveryStats.favoriteCount}',
          label: l10n?.favorites ?? 'Favourites',
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.sageGreen, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.darkGreen,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isFr;

  const _AchievementBadge({required this.achievement, this.isFr = false});

  void _handleTap(BuildContext context) {
    if (achievement.isUnlocked) {
      BadgeUnlockAlert.show(context, achievement: achievement, isFr: isFr);
    } else {
      SoundService.instance.playGardenTapSound();
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.disabledBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.mutedText, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                achievement.localizedTitle(isFr),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                achievement.localizedDescription(isFr),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFr ? 'Continuez d\'explorer pour débloquer ce badge ! 🌿' : 'Keep exploring nature to unlock this badge! 🌿',
                style: const TextStyle(
                  color: AppColors.sageGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(isFr ? 'Compris !' : 'Got it!', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final title = achievement.localizedTitle(isFr);

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: unlocked
              ? AppColors.mintGreen.withAlpha(60)
              : AppColors.disabledBackground.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.sageGreen.withAlpha(80)
                : AppColors.border,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: unlocked
                    ? AppColors.sageGreen.withAlpha(30)
                    : AppColors.disabledBackground,
                shape: BoxShape.circle,
              ),
              child: unlocked
                  ? Center(child: Text(achievement.emoji, style: const TextStyle(fontSize: 22)))
                  : const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.mutedText,
                      size: 24,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: unlocked ? AppColors.darkGreen : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
