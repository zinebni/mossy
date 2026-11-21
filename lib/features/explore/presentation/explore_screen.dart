import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/quest_service.dart';
import '../../../services/sound_service.dart';
import '../../../services/supabase_service.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/models/discovery_rarity.dart';
import '../../../shared/widgets/rarity_widgets.dart';
import '../../../shared/models/identification_result.dart';
import '../../../shared/models/plant_candidate.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mascot_with_accessory.dart';
import '../../collection/presentation/collection_screen.dart';

// ============================================================================
// EXPLORE STATE & NOTIFIER
// ============================================================================

class ExploreState {
  final XFile? currentImage;
  final bool isIdentifying;
  final IdentificationResult? result;
  final String? errorMessage;

  const ExploreState({
    this.currentImage,
    this.isIdentifying = false,
    this.result,
    this.errorMessage,
  });

  ExploreState copyWith({
    XFile? currentImage,
    bool clearImage = false,
    bool? isIdentifying,
    IdentificationResult? result,
    bool clearResult = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExploreState(
      currentImage: clearImage ? null : (currentImage ?? this.currentImage),
      isIdentifying: isIdentifying ?? this.isIdentifying,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ExploreNotifier extends StateNotifier<ExploreState> {
  final Ref _ref;

  ExploreNotifier(this._ref) : super(const ExploreState());

  void setImage(XFile? file) {
    state = state.copyWith(
      currentImage: file,
      clearResult: true,
      clearError: true,
      isIdentifying: false,
    );
  }

  void reset() {
    state = const ExploreState();
  }

  Future<void> identify() async {
    final image = state.currentImage;
    if (image == null) return;

    state = state.copyWith(isIdentifying: true, clearError: true);

    try {
      final service = _ref.read(plantIdentificationServiceProvider);
      final currentLocale = _ref.read(localeProvider);
      final bytes = await image.readAsBytes();
      final result = await service.identifyPlant(
        bytes,
        image.name,
        language: currentLocale.languageCode,
      );

      final hasMatch = (result.bestMatch != null) || (result.candidates.isNotEmpty);
      if (hasMatch) {
        SoundService.instance.playRecognitionSound().catchError((_) {});
        HapticFeedback.mediumImpact().catchError((_) {});
      }

      state = state.copyWith(
        isIdentifying: false,
        result: result,
        clearError: true,
      );
    } catch (e) {
      debugPrint('[Mossy] Identification failed: $e');
      state = state.copyWith(
        isIdentifying: false,
        errorMessage: 'Identification failed: $e',
      );
    }
  }
}

final exploreProvider =
    StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  return ExploreNotifier(ref);
});

// ============================================================================
// EXPLORE SCREEN ROOT
// ============================================================================

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exploreState = ref.watch(exploreProvider);
    final hasActiveSubScreen = exploreState.isIdentifying ||
        (exploreState.result != null && exploreState.currentImage != null) ||
        exploreState.currentImage != null;

    Widget body;
    if (exploreState.isIdentifying) {
      body = const _IdentificationLoadingScreen();
    } else if (exploreState.result != null && exploreState.currentImage != null) {
      body = _IdentificationResultScreen(
        result: exploreState.result!,
        imageFile: exploreState.currentImage!,
      );
    } else if (exploreState.currentImage != null) {
      body = _ImagePreviewScreen(
        imageFile: exploreState.currentImage!,
        errorMessage: exploreState.errorMessage,
      );
    } else {
      body = const _ExploreHomeScreen();
    }

    return PopScope(
      canPop: !hasActiveSubScreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && hasActiveSubScreen) {
          ref.read(exploreProvider.notifier).reset();
        }
      },
      child: body,
    );
  }
}

// ─── Explore Home ─────────────────────────────────────────────────────────────
class _ExploreHomeScreen extends ConsumerWidget {
  const _ExploreHomeScreen();

