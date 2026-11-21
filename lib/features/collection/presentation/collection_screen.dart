import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/image_storage_service.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/models/achievement.dart';
import '../../../shared/models/garden_state.dart';
import '../../../shared/widgets/celebration_dialogs.dart';
import '../../../shared/widgets/rarity_widgets.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';

enum _SortOption {
  recent('Newest First'),
  oldest('Oldest First'),
  confidence('Highest Confidence'),
  name('Name (A–Z)');

  final String label;
  const _SortOption(this.label);

  String localizedLabel(bool isFr) {
    switch (this) {
      case _SortOption.recent:
        return isFr ? 'Plus récent d\'abord' : 'Newest First';
      case _SortOption.oldest:
        return isFr ? 'Plus ancien d\'abord' : 'Oldest First';
      case _SortOption.confidence:
        return isFr ? 'Confiance la plus élevée' : 'Highest Confidence';
      case _SortOption.name:
        return isFr ? 'Nom (A–Z)' : 'Name (A–Z)';
    }
  }
}

/// Nature Discovery Journal — Personal botanical collection of all saved finds.
/// Features high-resolution photos, scientific classification, personal notes,
/// and interactive filters.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  String _search = '';
  bool _favoritesOnly = false;
  String? _selectedFamily;
  _SortOption _sortOption = _SortOption.recent;
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final discoveriesAsync = ref.watch(discoveriesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // ─── 1. Header Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.myCollection ?? 'My Collection',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkGreen,
                              ),
                        ),
                        discoveriesAsync.maybeWhen(
                          data: (list) => Text(
                            isFr
                                ? 'Journal de découvertes • ${list.length} ${list.length == 1 ? 'trouvaille' : 'trouvailles'}'
                                : 'Nature Discovery Journal • ${list.length} ${list.length == 1 ? 'find' : 'finds'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          orElse: () => Text(
                            isFr ? 'Journal de découvertes' : 'Nature Discovery Journal',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sort menu button
                  PopupMenuButton<_SortOption>(
                    icon: const Icon(Icons.sort_rounded, color: AppColors.sageGreen),
                    tooltip: isFr ? 'Trier le journal' : 'Sort journal',
                    initialValue: _sortOption,
                    onSelected: (option) => setState(() => _sortOption = option),
                    itemBuilder: (context) => _SortOption.values.map((opt) {
                      return PopupMenuItem(
                        value: opt,
                        child: Text(
                          opt.localizedLabel(isFr),
                          style: TextStyle(
                            fontWeight: _sortOption == opt ? FontWeight.w700 : FontWeight.normal,
                            color: _sortOption == opt ? AppColors.darkGreen : AppColors.secondaryText,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Grid / List toggle
                  IconButton(
                    icon: Icon(
                      _gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: AppColors.sageGreen,
                    ),
                    tooltip: _gridView
                        ? (isFr ? 'Vue liste' : 'Switch to list view')
                        : (isFr ? 'Vue grille' : 'Switch to grid view'),
                    onPressed: () => setState(() => _gridView = !_gridView),
                  ),
                ],
              ),
            ),

            // ─── 2. Search Field ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: l10n?.searchPlants ?? 'Search by common name, species, family, or notes…',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.mutedText, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.mutedText),
                            onPressed: () => setState(() => _search = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // ─── 3. Filter Chips ──────────────────────────────────────────
            discoveriesAsync.maybeWhen(
              data: (all) {
                final families = all
                    .map((d) => d.family)
                    .where((f) => f.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();

                final favoriteCount = all.where((d) => d.isFavorite).length;

                return SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      ChoiceChip(
                        label: Text(l10n?.all ?? 'All'),
                        selected: !_favoritesOnly && _selectedFamily == null,
                        onSelected: (_) {
                          setState(() {
                            _favoritesOnly = false;
                            _selectedFamily = null;
                          });
                        },
                        selectedColor: AppColors.sageGreen.withAlpha(60),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: (!_favoritesOnly && _selectedFamily == null) ? AppColors.darkGreen : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: Icon(
                          _favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: _favoritesOnly ? Colors.redAccent : AppColors.secondaryText,
                        ),
                        label: Text('${l10n?.favorites ?? 'Favorites'} ($favoriteCount)'),
                        selected: _favoritesOnly,
                        onSelected: (selected) => setState(() => _favoritesOnly = selected),
                        selectedColor: Colors.redAccent.withAlpha(40),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _favoritesOnly ? Colors.redAccent : AppColors.secondaryText,
                        ),
                      ),
                      if (families.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...families.map((fam) {
                          final isSelected = _selectedFamily == fam;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(fam),
                              selected: isSelected,
                              onSelected: (selected) => setState(() => _selectedFamily = selected ? fam : null),
                              selectedColor: AppColors.sageGreen.withAlpha(70),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? AppColors.darkGreen : AppColors.secondaryText,
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

            const SizedBox(height: 8),

            // ─── 4. Journal Collection List / Grid ────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.sageGreen,
                onRefresh: () async => ref.invalidate(discoveriesProvider),
                child: discoveriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageGreen)),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(isFr ? 'Impossible de charger les découvertes' : 'Could not load discoveries: $e', textAlign: TextAlign.center),
                    ),
                  ),
                  data: (all) {
                    var list = all.where((d) {
                      if (_favoritesOnly && !d.isFavorite) return false;
                      if (_selectedFamily != null && d.family != _selectedFamily) return false;
                      if (_search.isNotEmpty) {
                        final inCommon = d.commonName.toLowerCase().contains(_search);
                        final inSci = d.scientificName.toLowerCase().contains(_search);
                        final inFamily = d.family.toLowerCase().contains(_search);
                        final inNotes = (d.personalNotes ?? '').toLowerCase().contains(_search);
                        return inCommon || inSci || inFamily || inNotes;
                      }
                      return true;
                    }).toList();

                    switch (_sortOption) {
                      case _SortOption.recent:
                        list.sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
                        break;
                      case _SortOption.oldest:
                        list.sort((a, b) => a.discoveredAt.compareTo(b.discoveredAt));
                        break;
                      case _SortOption.confidence:
                        list.sort((a, b) => b.identificationScore.compareTo(a.identificationScore));
                        break;
                      case _SortOption.name:
                        list.sort((a, b) => a.commonName.compareTo(b.commonName));
                        break;
                    }

                    if (list.isEmpty) {
                      return _EmptyState(
                        isFr: isFr,
                        l10n: l10n,
                        favoritesOnly: _favoritesOnly,
                        selectedFamily: _selectedFamily,
                        hasSearch: _search.isNotEmpty,
                        totalCount: all.length,
                      );
                    }

                    if (_gridView) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.74,
                        ),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) => _GridCard(discovery: list[i])
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: (i % 8) * 40)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) => _ListCard(discovery: list[i])
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: (i % 8) * 40)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isFr;
  final AppLocalizations? l10n;
  final bool favoritesOnly;
  final String? selectedFamily;
  final bool hasSearch;
  final int totalCount;

  const _EmptyState({
    required this.isFr,
    required this.l10n,
    required this.favoritesOnly,
    required this.selectedFamily,
    required this.hasSearch,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String description;

    if (favoritesOnly) {
      title = isFr ? 'Aucun favori marqué' : 'No favorites marked';
      description = isFr
          ? 'Appuyez sur l\'icône cœur sur une découverte pour l\'enregistrer ici.'
          : 'Tap the heart icon on any botanical find to save it here.';
    } else if (selectedFamily != null) {
      title = isFr ? 'Aucune plante $selectedFamily' : 'No $selectedFamily plants';
      description = isFr
          ? 'Vous n\'avez pas encore enregistré de spécimens de la famille $selectedFamily.'
          : 'You have not recorded any specimens in the $selectedFamily family yet.';
    } else if (hasSearch) {
      title = isFr ? 'Aucun résultat trouvé' : 'No matches found';
      description = isFr
          ? 'Essayez de rechercher avec une espèce, un nom commun ou une famille différente.'
          : 'Try searching with a different species, common name, or family.';
    } else {
      title = isFr ? 'Votre journal est vide' : 'Your Journal is Empty';
      description = isFr
          ? 'Commencez à explorer la nature ! Identifiez des feuilles, fleurs et arbres avec l\'appareil photo.'
          : 'Start exploring nature! Identify wild leaves, flowers, and trees with the camera to build your personal field journal.';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.mintGreen.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, size: 48, color: AppColors.sageGreen),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkGreen,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.4,
                  ),
            ),
            if (totalCount == 0) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/explore'),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: Text(isFr ? 'Commencer à explorer' : 'Start Exploring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── High-Resolution Photo Widget ───────────────────────────────────────────
class _PlantImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final int? memCacheWidth;
  final String? heroTag;

  const _PlantImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        memCacheWidth: memCacheWidth,
        placeholder: (_, __) => Container(
          color: AppColors.mintLight,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageGreen),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.mintLight,
          child: const Center(
            child: Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36),
          ),
        ),
      );
    } else {
      final cleanPath = ImageStorageService.resolveImagePathSync(url);
      final file = File(cleanPath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: fit,
          cacheWidth: memCacheWidth,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.mintLight,
            child: const Center(
              child: Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36),
            ),
          ),
        );
      } else {
        imageWidget = Container(
          color: AppColors.mintLight,
          child: const Center(
            child: Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36),
          ),
        );
      }
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}

