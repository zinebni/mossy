import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/quest_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../explore/presentation/explore_screen.dart';

/// Modal bottom sheet presenting complete challenge details and
/// providing direct action to launch the primed Plant Scanner / Camera.
class ChallengeDetailSheet extends ConsumerWidget {
  final QuestWithProgress quest;

  const ChallengeDetailSheet({
    super.key,
    required this.quest,
  });

  /// Convenient static helper to show the sheet modally.
  static Future<void> show(BuildContext context, QuestWithProgress quest) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChallengeDetailSheet(quest: quest),
    );
  }

  void _primeAndLaunchScanner(
    BuildContext context,
    WidgetRef ref, {
    bool fromCamera = false,
    bool fromGallery = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final def = quest.definition;

    // Set the primed quest
    ref.read(activeQuestProvider.notifier).state = def;

    // Close the sheet first
    Navigator.of(context).pop();

    if (fromCamera || fromGallery) {
      final cameraService = ref.read(cameraServiceProvider);
      final file = fromCamera
          ? await cameraService.pickFromCamera()
          : await cameraService.pickFromGallery();

      if (file != null) {
        ref.read(exploreProvider.notifier).setImage(file);
      } else {
        ref.read(exploreProvider.notifier).reset();
      }
    } else {
      // Direct explore view primed with target quest banner
      ref.read(exploreProvider.notifier).reset();
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(def.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFr
                      ? 'Défi activé : ${def.title(true)} — Scanner prêt !'
                      : 'Challenge active: ${def.title(false)} — Scanner primed!',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.sageGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate smoothly to the explore/scanner tab
      context.go(AppRouter.explorePath);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final def = quest.definition;
    final completed = quest.isCompleted;
    final isDaily = def.type == QuestType.daily;

    final accent = completed
        ? AppColors.sageGreen
        : isDaily
            ? const Color(0xFF6B9FD4)
            : AppColors.butterYellow;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.secondaryText.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Top Header: Emoji + Badges + Close
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withAlpha(40),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(def.emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDaily
                                  ? const Color(0xFFE3EDFA)
                                  : AppColors.butterYellow.withAlpha(70),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isDaily
                                  ? (isFr ? 'DÉFI DU JOUR' : 'DAILY CHALLENGE')
                                  : (isFr
                                      ? 'QUÊTE SAISONNIÈRE'
                                      : 'SEASONAL QUEST'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDaily
                                    ? const Color(0xFF2E659A)
                                    : AppColors.darkGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.butterYellow.withAlpha(50),
                              border: Border.all(
                                  color: AppColors.butterYellow.withAlpha(120)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded,
                                    size: 13, color: AppColors.butterYellow),
                                const SizedBox(width: 2),
                                Text(
                                  '+${def.xpReward} XP',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        def.title(isFr),
                        style: GoogleFonts.fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.secondaryText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Description
            Text(
              def.description(isFr),
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Botanical Target Criteria Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.travel_explore_rounded,
                        color: AppColors.sageGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFr ? 'Objectif botanique' : 'Botanical Target',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          def.targetRequirementLabel(isFr),
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFr
                              ? 'Le scanner évaluera automatiquement vos photos.'
                              : 'The scanner will evaluate your photos automatically.',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress Bar & Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFr ? 'Progression' : 'Progress',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGreen,
                  ),
                ),
                Text(
                  completed
                      ? (isFr ? '✅ Défi Terminé !' : '✅ Challenge Completed!')
                      : '${quest.currentCount} / ${quest.targetCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: completed
                        ? AppColors.sageGreen
                        : AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: quest.completionFraction,
                minHeight: 8,
                backgroundColor: accent.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? AppColors.sageGreen : accent,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons
            if (completed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen.withAlpha(90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sageGreen),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.darkGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isFr
                          ? 'Félicitations ! Défi déjà complété.'
                          : 'Congratulations! Challenge already completed.',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Primary: Start Challenge & Open Scanner
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _primeAndLaunchScanner(context, ref),
                  icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
                  label: Text(
                    isFr
                        ? 'Démarrer le Défi & Scanner'
                        : 'Start Challenge & Scan',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary Quick Actions: Camera / Gallery
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _primeAndLaunchScanner(context, ref,
                          fromCamera: true),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(
                        isFr ? 'Prendre Photo' : 'Take Photo',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkGreen,
                        side: const BorderSide(color: AppColors.sageGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _primeAndLaunchScanner(context, ref,
                          fromGallery: true),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(
                        isFr ? 'Galerie' : 'Gallery',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkGreen,
                        side: const BorderSide(color: AppColors.sageGreen),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