  Future<void> _pickImage(BuildContext ctx, WidgetRef ref, {required bool fromCamera}) async {
    final cameraService = ref.read(cameraServiceProvider);
    final XFile? file = fromCamera
        ? await cameraService.pickFromCamera()
        : await cameraService.pickFromGallery();

    if (file != null) {
      ref.read(exploreProvider.notifier).setImage(file);
    } else if (cameraService.lastError != null && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('Could not access ${fromCamera ? "camera" : "gallery"}: ${cameraService.lastError}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final activeQuest = ref.watch(activeQuestProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (activeQuest != null) ...[
                _buildActiveQuestBanner(context, ref, activeQuest, isFr),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Animate(
                effects: [
                  ScaleEffect(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                  ),
                ],
                child: const MascotWithAccessory(
                  expression: MascotExpression.searching,
                  accessory: MascotAccessory.magnifyingGlass,
                  size: 130,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n?.discoverPlant ?? 'Discover a Plant',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n?.takePhoto != null
                    ? (AppLocalizations.of(context)?.identifyPlant ?? 'Take a photo of any plant to identify it')
                    : 'Take a photo of any plant to identify it',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryText,
                    ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.camera_alt_rounded,
                      label: l10n?.takePhoto ?? 'Take a Photo',
                      color: AppColors.sageGreen,
                      onTap: () => _pickImage(context, ref, fromCamera: true),
                    ).animate().slideX(begin: -0.3, delay: 400.ms),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.photo_library_rounded,
                      label: l10n?.chooseFromGallery ?? 'From Gallery',
                      color: AppColors.lavender,
                      iconColor: AppColors.darkGreen,
                      textColor: AppColors.darkGreen,
                      onTap: () => _pickImage(context, ref, fromCamera: false),
                    ).animate().slideX(begin: 0.3, delay: 400.ms),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              MossyCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded, color: AppColors.butterYellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.photoTips ?? 'Photo Tips',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final tip in [
                      '📏  ${l10n?.photoTip2 ?? 'Include leaves and flowers'}',
                      '☀️  ${l10n?.photoTip3 ?? 'Use good lighting'}',
                      '📐  ${l10n?.photoTip1 ?? 'Get close to the plant'}',
                      '🔍  ${l10n?.photoTip4 ?? 'Avoid blurry shots'}',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          tip,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveQuestBanner(
    BuildContext context,
    WidgetRef ref,
    QuestDefinition quest,
    bool isFr,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sageGreen, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.sageGreen.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mintGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.track_changes_rounded,
                        size: 13, color: AppColors.darkGreen),
                    const SizedBox(width: 4),
                    Text(
                      isFr ? 'DÉFI PRIMÉ' : 'PRIMED CHALLENGE',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${quest.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () =>
                    ref.read(activeQuestProvider.notifier).state = null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isFr ? 'Effacer' : 'Clear',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.close_rounded,
                          size: 15, color: AppColors.secondaryText),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(quest.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title(isFr),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quest.targetRequirementLabel(isFr),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Image Preview ────────────────────────────────────────────────────────────
class _ImagePreviewScreen extends ConsumerWidget {
  final XFile imageFile;
  final String? errorMessage;

  const _ImagePreviewScreen({
    required this.imageFile,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final activeQuest = ref.watch(activeQuestProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(exploreProvider.notifier).reset(),
        ),
        title: Text(l10n?.discoverPlant ?? 'Preview'),      ),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(imageFile.path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
              ),
            ),
          ),
          if (errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                if (activeQuest != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintGreen.withAlpha(90),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sageGreen),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(activeQuest.emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isFr
                                ? 'Test pour : ${activeQuest.title(true)}'
                                : 'Evaluating for: ${activeQuest.title(false)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGreen,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Text(
                  l10n?.identifyPlant ?? 'Ready to identify!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGreen,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.tagline ?? 'Our AI will analyse your photo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search_rounded),
                    label: Text(l10n?.identifyPlant ?? 'Identify This Plant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sageGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => ref.read(exploreProvider.notifier).identify(),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => ref.read(exploreProvider.notifier).reset(),
                  child: Text(l10n?.chooseAnother ?? 'Choose Another'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Screen ───────────────────────────────────────────────────────────
class _IdentificationLoadingScreen extends ConsumerStatefulWidget {
  const _IdentificationLoadingScreen();

  @override
  ConsumerState<_IdentificationLoadingScreen> createState() => _LoadingState();
}

class _LoadingState extends ConsumerState<_IdentificationLoadingScreen> {
  int _msgIndex = 0;
  bool _disposed = false;

  List<String> _messages(AppLocalizations? l10n) => [
    l10n?.lookingClosely ?? 'Looking closely at your discovery...',
    l10n?.searchingBotanical ?? 'Searching the botanical world...',
    l10n?.consultingEncyclopedia ?? 'Consulting the plant encyclopedia...',
    l10n?.preparingSomething ?? 'Preparing something interesting...',
    l10n?.almostThere ?? 'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _cycle() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!_disposed && mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _msgIndex = (_msgIndex + 1) % _messages(l10n).length);
        _cycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final msgs = _messages(l10n);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const MascotWithAccessory(
              expression: MascotExpression.curious,
              accessory: MascotAccessory.magnifyingGlass,
              size: 150,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.sageGreen),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Padding(
                key: ValueKey(_msgIndex),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  msgs[_msgIndex],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextButton.icon(
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text(l10n?.cancel ?? 'Cancel'),
              style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
              onPressed: () {
                ref.read(exploreProvider.notifier).reset();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Result Screen ────────────────────────────────────────────────────────────
class _IdentificationResultScreen extends ConsumerStatefulWidget {
  final IdentificationResult result;
  final XFile imageFile;

  const _IdentificationResultScreen({
    required this.result,
    required this.imageFile,
  });

  @override
  ConsumerState<_IdentificationResultScreen> createState() => _IdentificationResultScreenState();
}

class _IdentificationResultScreenState extends ConsumerState<_IdentificationResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;
  String? _errorMessage;
  String _statusMessage = 'Examining specimen...';
  int _msgIndex = 0;
  Timer? _msgTimer;

  static const List<String> _loreMessagesEn = [
    '🌿 Plant spotted! Mossy is examining your specimen...',
    '✨ Consulting botanical wisdom & forest lore...',
    '📖 Weaving your unique Nature Journal story...',
    '🌱 Preparing kid-friendly growing tips & safe explorer advice...',
    '🎨 Assembling your high-resolution specimen card...',
    '🎉 Almost ready to add to your collection!',
  ];

  static const List<String> _loreMessagesFr = [
    '🌿 Plante repérée ! Mossy examine votre spécimen...',
    '✨ Consultation de la sagesse botanique et des secrets de la forêt...',
    '📖 Rédaction de votre histoire dans le Journal de Nature...',
    '🌱 Préparation des astuces de culture et conseils d\'explorateur...',
    '🎨 Assemblage de votre fiche de spécimen haute résolution...',
    '🎉 Presque prêt pour votre collection !',
  ];

  @override
  void initState() {
    super.initState();
    final candidate = widget.result.bestMatch ??
        (widget.result.candidates.isNotEmpty ? widget.result.candidates.first : null);

    if (candidate != null) {
      // 1. Immediate recognition feedback: joyful chime sound + haptic vibration
      SoundService.instance.playRecognitionSound().catchError((_) {});
      HapticFeedback.mediumImpact().catchError((_) {});

      // 2. Start cycling friendly wisdom generation messages
      _startCyclingMessages();

      // 3. Automatically craft wisdom & save discovery without manual button tap
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isSaving && !_isSaved) {
          _saveDiscovery(candidate);
        }
      });
    }
  }

  void _startCyclingMessages() {
    _msgTimer?.cancel();
    _msgTimer = Timer.periodic(const Duration(milliseconds: 2300), (_) {
      if (mounted) {
        setState(() => _msgIndex++);
      }
    });
  }

  @override
  void dispose() {
    _msgTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveDiscovery(PlantCandidate candidate) async {
    if (_isSaving || _isSaved) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = 'Archiving specimen photo...';
    });

    try {
      final auth = ref.read(authProvider);
      final currentUser = SupabaseService.instance.auth?.currentUser;
      final userId = currentUser?.id ?? auth.user?.id ?? 'guest-user';
      final aiService = ref.read(aiContentServiceProvider);
      final discoveryNotifier = ref.read(discoveriesProvider.notifier);
      final imageStorage = ref.read(imageStorageServiceProvider);
      final discoveryId = const Uuid().v4();

      // 1. Copy high-res image to persistent documents directory
      String persistentImagePath = await imageStorage.saveLocalSpecimen(widget.imageFile.path, discoveryId);

      // 2. If authenticated, optionally upload to Supabase storage bucket
      if (currentUser != null) {
        if (mounted) {
          setState(() => _statusMessage = 'Syncing specimen photo to cloud...');
        }
        final cloudUrl = await imageStorage.uploadSpecimenToCloud(
          localPath: persistentImagePath,
          discoveryId: discoveryId,
          userId: currentUser.id,
        );
        if (cloudUrl != null && cloudUrl.isNotEmpty) {
          persistentImagePath = cloudUrl;
        }
      }

      // 3. Generate structured botanical lore from Gemini
      if (mounted) {
        setState(() => _statusMessage = 'Consulting Gemini botanical wisdom...');
      }

      final currentLocale = ref.read(localeProvider);
      final aiContent = await aiService.generateContent(
        candidate.scientificName,
        candidate.commonName,
        candidate.family,
        currentLocale.languageCode,
      );

      // 3b. Capture real device GPS coordinates (optional & non-blocking)
      double? latitude;
      double? longitude;
      try {
        final locService = ref.read(locationServiceProvider);
        final pos = await locService.getCurrentPosition(
          timeLimit: const Duration(seconds: 4),
        );
        if (pos != null) {
          latitude = pos.latitude;
          longitude = pos.longitude;
        }
      } catch (e) {
        debugPrint('[Mossy] Non-fatal GPS location capture: $e');
      }

      // 4. Construct complete Discovery entry
      if (mounted) {
        setState(() => _statusMessage = 'Recording in your Nature Journal...');
      }

      final discovery = Discovery(
        id: discoveryId,
        userId: userId,
        commonName: candidate.commonName.isNotEmpty ? candidate.commonName : candidate.scientificName,
        scientificName: candidate.scientificName,
        family: candidate.family,
        imagePath: persistentImagePath,
        discoveredAt: DateTime.now(),
        createdAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        identificationScore: candidate.score,
        aiContent: aiContent,
        // Gemini decides the tier; invalid/missing -> deterministic engine.
        rarity: aiContent.rarity ??
            RarityEngine.assign(
              scientificName: candidate.scientificName,
              family: candidate.family,
            ),
      );
      final rarity = discovery.rarity;
      final earnedPoints = rarity.totalPoints;
      final oldGardenLevel = ref.read(gardenStateProvider).value?.gardenLevel ?? 1;

      // 5. Save to journal and award points
      await discoveryNotifier.addDiscovery(discovery);
      await ref.read(userProfileProvider.notifier).addPoints(
        earnedPoints,
        rarity == DiscoveryRarity.common ? 'plant_identified' : 'plant_identified_${rarity.name}',
        referenceId: discoveryId,
      );

      final activeQuest = ref.read(activeQuestProvider);
      final isQuestMatch = activeQuest != null &&
          activeQuest.matchesPlant(
            family: candidate.family,
            scientificName: candidate.scientificName,
            commonName: candidate.commonName,
          );

      if (isQuestMatch) {
        ref.read(activeQuestProvider.notifier).state = null;
      }

      final newGardenState = ref.read(gardenStateProvider).value;
      final newGardenLevel = newGardenState?.gardenLevel ?? oldGardenLevel;
      final gardenLeveledUp = newGardenLevel > oldGardenLevel;
      final earnedBadge = ref.read(latestBadgeAwardProvider);
      if (earnedBadge != null) {
        ref.read(latestBadgeAwardProvider.notifier).state = null;
      }

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      // Clear the explore state so popping back from the detail view returns to a fresh Explore screen
      ref.read(exploreProvider.notifier).reset();

      // Automatically navigate directly to the new Discovery Card without requiring an extra manual tap!
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiscoveryDetailPage(
            discovery: discovery,
            autoCelebrate: true,
            earnedBadge: earnedBadge,
            gardenLeveledUp: gardenLeveledUp,
            newGardenLevel: newGardenLevel,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Mossy] Error saving discovery: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFr = ref.read(localeProvider).languageCode == 'fr' ||
        Localizations.localeOf(context).languageCode == 'fr' ||
        l10n?.home == 'Accueil';
    final candidate = widget.result.bestMatch ??
        (widget.result.candidates.isNotEmpty ? widget.result.candidates.first : null);

    if (candidate == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
            onPressed: () => ref.read(exploreProvider.notifier).reset(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MascotWithAccessory(
                  expression: MascotExpression.curious,
                  accessory: MascotAccessory.magnifyingGlass,
                  size: 130,
                ),
                const SizedBox(height: 24),
                Text(
                  isFr ? 'Aucune plante reconnue' : 'No plant detected',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isFr
                      ? 'Mossy n\'a pas pu identifier clairement cette plante. Rapprochez-vous avec une belle lumière naturelle sur les feuilles ou les fleurs !'
                      : 'Mossy could not clearly identify a plant in this photo. Try taking a closer, well-lit photo of the leaves or flowers!',
                  style: const TextStyle(fontSize: 14, color: AppColors.secondaryText, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(isFr ? 'Prendre une autre photo' : 'Try Another Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sageGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => ref.read(exploreProvider.notifier).reset(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final candidateRarity = RarityEngine.assign(
      scientificName: candidate.scientificName,
      family: candidate.family,
    );
    final activeQuest = ref.watch(activeQuestProvider);
    final bool isQuestMatch = activeQuest != null &&
        activeQuest.matchesPlant(
          family: candidate.family,
          scientificName: candidate.scientificName,
          commonName: candidate.commonName,
        );

    if (_errorMessage != null && !_isSaved) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
            onPressed: () => ref.read(exploreProvider.notifier).reset(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MascotWithAccessory(
                  expression: MascotExpression.surprised,
                  accessory: MascotAccessory.magnifyingGlass,
                  size: 120,
                ),
                const SizedBox(height: 24),
                Text(
                  isFr ? 'Oups ! Petit imprévu' : 'Oops! Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref.read(exploreProvider.notifier).reset(),
                      child: Text(isFr ? 'Annuler' : 'Cancel'),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(isFr ? 'Réessayer' : 'Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.sageGreen),
                      onPressed: () => _saveDiscovery(candidate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final loreMessages = isFr ? _loreMessagesFr : _loreMessagesEn;

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          foregroundColor: AppColors.darkGreen,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => ref.read(exploreProvider.notifier).reset(),
          ),
          title: Text(
            isFr ? 'Création de la découverte...' : 'Crafting Discovery...',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 1. Instant Recognition Pill / Alert ─────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: candidateRarity.color.withAlpha(160), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: candidateRarity.color.withAlpha(35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: candidateRarity.color.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: candidateRarity.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFr ? '🎉 Plante reconnue avec succès !' : '🎉 Plant spotted successfully!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isFr
                                ? 'Mossy prépare votre fiche dans le journal...'
                                : 'Mossy is crafting your Nature Journal entry...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 16),

              // ─── 2. Lively Specimen Preview Card ──────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: candidateRarity.color.withAlpha(120), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: candidateRarity.color.withAlpha(40),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.file(
                          File(widget.imageFile.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.commonName.isNotEmpty ? candidate.commonName : candidate.scientificName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkGreen,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            candidate.scientificName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.secondaryText,
                                ),
                          ),
                          if (candidate.family.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              isFr ? 'Famille : ${candidate.family}' : 'Family: ${candidate.family}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              RarityBadge(rarity: candidateRarity, isFr: isFr),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.butterYellow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${candidateRarity.totalPoints} XP',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (activeQuest != null && isQuestMatch) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.mintLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sageGreen, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.sageGreen, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isFr
                              ? '🎯 Correspond au défi « ${activeQuest.title(true)} » (+${activeQuest.xpReward} XP) !'
                              : '🎯 Matches challenge "${activeQuest.title(false)}" (+${activeQuest.xpReward} XP)!',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ─── 3. Engaging Wisdom Generation Activity Box ───────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkGreen.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      child: const MascotWithAccessory(
                        expression: MascotExpression.curious,
                        accessory: MascotAccessory.magnifyingGlass,
                        size: 95,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: -6, duration: 1200.ms),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: AppColors.mintGreen,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.sageGreen),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        loreMessages[_msgIndex % loreMessages.length],
                        key: ValueKey(_msgIndex % loreMessages.length),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── 4. Cancel Button ─────────────────────────────────────────
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(
                    isFr ? 'Annuler' : 'Cancel',
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                  onPressed: () => ref.read(exploreProvider.notifier).reset(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

