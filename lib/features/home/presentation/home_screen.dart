import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/models/mission.dart';
import '../../../shared/models/user_mission.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mascot_with_accessory.dart';
import '../../../shared/widgets/mascot/mossy_mascot.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _factIndex = 0;

  static const _factsEn = [
    'Mosses have survived on Earth for over 450 million years without true roots!',
    'Trees communicate with each other through subterranean fungal mycelium networks.',
    'Dandelions open their petals with morning light and tuck themselves in at sundown.',
    'Ferns existed long before flowering plants—and even before the dinosaurs!',
    'Look closely at sidewalk cracks: tough pioneer mosses create micro-soil for other seedlings.',
    'Clover leaves fold upward at dusk in a botanical sleep movement called nyctinasty.',
  ];

  static const _factsFr = [
    'Les mousses survivent sur Terre depuis plus de 450 millions d\'années sans véritables racines !',
    'Les arbres communiquent entre eux via des réseaux souterrains de mycelium fongique.',
    'Les pissenlits ouvrent leurs pétales avec la lumière du matin et se referment au coucher du soleil.',
    'Les fougères existaient bien avant les plantes à fleurs — et même avant les dinosaures !',
    'Regardez attentivement les fissures des trottoirs : des mousses pionnières créent du micro-sol pour d\'autres plantes.',
    'Les feuilles de trèfle se plient vers le haut au crépuscule lors d\'un mouvement botanique appelé nyctinastie.',
  ];

  List<String> _getFacts(bool isFr) => isFr ? _factsFr : _factsEn;

  String _getTimeGreeting(AppLocalizations? l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n?.goodMorning ?? 'Good morning,';
    if (hour < 17) return l10n?.goodAfternoon ?? 'Good afternoon,';
    return l10n?.goodEvening ?? 'Good evening,';
  }

  void _nextFact(bool isFr) {
    setState(() {
      _factIndex = (_factIndex + 1) % _getFacts(isFr).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final facts = _getFacts(isFr);

    final profileAsync = ref.watch(userProfileProvider);
    final discoveriesAsync = ref.watch(discoveriesProvider);
    final missionsAsync = ref.watch(missionsProvider);
    final gardenAsync = ref.watch(gardenStateProvider);
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: profileAsync.when(
          data: (profile) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTimeGreeting(l10n),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              Text(
                profile.username.isNotEmpty
                    ? profile.username
                    : (isFr ? 'Explorateur Nature' : 'Nature Explorer'),
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
          loading: () => Text(
            'Mossy',
            style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
          ),
          error: (_, __) => Text(
            'Mossy',
            style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
          ),
        ),
        actions: [
          profileAsync.maybeWhen(
            data: (profile) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.butterYellow.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.butterYellow),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFC4971A)),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.totalPoints} pts',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          profileAsync.maybeWhen(
            data: (profile) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sageGreen),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded, size: 14, color: AppColors.sageGreen),
                  const SizedBox(width: 4),
                  Text(
                    'Lvl ${profile.explorerLevel}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
                  ),
                ],
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.darkGreen),
            tooltip: l10n?.profile ?? 'Profile',
            onPressed: () => context.push(AppRouter.profilePath),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.sageGreen,
          backgroundColor: Colors.white,
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(discoveriesProvider);
            ref.invalidate(missionsProvider);
            ref.invalidate(gardenStateProvider);
            ref.invalidate(achievementsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMascotWisdomBanner(l10n, isFr, facts),
                const SizedBox(height: 18),
                _buildExploreHeroCard(context, l10n, isFr),
                const SizedBox(height: 24),
                _buildDailyAdventureSection(context, l10n, isFr, missionsAsync),
                const SizedBox(height: 24),
                _buildRecentDiscoveriesSection(context, l10n, isFr, discoveriesAsync),
                const SizedBox(height: 24),
                _buildGardenPreviewSection(context, l10n, isFr, gardenAsync),
                const SizedBox(height: 24),
                _buildAchievementSummarySection(context, l10n, isFr, achievementsAsync),
                const SizedBox(height: 24),
                _buildQuickLinksRow(context, l10n, isFr),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 1. Mascot & Wisdom Card ───────────────────────────────────────────────
  Widget _buildMascotWisdomBanner(AppLocalizations? l10n, bool isFr, List<String> facts) {
    return GestureDetector(
      onTap: () => _nextFact(isFr),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCream,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            const MossyMascot(expression: MascotExpression.happy, size: 80),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.mintGreen, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          isFr ? 'Notes de terrain de Mossy' : 'Mossy\'s Field Notes',
                          style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.deepSage),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.mutedText),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    facts[_factIndex % facts.length],
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGreen, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms);
  }

  // ─── 2. Explore Hero Card ──────────────────────────────────────────────────
  Widget _buildExploreHeroCard(BuildContext context, AppLocalizations? l10n, bool isFr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.sageGreen, Color(0xFF6B8762)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.sageGreen.withAlpha(80), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFr ? 'Prêt à explorer ?' : 'Ready to explore?',
                      style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.mintGreen),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFr ? 'Regardez de près.\nDécouvrez plus.' : 'Look closer.\nDiscover more.',
                      style: GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.15),
                    ),
                  ],
                ),
              ),
              const MascotWithAccessory(
                expression: MascotExpression.searching,
                accessory: MascotAccessory.magnifyingGlass,
                size: 80,
                animate: false,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isFr
                ? 'Photographiez n\'importe quelle fleur, feuille ou arbre pour identifier l\'espèce et découvrir son histoire botanique.'
                : 'Photograph any flower, leaf, or tree to identify species and unlock botanical lore.',
            style: GoogleFonts.nunito(fontSize: 13, color: Colors.white.withAlpha(230), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go(AppRouter.explorePath),
              icon: const Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.darkGreen),
              label: Text(
                l10n?.identifyPlant ?? 'Identify a Plant',
                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.butterYellow,
                foregroundColor: AppColors.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.97, 0.97));
  }

  // ─── 3. Daily Adventure Spotlight ──────────────────────────────────────────
  Widget _buildDailyAdventureSection(
    BuildContext context,
    AppLocalizations? l10n,
    bool isFr,
    AsyncValue<List<UserMission>> missionsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: l10n?.dailyChallenge ?? 'Daily Adventure',
          actionLabel: isFr ? 'Voir tout' : 'See all',
          onTap: () => context.go(AppRouter.adventuresPath),
        ),
        const SizedBox(height: 12),
        missionsAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.sageGreen)),
          ),
          error: (e, _) => Text(isFr ? 'Impossible de charger l\'aventure' : 'Could not load adventure: $e'),
          data: (missions) {
            final daily = missions.firstWhere(
              (m) => m.mission?.category == MissionCategory.daily && !m.isCompleted,
              orElse: () => missions.isNotEmpty
                  ? missions.first
                  : UserMission(
                      id: 'demo-1',
                      userId: 'demo',
                      missionId: 'mission-001',
                      status: UserMissionStatus.available,
                      mission: Mission(
                        id: 'mission-001',
                        title: isFr ? 'Trouver une fleur jaune dorée' : 'Find a Golden Yellow Flower',
                        description: isFr
                            ? 'Cherchez dans les jardins ensoleillés des pétales jaune vif.'
                            : 'Search sunny lawn edges, meadows, or gardens for bright yellow petals.',
                        category: MissionCategory.daily,
                        difficulty: MissionDifficulty.easy,
                        rewardPoints: 60,
                      ),
                    ),
            );

            final missionObj = daily.mission;
            final isCompleted = daily.isCompleted;

            String difficultyLabel(MissionDifficulty? d) {
              if (d == null) return '';
              switch (d) {
                case MissionDifficulty.easy:
                  return l10n?.easy.toUpperCase() ?? 'EASY';
                case MissionDifficulty.medium:
                  return l10n?.medium.toUpperCase() ?? 'MEDIUM';
                case MissionDifficulty.hard:
                  return l10n?.hard.toUpperCase() ?? 'HARD';
              }
            }

            return MossyCard(
              onTap: () => context.go(AppRouter.adventuresPath),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          difficultyLabel(missionObj?.difficulty),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B4B9A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.butterYellow.withAlpha(70),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC4971A)),
                            const SizedBox(width: 3),
                            Text(
                              '+${missionObj?.rewardPoints ?? 50} pts',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (isCompleted)
                        const Icon(Icons.check_circle_rounded, color: AppColors.sageGreen, size: 20)
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mutedText),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    missionObj?.title ?? (isFr ? 'Quête nature' : 'Nature Quest'),
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    missionObj?.description ?? (isFr ? 'Explorez la nature et relevez des défis.' : 'Explore outdoor greens and complete nature challenges.'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.secondaryText),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── 4. Recent Discoveries Section ─────────────────────────────────────────
  Widget _buildRecentDiscoveriesSection(
    BuildContext context,
    AppLocalizations? l10n,
    bool isFr,
    AsyncValue<List<Discovery>> discoveriesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: l10n?.recentDiscoveries ?? 'Recent Discoveries',
          actionLabel: isFr ? 'Voir le journal' : 'View journal',
          onTap: () => context.go(AppRouter.collectionPath),
        ),
        const SizedBox(height: 12),
        discoveriesAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.sageGreen)),
          ),
          error: (e, _) => Text(isFr ? 'Impossible de charger les découvertes' : 'Could not load discoveries: $e'),
          data: (discoveries) {
            if (discoveries.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.eco_outlined, size: 48, color: AppColors.mintGreen),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.noDiscoveries ?? 'No discoveries yet!',
                      style: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.startExploring ?? 'Step outside and photograph your first plant to begin your nature journal.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRouter.explorePath),
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: Text(isFr ? 'Découvrir maintenant' : 'Discover Now'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.sageGreen,
                        side: const BorderSide(color: AppColors.sageGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            }

            final recent = discoveries.take(5).toList();
            return SizedBox(
              height: 175,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final d = recent[i];
                  return GestureDetector(
                    onTap: () => context.go(AppRouter.collectionPath),
                    child: Container(
                      width: 135,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            child: SizedBox(
                              height: 95,
                              width: 135,
                              child: d.imagePath.startsWith('http')
                                  ? Image.network(
                                      d.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppColors.mintGreen,
                                        child: const Icon(Icons.eco_rounded, color: AppColors.sageGreen),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.mintGreen,
                                      child: const Icon(Icons.eco_rounded, color: AppColors.sageGreen),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d.commonName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.darkGreen),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d.scientificName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 10, color: AppColors.secondaryText),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── 5. Garden Sanctuary Preview Section ───────────────────────────────────
  Widget _buildGardenPreviewSection(BuildContext context, AppLocalizations? l10n, bool isFr, AsyncValue<dynamic> gardenAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: l10n?.yourGarden ?? 'Virtual Garden',
          actionLabel: isFr ? 'Visiter le jardin' : 'Visit garden',
          onTap: () => context.go(AppRouter.gardenPath),
        ),
        const SizedBox(height: 12),
        gardenAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.sageGreen)),
          ),
          error: (e, _) => Text('$e'),
          data: (garden) {
            final level = garden.gardenLevel as int;
            final stageName = garden.stageName as String;
            final progress = (garden.progressToNextLevel as double).clamp(0.0, 1.0);

            return MossyCard(
              onTap: () => context.go(AppRouter.gardenPath),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: AppColors.mintGreen.withAlpha(120), shape: BoxShape.circle),
                    child: const Icon(Icons.park_rounded, color: AppColors.sageGreen, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isFr ? 'Niveau $level — Sanctuaire' : 'Level $level Sanctuary',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.darkGreen),
                            ),
                            const Spacer(),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sageGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(stageName, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.mintGreen.withAlpha(80),
                            color: AppColors.sageGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── 6. Explorer Badges & Achievement Summary ──────────────────────────────
  Widget _buildAchievementSummarySection(
    BuildContext context,
    AppLocalizations? l10n,
    bool isFr,
    AsyncValue<dynamic> achievementsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: l10n?.achievements ?? 'Explorer Badges',
          actionLabel: isFr ? 'Voir tout' : 'View all',
          onTap: () => context.push(AppRouter.profilePath),
        ),
        const SizedBox(height: 12),
        achievementsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (achievements) {
            final list = achievements as List;
            final unlocked = list.where((a) => a.isUnlocked == true).length;
            final total = list.length;

            return MossyCard(
              onTap: () => context.push(AppRouter.profilePath),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: AppColors.butterYellow.withAlpha(70), shape: BoxShape.circle),
                    child: const Icon(Icons.military_tech_rounded, color: Color(0xFFC4971A), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFr ? '$unlocked sur $total badges obtenus' : '$unlocked of $total Badges Earned',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.darkGreen),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          unlocked == total
                              ? (isFr ? 'Botaniste maître ! Tous les succès complétés.' : 'Master Botanist! All achievements completed.')
                              : (isFr ? 'Continuez à explorer pour débloquer votre prochaine étape.' : 'Keep exploring nature to unlock your next milestone.'),
                          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mutedText),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── 7. Quick Links (Map & Settings) ───────────────────────────────────────
  Widget _buildQuickLinksRow(BuildContext context, AppLocalizations? l10n, bool isFr) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(AppRouter.mapPath),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.mintGreen.withAlpha(80), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.map_outlined, color: AppColors.sageGreen, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.discoveryMap ?? 'Discovery Map',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.darkGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(AppRouter.settingsPath),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.lavender.withAlpha(80), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.settings_outlined, color: Color(0xFF7E60A8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n?.settings ?? 'Settings',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.darkGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Header Helper ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader({required String title, required String actionLabel, required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
        GestureDetector(
          onTap: onTap,
          child: Text(actionLabel, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sageGreen)),
        ),
      ],
    );
  }
}
