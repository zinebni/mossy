import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mossy_card.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/providers/app_providers.dart';

enum _SortOption {
  recent('Newest First'),
  oldest('Oldest First'),
  confidence('Highest Confidence'),
  name('Name (A–Z)');

  final String label;
  const _SortOption(this.label);
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
                          'My Collection',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkGreen,
                              ),
                        ),
                        discoveriesAsync.maybeWhen(
                          data: (list) => Text(
                            'Nature Discovery Journal • ${list.length} ${list.length == 1 ? 'find' : 'finds'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          orElse: () => const Text(
                            'Nature Discovery Journal',
                            style: TextStyle(
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
                    tooltip: 'Sort journal',
                    initialValue: _sortOption,
                    onSelected: (option) => setState(() => _sortOption = option),
                    itemBuilder: (context) => _SortOption.values.map((opt) {
                      return PopupMenuItem(
                        value: opt,
                        child: Text(
                          opt.label,
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
                    tooltip: _gridView ? 'Switch to list view' : 'Switch to grid view',
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
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by common name, species, family, or notes…',
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

            // ─── 3. Filter Chips (Favorites & Dynamic Botanical Families) ──
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
                      // "All" filter
                      ChoiceChip(
                        label: const Text('All'),
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
                          color: (!_favoritesOnly && _selectedFamily == null)
                              ? AppColors.darkGreen
                              : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // "Favorites" filter
                      FilterChip(
                        avatar: Icon(
                          _favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: _favoritesOnly ? Colors.redAccent : AppColors.secondaryText,
                        ),
                        label: Text('Favorites ($favoriteCount)'),
                        selected: _favoritesOnly,
                        onSelected: (selected) {
                          setState(() {
                            _favoritesOnly = selected;
                          });
                        },
                        selectedColor: Colors.redAccent.withAlpha(40),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _favoritesOnly ? Colors.redAccent : AppColors.secondaryText,
                        ),
                      ),

                      // Botanical Family Filter Chips
                      if (families.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...families.map((fam) {
                          final isSelected = _selectedFamily == fam;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(fam),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFamily = selected ? fam : null;
                                });
                              },
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
                onRefresh: () async {
                  ref.invalidate(discoveriesProvider);
                },
                child: discoveriesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.sageGreen),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Could not load discoveries: $e', textAlign: TextAlign.center),
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

                    // Apply sorting
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
                        itemBuilder: (ctx, i) => _GridCard(
                          discovery: list[i],
                        ).animate().fadeIn(delay: Duration(milliseconds: (i % 8) * 40)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) => _ListCard(
                        discovery: list[i],
                      ).animate().fadeIn(delay: Duration(milliseconds: (i % 8) * 40)),
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
  final bool favoritesOnly;
  final String? selectedFamily;
  final bool hasSearch;
  final int totalCount;

  const _EmptyState({
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
      title = 'No favorites marked';
      description = 'Tap the heart icon on any botanical find to save it here.';
    } else if (selectedFamily != null) {
      title = 'No $selectedFamily plants';
      description = 'You have not recorded any specimens in the $selectedFamily family yet.';
    } else if (hasSearch) {
      title = 'No matches found';
      description = 'Try searching with a different species, common name, or family.';
    } else {
      title = 'Your Journal is Empty';
      description = 'Start exploring nature! Identify wild leaves, flowers, and trees with the camera to build your personal field journal.';
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
                label: const Text('Start Exploring'),
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

  const _PlantImage({
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
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
    }

    final cleanPath = url.startsWith('file://') ? url.replaceFirst('file://', '') : url;
    if (cleanPath.isNotEmpty) {
      final file = File(cleanPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.mintLight,
            child: const Center(
              child: Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36),
            ),
          ),
        );
      }
    }

    return Container(
      color: AppColors.mintLight,
      child: const Center(
        child: Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36),
      ),
    );
  }
}

// ─── Grid View Card ──────────────────────────────────────────────────────────
class _GridCard extends ConsumerWidget {
  final Discovery discovery;

  const _GridCard({required this.discovery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d');
    final confidencePct = (discovery.identificationScore * 100).toStringAsFixed(0);

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
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
                    child: _PlantImage(url: discovery.imagePath, fit: BoxFit.cover),
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
                  // Confidence tag
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$confidencePct%',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
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
    final confidencePct = (discovery.identificationScore * 100).toStringAsFixed(0);

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                child: _PlantImage(url: discovery.imagePath, fit: BoxFit.cover),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discovery.commonName.isNotEmpty ? discovery.commonName : discovery.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.darkGreen),
                    ),
                    Text(
                      discovery.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
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
                            style: const TextStyle(fontSize: 10, color: AppColors.darkGreen, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$confidencePct% match',
                          style: const TextStyle(fontSize: 11, color: AppColors.sageGreen, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(discovery.discoveredAt),
                      style: const TextStyle(fontSize: 10, color: AppColors.mutedText),
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
class _DiscoveryDetailPage extends ConsumerStatefulWidget {
  final Discovery discovery;

  const _DiscoveryDetailPage({required this.discovery});

  @override
  ConsumerState<_DiscoveryDetailPage> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_DiscoveryDetailPage> {
  late Discovery _d;
  late TextEditingController _notesCtrl;
  bool _isNotesSaved = false;

  @override
  void initState() {
    super.initState();
    _d = widget.discovery;
    _notesCtrl = TextEditingController(text: _d.personalNotes ?? '');
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Journal Entry'),
        content: Text('Remove "${_d.commonName}" from your nature journal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(discoveriesProvider.notifier).deleteDiscovery(_d.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _openFullScreenPhoto(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _PlantImage(url: _d.imagePath, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

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
                  context.go('/home');
                }
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded, color: AppColors.darkGreen),
                tooltip: 'View full photo',
                onPressed: () => _openFullScreenPhoto(context),
              ),
              IconButton(
                icon: Icon(
                  _d.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _d.isFavorite ? Colors.redAccent : AppColors.secondaryText,
                ),
                tooltip: _d.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                onPressed: _toggleFav,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _openFullScreenPhoto(context),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _PlantImage(url: _d.imagePath, fit: BoxFit.cover),
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
                    const Positioned(
                      bottom: 12,
                      right: 16,
                      child: Row(
                        children: [
                          Icon(Icons.zoom_in_rounded, size: 14, color: AppColors.darkGreen),
                          SizedBox(width: 4),
                          Text('Tap to zoom', style: TextStyle(fontSize: 11, color: AppColors.darkGreen, fontWeight: FontWeight.w600)),
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

                // Confidence pill & Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintGreen.withAlpha(70),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(_d.identificationScore * 100).toStringAsFixed(0)}% • ${_d.confidenceLabel}',
                        style: const TextStyle(color: AppColors.sageGreen, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      dateFormat.format(_d.discoveredAt),
                      style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
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
                            'Scientific Classification',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGreen,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _TaxonomyRow('Kingdom', 'Plantae'),
                      _TaxonomyRow('Family', _d.family.isNotEmpty ? _d.family : 'Unknown'),
                      _TaxonomyRow('Genus', _d.genus),
                      _TaxonomyRow('Species', _d.scientificName),
                      if (_d.hasLocation) ...[
                        _TaxonomyRow(
                          'Coordinates',
                          '${_d.latitude!.toStringAsFixed(4)}°, ${_d.longitude!.toStringAsFixed(4)}°',
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ─── 📖 Generative Botanical Lore ──────────────────────────
                if (_d.aiContent != null) ...[
                  if (_d.aiContent!.introduction.isNotEmpty)
                    _Section('Botanical Overview', _d.aiContent!.introduction),

                  if (_d.aiContent!.description.isNotEmpty)
                    _Section('Morphology & Habitat', _d.aiContent!.description),

                  if (_d.funFacts.isNotEmpty)
                    _BulletSection(
                      'Fascinating Facts',
                      _d.funFacts,
                      Icons.lightbulb_outline_rounded,
                    ),

                  if (_d.observationTips.isNotEmpty)
                    _BulletSection(
                      'Field Observation Tips',
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
                                const Text(
                                  'Safety Note',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGreen),
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
                            'Personal Field Notes',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkGreen,
                                ),
                          ),
                          const Spacer(),
                          if (_isNotesSaved)
                            const Text(
                              'Saved ✓',
                              style: TextStyle(color: AppColors.sageGreen, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Record where you found it, weather, companion plants, or growth stage…',
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
                          label: const Text('Save Notes'),
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
                    label: const Text('Remove from Journal', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
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