// ─── Grid View Card ──────────────────────────────────────────────────────────
class _GridCard extends ConsumerWidget {
  final Discovery discovery;

  const _GridCard({required this.discovery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _DiscoveryDetailPage(discovery: discovery)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: RarityFrame.border(discovery.rarity),
          boxShadow: RarityFrame.shadows(discovery.rarity, [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo with quick favorite button
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: _PlantImage(
                      url: discovery.imagePath,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      heroTag: 'discovery_photo_${discovery.id}',
                    ),
                  ),
                  // Heart favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(discoveriesProvider.notifier).toggleFavorite(discovery.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(220),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          discovery.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 16,
                          color: discovery.isFavorite ? Colors.redAccent : AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ),
                  // Rarity badge (always visible, tap rare+ to trigger sparkles)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: RarityBadge(
                      rarity: discovery.rarity,
                      isFr: Localizations.localeOf(context).languageCode == 'fr',
                      compact: true,
                      onTap: discovery.rarity.isCelebratory
                          ? () => RarityCelebration.show(
                                context,
                                discovery.rarity,
                                isFr: Localizations.localeOf(context).languageCode == 'fr',
                              )
                          : null,
                    ),
                  ),
                  // XP bonus chip
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFFFFD54F)),
                          const SizedBox(width: 1),
                          Text(
                            '+${discovery.rarity.totalPoints}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Plant information
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discovery.commonName.isNotEmpty ? discovery.commonName : discovery.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.darkGreen),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    discovery.scientificName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          discovery.family,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: AppColors.sageGreen, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        dateFormat.format(discovery.discoveredAt),
                        style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List View Card ──────────────────────────────────────────────────────────
