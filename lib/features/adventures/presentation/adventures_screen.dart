import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/quest_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mascot_with_accessory.dart';

// ════════════════════════════════════════════════════════════════════════════
// Adventures & Quests Screen
// ════════════════════════════════════════════════════════════════════════════

class AdventuresScreen extends ConsumerStatefulWidget {
  const AdventuresScreen({super.key});

  @override
  ConsumerState<AdventuresScreen> createState() => _AdventuresScreenState();
}

class _AdventuresScreenState extends ConsumerState<AdventuresScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isFr =>
      AppLocalizations.of(context)?.home == 'Accueil';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFr = _isFr;
    final questsAsync = ref.watch(questsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final totalXp = profileAsync.maybeWhen(
      data: (p) => p.totalPoints,
      orElse: () => 0,
    );
    final level = profileAsync.maybeWhen(
      data: (p) => p.explorerLevel,
      orElse: () => 1,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────────
          _AdventureHeader(
            isFr: isFr,
            l10n: l10n,
            totalXp: totalXp,
            level: level,
          ),
          const SizedBox(height: 10),

          // ── Tab bar ───────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.mintGreen.withAlpha(70),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.sageGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.secondaryText,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: isFr ? 'Défis du Jour' : 'Daily'),
                Tab(text: isFr ? 'Quêtes Saisonnières' : 'Seasonal'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: questsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.sageGreen),
              ),
              error: (e, _) => _ErrorState(message: e.toString(), isFr: isFr),
              data: (quests) {
                final daily =
                    quests.where((q) => q.definition.type == QuestType.daily).toList();
                final seasonal = quests
                    .where((q) => q.definition.type == QuestType.seasonal)
                    .toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _QuestList(
                      quests: daily,
                      isFr: isFr,
                      isDaily: true,
                    ),
                    _QuestList(
                      quests: seasonal,
                      isFr: isFr,
                      isDaily: false,
                    ),
                  ],
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Header with XP summary
// ════════════════════════════════════════════════════════════════════════════

class _AdventureHeader extends StatelessWidget {
  final bool isFr;
  final AppLocalizations? l10n;
  final int totalXp;
  final int level;

  const _AdventureHeader({
    required this.isFr,
    required this.l10n,
    required this.totalXp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        // Title column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.adventures ?? 'Adventures',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkGreen,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                isFr
                    ? 'Explorez, scannez, gagnez des XP !'
                    : 'Explore, scan plants, earn XP!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
              const SizedBox(height: 10),
              // XP / level pill row
              Row(children: [
                _XpPill(xp: totalXp, isFr: isFr),
                const SizedBox(width: 8),
                _LevelPill(level: level, isFr: isFr),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const MascotWithAccessory(
          expression: MascotExpression.excited,
          accessory: MascotAccessory.backpack,
          size: 72,
          animate: false,
        ),
      ]),
    );
  }
}

class _XpPill extends StatelessWidget {
  final int xp;
  final bool isFr;
  const _XpPill({required this.xp, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.butterYellow.withAlpha(50),
        border: Border.all(color: AppColors.butterYellow.withAlpha(120)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.bolt_rounded, size: 14, color: AppColors.butterYellow),
        const SizedBox(width: 4),
        Text(
          '$xp XP',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGreen,
          ),
        ),
      ]),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final int level;
  final bool isFr;
  const _LevelPill({required this.level, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sageGreen.withAlpha(40),
        border: Border.all(color: AppColors.sageGreen.withAlpha(100)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.military_tech_rounded,
            size: 14, color: AppColors.sageGreen),
        const SizedBox(width: 4),
        Text(
          isFr ? 'Niv. $level' : 'Lv $level',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGreen,
          ),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Quest list
// ════════════════════════════════════════════════════════════════════════════

class _QuestList extends StatelessWidget {
  final List<QuestWithProgress> quests;
  final bool isFr;
  final bool isDaily;

  const _QuestList({
    required this.quests,
    required this.isFr,
    required this.isDaily,
  });

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return _EmptyState(isFr: isFr, isDaily: isDaily);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: quests.length,
      itemBuilder: (context, i) => _QuestCard(
        quest: quests[i],
        isFr: isFr,
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: i * 90))
          .slideY(begin: 0.18, curve: Curves.easeOut),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Quest card
// ════════════════════════════════════════════════════════════════════════════

class _QuestCard extends StatelessWidget {
  final QuestWithProgress quest;
  final bool isFr;

  const _QuestCard({required this.quest, required this.isFr});

  @override
  Widget build(BuildContext context) {
    final def = quest.definition;
    final completed = quest.isCompleted;
    final fraction = quest.completionFraction;

    // Colour accent
    final accent = completed
        ? AppColors.sageGreen
        : def.type == QuestType.daily
            ? const Color(0xFF6B9FD4) // cornflower blue for daily
            : AppColors.butterYellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: [
          // ── Top row ───────────────────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Left accent bar
            Container(
              width: 5,
              height: 110,
              color: accent,
            ),
            // Emoji badge
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 0, 14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(def.emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 10),
            // Title / description / XP
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            def.title(isFr),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (completed)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.sageGreen, size: 20)
                        else
                          _XpBadge(xp: def.xpReward),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        def.description(isFr),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.secondaryText,
                            ),
                      ),
                      const SizedBox(height: 6),
                      // Count label
                      Text(
                        completed
                            ? (isFr ? '✅ Terminé !' : '✅ Completed!')
                            : '${quest.currentCount} / ${quest.targetCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: completed
                              ? AppColors.sageGreen
                              : AppColors.secondaryText,
                        ),
                      ),
                    ]),
              ),
            ),
          ]),

          // ── Progress bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: accent.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? AppColors.sageGreen : accent,
                ),
              ),
            ),
          ),

          // ── Tip row ───────────────────────────────────────────────────────
          if (!completed)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 6, 12, 10),
              child: Row(children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 13, color: accent.withAlpha(200)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _tip(def, isFr),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText.withAlpha(190),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ]),
            )
          else
            const SizedBox(height: 10),
        ]),
      ),
    );
  }

  String _tip(QuestDefinition def, bool isFr) {
    switch (def.requirementType) {
      case QuestRequirementType.specificFamily:
        final family = def.requiredFamily ?? '';
        return isFr
            ? 'Cherchez une plante de la famille $family'
            : 'Look for plants in the $family family';
      case QuestRequirementType.tagMatch:
        return isFr
            ? 'Utilisez le scanner pour identifier des plantes'
            : 'Use the scanner to identify plants';
      case QuestRequirementType.anyPlant:
      case QuestRequirementType.countBased:
        return isFr
            ? 'Scannez des plantes autour de vous'
            : 'Scan any plants around you';
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Supporting widgets
// ════════════════════════════════════════════════════════════════════════════

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.butterYellow.withAlpha(50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.butterYellow.withAlpha(120)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.bolt_rounded, size: 11, color: AppColors.butterYellow),
        const SizedBox(width: 2),
        Text(
          '+$xp XP',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGreen,
          ),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFr;
  final bool isDaily;

  const _EmptyState({required this.isFr, required this.isDaily});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.explore_outlined, size: 64, color: AppColors.mintGreen),
        const SizedBox(height: 16),
        Text(
          isDaily
              ? (isFr ? 'Aucun défi du jour' : 'No daily challenge yet')
              : (isFr ? 'Aucune quête saisonnière' : 'No seasonal quests yet'),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.secondaryText),
        ),
        const SizedBox(height: 8),
        Text(
          isFr
              ? 'Revenez bientôt pour de nouvelles aventures !'
              : 'Check back soon for new adventures!',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.mutedText),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isFr;
  const _ErrorState({required this.message, required this.isFr});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.peach),
          const SizedBox(height: 12),
          Text(
            isFr ? 'Une erreur est survenue' : 'Something went wrong',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.mutedText),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
      ),
    );
  }
}
