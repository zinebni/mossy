import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/models/identification_result.dart';
import '../../../shared/models/plant_candidate.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/mascot/mascot_expression.dart';
import '../../../shared/widgets/mascot/mascot_with_accessory.dart';

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
      final bytes = await image.readAsBytes();
      final result = await service.identifyPlant(bytes, image.name);

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

    if (exploreState.isIdentifying) {
      return const _IdentificationLoadingScreen();
    }

    if (exploreState.result != null && exploreState.currentImage != null) {
      return _IdentificationResultScreen(
        result: exploreState.result!,
        imageFile: exploreState.currentImage!,
      );
    }

    if (exploreState.currentImage != null) {
      return _ImagePreviewScreen(
        imageFile: exploreState.currentImage!,
        errorMessage: exploreState.errorMessage,
      );
    }

    return const _ExploreHomeScreen();
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                'Discover Nature',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take a photo of any plant to identify it',
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
                      label: 'Take a Photo',
                      color: AppColors.sageGreen,
                      onTap: () => _pickImage(context, ref, fromCamera: true),
                    ).animate().slideX(begin: -0.3, delay: 400.ms),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.photo_library_rounded,
                      label: 'From Gallery',
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
                          'Photo Tips',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final tip in [
                      '📏  Include leaves, flowers, and stems',
                      '☀️  Use natural light when possible',
                      '📐  Fill the frame with the plant',
                      '🔍  Avoid blurry or dark images',
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(exploreProvider.notifier).reset(),
        ),
        title: const Text('Preview'),
      ),
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
                Text(
                  'Ready to identify!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGreen,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our AI will analyse your photo',
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
                    label: const Text('Identify This Plant'),
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
                  child: const Text('Choose Another'),
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
  static const _messages = [
    'Looking closely at your discovery...',
    'Searching the botanical world...',
    'Consulting the plant encyclopedia...',
    'Preparing something interesting...',
    'Almost there...',
  ];
  int _msgIndex = 0;
  bool _disposed = false;

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
        setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
        _cycle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  _messages[_msgIndex],
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
              label: const Text('Cancel'),
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
class _IdentificationResultScreen extends ConsumerWidget {
  final IdentificationResult result;
  final XFile imageFile;

  const _IdentificationResultScreen({
    required this.result,
    required this.imageFile,
  });

  Color _confidenceColor(double s) {
    if (s >= 0.7) return AppColors.success;
    if (s >= 0.3) return AppColors.butterYellow;
    return AppColors.error;
  }

  String _confidenceLabel(double s) {
    if (s >= 0.7) return 'Very Likely';
    if (s >= 0.4) return 'Likely';
    if (s >= 0.2) return 'Possible';
    return 'Uncertain';
  }

  Future<void> _saveDiscovery(BuildContext context, WidgetRef ref, PlantCandidate candidate) async {
    try {
      final auth = ref.read(authProvider);
      final userId = auth.user?.id ?? 'demo-user';
      final aiService = ref.read(aiContentServiceProvider);
      final discoveryNotifier = ref.read(discoveriesProvider.notifier);

      final aiContent = await aiService.generateContent(
        candidate.scientificName,
        candidate.commonName,
        candidate.family,
        'en',
      );

      final discovery = Discovery(
        id: 'disc-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        commonName: candidate.commonName.isNotEmpty ? candidate.commonName : candidate.scientificName,
        scientificName: candidate.scientificName,
        family: candidate.family,
        imagePath: imageFile.path,
        discoveredAt: DateTime.now(),
        createdAt: DateTime.now(),
        identificationScore: candidate.score,
        aiContent: aiContent,
      );

      await discoveryNotifier.addDiscovery(discovery);
      await ref.read(userProfileProvider.notifier).addPoints(15, 'plant_identified');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🌿 Discovery saved! +15 points'),
            backgroundColor: AppColors.sageGreen,
          ),
        );
        ref.read(exploreProvider.notifier).reset();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = result.bestMatch;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.darkGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => ref.read(exploreProvider.notifier).reset(),
            ),
            title: const Text('Identification Result'),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imageFile.path), fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.cream.withAlpha(230)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (best != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              best.commonName.isNotEmpty ? best.commonName : best.scientificName,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkGreen,
                                  ),
                            ),
                            Text(
                              best.scientificName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.secondaryText,
                                  ),
                            ),
                            if (best.family.isNotEmpty)
                              Text(
                                'Family: ${best.family}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _confidenceColor(best.score).withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _confidenceLabel(best.score),
                              style: TextStyle(
                                color: _confidenceColor(best.score),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(best.score * 100).toStringAsFixed(0)}%',
                              style: TextStyle(color: _confidenceColor(best.score), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                if (result.candidates.length > 1) ...[
                  Text(
                    'Other possibilities',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...result.candidates.skip(1).take(3).map(
                        (c) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.commonName.isNotEmpty ? c.commonName : c.scientificName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      c.scientificName,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 11,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(c.score * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bookmark_add_rounded),
                    label: const Text('Save to Collection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sageGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: best != null ? () => _saveDiscovery(context, ref, best) : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => ref.read(exploreProvider.notifier).reset(),
                  child: const Text('Identify Another Plant'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