class _ListCard extends ConsumerWidget {
  final Discovery discovery;

  const _ListCard({required this.discovery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _DiscoveryDetailPage(discovery: discovery)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: RarityFrame.border(discovery.rarity),
          boxShadow: RarityFrame.shadows(discovery.rarity, [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]),
        ),
        child: Row(
          children: [
            // High-res thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: _PlantImage(
                  url: discovery.imagePath,
                  fit: BoxFit.cover,
                  memCacheWidth: 250,
                  heroTag: 'discovery_photo_list_${discovery.id}',
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            discovery.commonName.isNotEmpty ? discovery.commonName : discovery.scientificName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.darkGreen),
                          ),
                        ),
                        const SizedBox(width: 6),
                        RarityBadge(
                          rarity: discovery.rarity,
                          isFr: Localizations.localeOf(context).languageCode == 'fr',
                          compact: true,
                          onTap: discovery.rarity.isCelebratory
                              ? () => RarityCelebration.show(
                                    context,
                                    discovery.rarity,
                                    isFr: Localizations.localeOf(context).languageCode == 'fr',
                                  )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      discovery.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mintGreen.withAlpha(60),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            discovery.family,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: AppColors.darkGreen, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: discovery.rarity.softColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: discovery.rarity.color.withAlpha(80)),
                          ),
                          child: Text(
                            '+${discovery.rarity.totalPoints} XP',
                            style: TextStyle(fontSize: 9.5, color: discovery.rarity.color, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateFormat.format(discovery.discoveredAt),
                          style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Quick favorite action
            IconButton(
              icon: Icon(
                discovery.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: discovery.isFavorite ? Colors.redAccent : AppColors.secondaryText,
                size: 20,
              ),
              onPressed: () {
                ref.read(discoveriesProvider.notifier).toggleFavorite(discovery.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Discovery Detail Screen (Journal Entry) ─────────────────────────────────
class DiscoveryDetailPage extends ConsumerStatefulWidget {
  final Discovery discovery;
  final bool autoCelebrate;
  final Achievement? earnedBadge;
  final bool gardenLeveledUp;
  final int? newGardenLevel;

  const DiscoveryDetailPage({
    super.key,
    required this.discovery,
    this.autoCelebrate = false,
    this.earnedBadge,
    this.gardenLeveledUp = false,
    this.newGardenLevel,
  });

  @override
  ConsumerState<DiscoveryDetailPage> createState() => _DetailState();
}

typedef _DiscoveryDetailPage = DiscoveryDetailPage;

class _DetailState extends ConsumerState<DiscoveryDetailPage> {
  late Discovery _d;
  late TextEditingController _notesCtrl;
  bool _isNotesSaved = false;

  @override
  void initState() {
    super.initState();
    _d = widget.discovery;
    _notesCtrl = TextEditingController(text: _d.personalNotes ?? '');

    if (widget.autoCelebrate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Delay slightly (350ms) so navigation route transition finishes cleanly
        // and fireworks celebration is not clipped or swallowed.
        Future.delayed(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          final isFr = ref.read(localeProvider).languageCode == 'fr' ||
              Localizations.localeOf(context).languageCode == 'fr' ||
              l10n?.home == 'Accueil';

          void showFollowUpAlerts() {
            if (!mounted) return;
            if (widget.earnedBadge != null) {
              BadgeUnlockAlert.show(context, achievement: widget.earnedBadge!, isFr: isFr);
            } else if (widget.gardenLeveledUp && widget.newGardenLevel != null) {
              GardenUnlockAlert.show(
                context,
                level: widget.newGardenLevel!,
                unlockedItems: GardenState.levelItemUnlocks[widget.newGardenLevel!] ?? const [],
                isFr: isFr,
              );
            }
          }

          RarityCelebration.show(
            context,
            widget.discovery.rarity,
            isFr: isFr,
            force: true,
            onDone: showFollowUpAlerts,
          );
        });
      });
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool _isRefreshingWisdom = false;

  Future<void> _refreshBotanicalWisdom(bool isFr) async {
    if (_isRefreshingWisdom) return;
    setState(() => _isRefreshingWisdom = true);
    try {
      final aiService = ref.read(aiContentServiceProvider);
      final lang = isFr ? 'fr' : 'en';
      final newAi = await aiService.generateContent(
        _d.scientificName,
        _d.commonName,
        _d.family,
        lang,
      );
      final updated = _d.copyWith(
        aiContent: newAi,
        rarity: newAi.rarity ?? _d.rarity,
      );
      await ref.read(discoveriesProvider.notifier).updateDiscovery(updated);
      if (mounted) {
        setState(() {
          _d = updated;
          _isRefreshingWisdom = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFr
                  ? '✨ Sagesse botanique actualisée !'
                  : '✨ Botanical wisdom refreshed!',
            ),
            backgroundColor: AppColors.sageGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshingWisdom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFr
                  ? 'Impossible d\'actualiser la sagesse : $e'
                  : 'Could not refresh wisdom: $e',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _saveNotes() {
    final text = _notesCtrl.text.trim();
    final updated = _d.copyWith(personalNotes: text);
    ref.read(discoveriesProvider.notifier).updateDiscovery(updated);
    setState(() {
      _d = updated;
      _isNotesSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Field notes updated! ✓'),
        backgroundColor: AppColors.sageGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleFav() async {
    await ref.read(discoveriesProvider.notifier).toggleFavorite(_d.id);
    setState(() => _d = _d.copyWith(isFavorite: !_d.isFavorite));
  }

  Future<void> _updatePhoto(bool isFr) async {
    final cameraService = ref.read(cameraServiceProvider);
    final imageStorage = ref.read(imageStorageServiceProvider);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFr ? 'Mettre à jour la photo du spécimen' : 'Update Specimen Photo',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.darkGreen),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.mintGreen,
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.sageGreen),
                ),
                title: Text(isFr ? 'Prendre une photo' : 'Take a Photo', style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.mintGreen,
                  child: Icon(Icons.photo_library_rounded, color: AppColors.sageGreen),
                ),
                title: Text(isFr ? 'Choisir dans la galerie' : 'Choose from Gallery', style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await cameraService.pickImage(source);
    if (picked == null) return;

    // Save locally
    String newPath = await imageStorage.saveLocalSpecimen(picked.path, _d.id);

    // Sync to cloud if authenticated
    final auth = ref.read(authProvider);
    final userId = auth.user?.id;
    if (userId != null) {
      final cloudUrl = await imageStorage.uploadSpecimenToCloud(
        localPath: newPath,
        discoveryId: _d.id,
        userId: userId,
      );
      if (cloudUrl != null && cloudUrl.isNotEmpty) {
        newPath = cloudUrl;
      }
    }

    final updated = _d.copyWith(imagePath: newPath);
    await ref.read(discoveriesProvider.notifier).updateDiscovery(updated);
    if (mounted) {
      setState(() => _d = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFr ? 'Photo du spécimen mise à jour ! ✓' : 'Specimen photo updated! ✓'),
          backgroundColor: AppColors.sageGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Journal Entry'),
        content: Text('Remove "${_d.commonName}" from your nature journal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final nav = Navigator.of(context);
      final plantName = _d.commonName;

      // Pop detail screen back to collection list immediately
      nav.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text('🌿 Removed "$plantName" from your journal'),
          backgroundColor: AppColors.darkGreen,
          duration: const Duration(seconds: 2),
        ),
      );

      final imageStorage = ref.read(imageStorageServiceProvider);
      await imageStorage.deleteLocalSpecimen(_d.imagePath);
      await ref.read(discoveriesProvider.notifier).deleteDiscovery(_d.id);
    }
  }

  void _openFullScreenPhoto(BuildContext context, bool isFr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: _PlantImage(url: _d.imagePath, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: MediaQuery.of(ctx).padding.top + 10,
                right: 16,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).padding.bottom + 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _d.commonName.isNotEmpty ? _d.commonName : _d.scientificName,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _d.scientificName,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sageGreen.withAlpha(200),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _d.family,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isFr = l10n?.home == 'Accueil';
    final dateFormat = DateFormat(isFr ? 'd MMMM yyyy • HH:mm' : 'MMMM d, yyyy • h:mm a', isFr ? 'fr' : 'en');

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ─── Sliver App Bar with High-Resolution Photo ─────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.darkGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/collection');
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded, color: AppColors.darkGreen),
                tooltip: isFr ? 'Voir la photo complète' : 'View full photo',
                onPressed: () => _openFullScreenPhoto(context, isFr),
              ),
              IconButton(
                icon: const Icon(Icons.add_a_photo_outlined, color: AppColors.darkGreen),
                tooltip: isFr ? 'Changer la photo' : 'Update photo',
                onPressed: () => _updatePhoto(isFr),
              ),
              IconButton(
                icon: Icon(
                  _d.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _d.isFavorite ? Colors.redAccent : AppColors.secondaryText,
                ),
                tooltip: _d.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                onPressed: _toggleFav,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                tooltip: 'Delete entry',
                onPressed: _delete,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _openFullScreenPhoto(context, isFr),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PlantImage(
                      url: _d.imagePath,
                      fit: BoxFit.cover,
                      heroTag: 'discovery_photo_${_d.id}',
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.cream.withAlpha(230),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => _updatePhoto(isFr),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.darkGreen),
                              const SizedBox(width: 4),
                              Text(
                                isFr ? 'Changer photo' : 'Change photo',
                                style: const TextStyle(fontSize: 11, color: AppColors.darkGreen, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: Row(
                        children: [
                          const Icon(Icons.zoom_in_rounded, size: 14, color: AppColors.darkGreen),
                          const SizedBox(width: 4),
                          Text(
                            isFr ? 'Toucher pour zoomer' : 'Tap to zoom',
                            style: const TextStyle(fontSize: 11, color: AppColors.darkGreen, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Content ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Rarity tier (tap a rare+ badge to replay the sparkles)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        RarityBadge(
                          rarity: _d.rarity,
                          isFr: isFr,
                          onTap: _d.rarity.isCelebratory
                              ? () => RarityCelebration.show(context, _d.rarity, isFr: isFr, force: true)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _d.rarity.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _d.rarity.color.withAlpha(80)),
                          ),
                          child: Text(
                            '+${_d.rarity.totalPoints} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _d.rarity.color,
                            ),
                          ),
                        ),
                        if (_d.rarity.isCelebratory)
                        GestureDetector(
                          onTap: () => RarityCelebration.show(context, _d.rarity, isFr: isFr, force: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _d.rarity.color.withAlpha(150)),
                              boxShadow: [
                                BoxShadow(
                                  color: _d.rarity.color.withAlpha(35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  isFr ? 'Rejouer' : 'Replay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _d.rarity.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Why this rarity (from Gemini, kid-friendly)
                if (_d.aiContent?.rarityReason != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _d.aiContent!.rarityReason!,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: _d.rarity.color,
                      ),
                    ),
                  ),
                // Title and common name
                Text(
                  _d.commonName.isNotEmpty ? _d.commonName : _d.scientificName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkGreen,
                      ),
                ),
                Text(
                  _d.scientificName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondaryText,
                      ),
                ),
                const SizedBox(height: 8),

                // Discovered Date pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withAlpha(70),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.sageGreen),
                          const SizedBox(width: 5),
                          Text(
                            dateFormat.format(_d.discoveredAt),
                            style: const TextStyle(color: AppColors.sageGreen, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ─── 🏛️ Scientific Classification Card ────────────────────
                MossyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: AppColors.sageGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isFr ? 'Classification scientifique' : 'Scientific Classification',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGreen,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _TaxonomyRow(isFr ? 'Règne' : 'Kingdom', 'Plantae'),
                      _TaxonomyRow(isFr ? 'Famille' : 'Family', _d.family.isNotEmpty ? _d.family : (isFr ? 'Inconnu' : 'Unknown')),
                      _TaxonomyRow(isFr ? 'Genre' : 'Genus', _d.genus),
                      _TaxonomyRow(isFr ? 'Espèce' : 'Species', _d.scientificName),
                      if (_d.hasLocation) ...[
                        _TaxonomyRow(
                          isFr ? 'Coordonnées' : 'Coordinates',
                          '${_d.latitude!.toStringAsFixed(4)}°, ${_d.longitude!.toStringAsFixed(4)}°',
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── 📖 Generative Botanical Lore ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.sageGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          isFr ? 'Sagesse de Mossy' : 'Mossy Wisdom',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGreen,
                              ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _isRefreshingWisdom ? null : () => _refreshBotanicalWisdom(isFr),
                      icon: _isRefreshingWisdom
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageGreen),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16, color: AppColors.sageGreen),
                      label: Text(
                        _isRefreshingWisdom
                            ? (isFr ? 'Actualisation...' : 'Refreshing...')
                            : (isFr ? 'Actualiser' : 'Refresh Lore'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sageGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_d.aiContent != null) ...[
                  if (_d.aiContent!.introduction.isNotEmpty)
                    _Section(isFr ? '✨ La vibe & le super-pouvoir' : '✨ Vibe & Superpower', _d.aiContent!.introduction),

                  if (_d.aiContent!.description.isNotEmpty)
                    _Section(isFr ? '🌍 Son histoire & où la débusquer' : '🌍 Story & Where It Lives', _d.aiContent!.description),

                  if (_d.funFacts.isNotEmpty)
                    _BulletSection(
                      isFr ? '🤩 Usages amusants & anecdotes' : '🤩 Fun Uses & Cool Facts',
                      _d.funFacts,
                      Icons.lightbulb_outline_rounded,
                    ),

                  if (_d.observationTips.isNotEmpty)
                    _BulletSection(
                      isFr ? '🔍 Comment l\'observer & la chouchouter' : '🔍 How to Spot or Grow It',
                      _d.observationTips,
                      Icons.visibility_outlined,
                    ),

                  if (_d.safetyNote != null && _d.safetyNote!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withAlpha(60)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFr ? '🛡️ Conseil Explorateur' : '🛡️ Safe Explorer Tip',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _d.safetyNote!,
                                  style: const TextStyle(fontSize: 13, color: AppColors.darkGreen),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // ─── ✍️ Personal Field Observations & Notes ───────────────
                MossyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: AppColors.sageGreen, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isFr ? 'Notes de terrain personnelles' : 'Personal Field Notes',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGreen,
                                ),
                          ),
                          const Spacer(),
                          if (_isNotesSaved)
                            Text(
                              isFr ? 'Enregistré ✓' : 'Saved ✓',
                              style: const TextStyle(color: AppColors.sageGreen, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: isFr
                              ? 'Notez où vous l\'avez trouvé, la météo, les plantes voisines…'
                              : 'Record where you found it, weather, companion plants, or growth stage…',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.sageGreen, width: 2),
                          ),
                        ),
                        onChanged: (_) {
                          if (_isNotesSaved) {
                            setState(() => _isNotesSaved = false);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _saveNotes,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: Text(isFr ? 'Enregistrer' : 'Save Notes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sageGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Delete Button ──────────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    label: Text(
                      isFr ? 'Retirer du journal' : 'Remove from Journal',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _delete,
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botanical Taxonomy Row Widget ───────────────────────────────────────────
class _TaxonomyRow extends StatelessWidget {
  final String label;
  final String value;

  const _TaxonomyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontStyle: label == 'Species' || label == 'Genus' ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Helper ──────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGreen,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Bulleted List Section Helper ────────────────────────────────────────────
class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;

  const _BulletSection(this.title, this.items, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGreen,
                ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: AppColors.sageGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
