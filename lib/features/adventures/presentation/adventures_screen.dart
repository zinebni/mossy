import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/mission.dart';
import '../../../shared/models/user_mission.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mascot_with_accessory.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missionsAsync = ref.watch(missionsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Adventures', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
                  Text('Complete challenges to earn points', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText)),
                ]),
              ),
              const MascotWithAccessory(
                expression: MascotExpression.excited,
                accessory: MascotAccessory.backpack,
                size: 70,
                animate: false,
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: AppColors.mintGreen.withAlpha(80), borderRadius: BorderRadius.circular(14)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: AppColors.sageGreen, borderRadius: BorderRadius.circular(12)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.secondaryText,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Challenges'),
                Tab(text: 'Completed'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: missionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageGreen)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (missions) => TabBarView(
                controller: _tabController,
                children: [
                  _MissionList(missions: missions.where((m) => m.mission?.category == MissionCategory.daily && !m.isCompleted).toList()),
                  _MissionList(missions: missions.where((m) => m.mission?.category != MissionCategory.daily && !m.isCompleted).toList()),
                  _MissionList(missions: missions.where((m) => m.isCompleted).toList(), isCompleted: true),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MissionList extends ConsumerWidget {
  final List<UserMission> missions;
  final bool isCompleted;
  const _MissionList({required this.missions, this.isCompleted = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (missions.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.explore_outlined, size: 64, color: AppColors.mintGreen),
          const SizedBox(height: 16),
          Text(isCompleted ? 'No completed adventures yet' : 'No adventures available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.secondaryText)),
          const SizedBox(height: 8),
          Text(isCompleted ? 'Complete challenges to see them here' : 'Check back soon for new adventures!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: missions.length,
      itemBuilder: (context, i) => _MissionCard(
        userMission: missions[i],
        isCompleted: isCompleted,
      ).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.2),
    );
  }
}

class _MissionCard extends ConsumerWidget {
  final UserMission userMission;
  final bool isCompleted;
  const _MissionCard({required this.userMission, this.isCompleted = false});

  Color _difficultyColor(MissionDifficulty? d) {
    switch (d) {
      case MissionDifficulty.easy: return AppColors.mintGreen;
      case MissionDifficulty.medium: return AppColors.butterYellow;
      case MissionDifficulty.hard: return AppColors.peach;
      default: return AppColors.mintGreen;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = userMission.mission;
    final diffColor = _difficultyColor(m?.difficulty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 6,
          height: 100,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.sageGreen : diffColor,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(m?.title ?? userMission.missionId,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle_rounded, color: AppColors.sageGreen, size: 20)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: diffColor.withAlpha(80), borderRadius: BorderRadius.circular(8)),
                    child: Text(m?.difficulty.name ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(m?.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star_rounded, color: AppColors.butterYellow, size: 16),
                const SizedBox(width: 4),
                Text('${m?.rewardPoints ?? 0} pts',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
                const Spacer(),
                if (!isCompleted)
                  TextButton(
                    onPressed: () => _startMission(context, ref),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                    child: const Text('Start', style: TextStyle(fontSize: 12, color: AppColors.sageGreen, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _startMission(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(missionsProvider.notifier).startMission(userMission.missionId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎒 Adventure started!'), backgroundColor: AppColors.sageGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
