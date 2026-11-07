import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/providers/app_providers.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});
  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  String _search = '';
  bool _favoritesOnly = false;
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final discoveriesAsync = ref.watch(discoveriesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(child: Text('My Collection', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.darkGreen))),
              IconButton(
                icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: AppColors.sageGreen),
                onPressed: () => setState(() => _gridView = !_gridView),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search plants…',
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedText, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: const Text('Favourites'),
                selected: _favoritesOnly,
                onSelected: (v) => setState(() => _favoritesOnly = v),
                selectedColor: AppColors.sageGreen.withAlpha(60),
                checkmarkColor: AppColors.sageGreen,
              ),
            ]),
          ),
          Expanded(
            child: discoveriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageGreen)),
              error: (e, _) => Center(child: Text('$e')),
              data: (all) {
                var list = all.where((d) {
                  if (_favoritesOnly && !d.isFavorite) return false;
                  if (_search.isNotEmpty) {
                    return d.commonName.toLowerCase().contains(_search) ||
                        d.scientificName.toLowerCase().contains(_search) ||
                        d.family.toLowerCase().contains(_search);
                  }
                  return true;
                }).toList();

                if (list.isEmpty) {
                  return _EmptyState(favoritesOnly: _favoritesOnly, hasSearch: _search.isNotEmpty);
                }

                if (_gridView) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.78),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _GridCard(discovery: list[i]).animate().fadeIn(delay: Duration(milliseconds: i * 60)).scale(begin: const Offset(0.95, 0.95)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _ListCard(discovery: list[i]).animate().fadeIn(delay: Duration(milliseconds: i * 60)),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool favoritesOnly;
  final bool hasSearch;
  const _EmptyState({required this.favoritesOnly, required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.eco_outlined, size: 80, color: AppColors.mintGreen),
          const SizedBox(height: 20),
          Text(
            favoritesOnly ? 'No favourites yet' : hasSearch ? 'No results found' : 'Your collection is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen),
          ),
          const SizedBox(height: 10),
          Text(
            favoritesOnly ? 'Heart discoveries to save them here.' : hasSearch ? 'Try a different search term.' : 'Go to Explore to identify your first plant!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
          ),
        ]),
      ),
    );
  }
}

class _GridCard extends ConsumerWidget {
  final Discovery discovery;
  const _GridCard({required this.discovery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _openDetail(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: _PlantImage(url: discovery.imagePath, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(discovery.commonName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.darkGreen)),
              Text(discovery.scientificName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: AppColors.secondaryText)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.eco_rounded, size: 12, color: AppColors.sageGreen),
                const SizedBox(width: 3),
                Expanded(child: Text(discovery.family, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.mutedText))),
                if (discovery.isFavorite) const Icon(Icons.favorite_rounded, size: 14, color: Colors.redAccent),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _DiscoveryDetailPage(discovery: discovery)));
  }
}

class _ListCard extends ConsumerWidget {
  final Discovery discovery;
  const _ListCard({required this.discovery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _DiscoveryDetailPage(discovery: discovery))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
            child: SizedBox(width: 80, height: 80, child: _PlantImage(url: discovery.imagePath, fit: BoxFit.cover)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(discovery.commonName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.darkGreen)),
                Text(discovery.scientificName, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.secondaryText)),
                Text(discovery.family, style: const TextStyle(fontSize: 11, color: AppColors.mutedText)),
              ]),
            ),
          ),
          if (discovery.isFavorite) const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 18)),
        ]),
      ),
    );
  }
}

class _PlantImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const _PlantImage({required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: fit,
          errorBuilder: (_, __, ___) => Container(color: AppColors.mintLight, child: const Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36)));
    }
    return Container(color: AppColors.mintLight, child: const Icon(Icons.eco_rounded, color: AppColors.sageGreen, size: 36));
  }
}

// ─── Discovery Detail (inline) ────────────────────────────────────────────────
class _DiscoveryDetailPage extends ConsumerStatefulWidget {
  final Discovery discovery;
  const _DiscoveryDetailPage({required this.discovery});
  @override
  ConsumerState<_DiscoveryDetailPage> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_DiscoveryDetailPage> {
  late Discovery _d;
  late TextEditingController _notesCtrl;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.darkGreen,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(fit: StackFit.expand, children: [
              _PlantImage(url: _d.imagePath, fit: BoxFit.cover),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AppColors.cream.withAlpha(220)]))),
            ]),
          ),
          actions: [
            IconButton(
              icon: Icon(_d.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: _d.isFavorite ? Colors.redAccent : AppColors.secondaryText),
              onPressed: _toggleFav,
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(delegate: SliverChildListDelegate([
            Text(_d.commonName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
            Text(_d.scientificName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: AppColors.secondaryText)),
            const SizedBox(height: 4),
            Text('Family: ${_d.family}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.mintGreen.withAlpha(60), borderRadius: BorderRadius.circular(10)),
              child: Text(_d.confidenceLabel, style: const TextStyle(color: AppColors.sageGreen, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            if (_d.aiContent != null) ...[
              const SizedBox(height: 20),
              _Section('About', _d.aiContent!.introduction),
              _Section('Description', _d.aiContent!.description),
              if (_d.funFacts.isNotEmpty) _BulletSection('Fun Facts', _d.funFacts, Icons.lightbulb_outline_rounded),
              if (_d.observationTips.isNotEmpty) _BulletSection('Observation Tips', _d.observationTips, Icons.visibility_outlined),
              if (_d.safetyNote != null) Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.warning.withAlpha(60))),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_d.safetyNote!, style: const TextStyle(fontSize: 13, color: AppColors.darkGreen))),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            Text('Personal Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add your personal observations…',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
              ),
              onChanged: (_) => _saveNotes(),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              label: const Text('Delete Discovery', style: TextStyle(color: AppColors.error)),
              onPressed: _delete,
            ),
          ])),
        ),
      ]),
    );
  }

  Future<void> _toggleFav() async {
    await ref.read(discoveriesProvider.notifier).toggleFavorite(_d.id);
    setState(() => _d = _d.copyWith(isFavorite: !_d.isFavorite));
  }

  void _saveNotes() {
    final updated = _d.copyWith(personalNotes: _notesCtrl.text);
    ref.read(discoveriesProvider.notifier).updateDiscovery(updated);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Discovery'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(discoveriesProvider.notifier).deleteDiscovery(_d.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText, height: 1.5)),
      ]),
    );
  }
}

class _BulletSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  const _BulletSection(this.title, this.items, this.icon);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 16, color: AppColors.sageGreen),
            const SizedBox(width: 8),
            Expanded(child: Text(item, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText, height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}
