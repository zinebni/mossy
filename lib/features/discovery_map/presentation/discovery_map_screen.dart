import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/providers/app_providers.dart';

class DiscoveryMapScreen extends ConsumerWidget {
  const DiscoveryMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveriesAsync = ref.watch(discoveriesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
          onPressed: () => context.pop(),
        ),
        title: Text('Discovery Map', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
        elevation: 0,
      ),
      body: discoveriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sageGreen)),
        error: (e, _) => Center(child: Text('$e')),
        data: (discoveries) {
          final located = discoveries.where((d) => d.hasLocation).toList();
          if (located.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.map_outlined, size: 80, color: AppColors.mintGreen),
                  const SizedBox(height: 20),
                  Text('No locations yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                  const SizedBox(height: 10),
                  Text('Enable location when saving discoveries to see them on the map.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText)),
                ]),
              ),
            );
          }
          final center = LatLng(
            located.map((d) => d.latitude!).reduce((a, b) => a + b) / located.length,
            located.map((d) => d.longitude!).reduce((a, b) => a + b) / located.length,
          );
          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mossy.app',
              ),
              MarkerLayer(
                markers: located.map((d) => Marker(
                  point: LatLng(d.latitude!, d.longitude!),
                  width: 50, height: 50,
                  child: GestureDetector(
                    onTap: () => _showDiscoveryInfo(context, d),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.sageGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: AppColors.sageGreen.withAlpha(100), blurRadius: 8)],
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDiscoveryInfo(BuildContext context, Discovery d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.commonName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(d.scientificName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: AppColors.secondaryText)),
          const SizedBox(height: 8),
          Text('Family: ${d.family}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
          Text('Discovered ${_formatDate(d.discoveredAt)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.mutedText)),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}
