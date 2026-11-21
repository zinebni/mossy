import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/discovery.dart';
import '../../../shared/models/discovery_rarity.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/rarity_widgets.dart';
import '../../collection/presentation/collection_screen.dart';

/// Real OpenStreetMap explorer showing where the authenticated user discovered their plants.
/// Uses exclusively real discovery GPS coordinates from [discoveriesProvider] — zero mock/demo pins.
class DiscoveryMapScreen extends ConsumerStatefulWidget {
  const DiscoveryMapScreen({super.key});

  @override
  ConsumerState<DiscoveryMapScreen> createState() => _DiscoveryMapScreenState();
}

class _DiscoveryMapScreenState extends ConsumerState<DiscoveryMapScreen> {
  late final MapController _mapController;
  Discovery? _selectedDiscovery;
  LatLng? _userLocation;
  bool _isLocating = false;
  bool _hasInitialFitted = false;

  // Neutral initial coordinate when no GPS or plant coordinates are available yet.
  static const LatLng _defaultCenter = LatLng(48.8566, 2.3522);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _detectInitialUserLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _detectInitialUserLocation() async {
    try {
      final locService = ref.read(locationServiceProvider);
      final pos = await locService.getCurrentPosition(
        timeLimit: const Duration(seconds: 4),
      );
      if (pos != null && mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      debugPrint('[Mossy] Non-fatal initial location detection error: $e');
    }
  }

  Future<void> _locateUser({bool animate = true}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      final locService = ref.read(locationServiceProvider);
      final pos = await locService.getCurrentPosition(
        timeLimit: const Duration(seconds: 6),
      );
      if (pos != null && mounted) {
        final target = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _userLocation = target;
          _isLocating = false;
        });
        if (animate) {
          _mapController.move(target, 15.5);
        }
      } else if (mounted) {
        setState(() => _isLocating = false);
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFr
                  ? '📍 Impossible d\'obtenir votre position GPS actuelle.'
                  : '📍 Could not retrieve your current GPS location.',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
      }
      debugPrint('[Mossy] Locate user error: $e');
    }
  }

  void _fitAllDiscoveries(List<Discovery> located, [List<LatLng>? pointsOverride]) {
    if (located.isEmpty) return;
    if (located.length == 1) {
      _mapController.move(
        LatLng(located.first.latitude!, located.first.longitude!),
        15.0,
      );
      return;
    }

    try {
      final points = pointsOverride ?? located.map((d) => LatLng(d.latitude!, d.longitude!)).toList();
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 100, bottom: 120, left: 60, right: 60),
          maxZoom: 16.0,
        ),
      );
    } catch (e) {
      debugPrint('[Mossy] Fit camera error: $e');
      final first = located.first;
      _mapController.move(LatLng(first.latitude!, first.longitude!), 14.0);
    }
  }

  /// Groups discoveries sharing the same or nearby GPS coordinates (within ~18m).
  List<_DiscoveryMapLocationGroup> _groupNearbyDiscoveries(List<Discovery> discoveries) {
    final List<_DiscoveryMapLocationGroup> groups = [];
    const double threshold = 0.00018;

    for (final d in discoveries) {
      bool added = false;
      for (final g in groups) {
        final latDiff = (g.anchor.latitude - d.latitude!).abs();
        final lonDiff = (g.anchor.longitude - d.longitude!).abs();
        if (latDiff < threshold && lonDiff < threshold) {
          g.discoveries.add(d);
          added = true;
          break;
        }
      }
      if (!added) {
        groups.add(_DiscoveryMapLocationGroup(
          anchor: LatLng(d.latitude!, d.longitude!),
          discoveries: [d],
        ));
      }
    }
    return groups;
  }

  /// Calculates visual coordinates for discoveries:
  /// - Single discoveries stay at anchor coordinates.
  /// - Multiple discoveries at the same spot branch out radially in flower petal formation so every pin is reachable.
  List<_PositionedDiscovery> _computePositionedDiscoveries(List<_DiscoveryMapLocationGroup> groups) {
    final List<_PositionedDiscovery> result = [];

    for (final group in groups) {
      final count = group.discoveries.length;
      final anchor = group.anchor;

      if (count == 1) {
        result.add(_PositionedDiscovery(
          discovery: group.discoveries.first,
          displayPosition: anchor,
          groupIndex: 0,
          groupSize: 1,
          groupAnchor: anchor,
        ));
      } else {
        // Petal offset radius: ~0.00020 to 0.00030 degrees (~18-28m ground distance)
        final double radius = count <= 3
            ? 0.00020
            : (count <= 6 ? 0.00026 : 0.00032);
        final cosLat = math.cos(anchor.latitude * math.pi / 180.0);
        final lonScale = cosLat.abs() > 0.0001 ? cosLat.abs() : 1.0;

        for (int i = 0; i < count; i++) {
          final d = group.discoveries[i];
          final angle = (2 * math.pi * i / count) - (math.pi / 2); // Start at 12 o'clock
          final lat = anchor.latitude + (radius * math.cos(angle));
          final lon = anchor.longitude + ((radius / lonScale) * math.sin(angle));

          result.add(_PositionedDiscovery(
            discovery: d,
            displayPosition: LatLng(lat, lon),
            groupIndex: i,
            groupSize: count,
            groupAnchor: anchor,
          ));
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final discoveriesAsync = ref.watch(discoveriesProvider);
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          try {
            context.go('/home');
          } catch (_) {}
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: discoveriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.sageGreen),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                isFr ? 'Impossible de charger la carte : $e' : 'Failed to load map: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (discoveries) {
            // Strictly real discoveries with GPS coordinates belonging to the authenticated user.
            final located = discoveries.where((d) => d.hasLocation).toList();
            final locationGroups = _groupNearbyDiscoveries(located);
            final positionedDiscoveries = _computePositionedDiscoveries(locationGroups);
            final Map<String, _PositionedDiscovery> positionedMap = {
              for (final pd in positionedDiscoveries) pd.discovery.id: pd,
            };

            // Fit camera on first data arrival
            if (located.isNotEmpty && !_hasInitialFitted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_hasInitialFitted) {
                  _hasInitialFitted = true;
                  final displayPoints = positionedDiscoveries.map((pd) => pd.displayPosition).toList();
                  _fitAllDiscoveries(located, displayPoints);
                }
              });
            }

            final initialCenter = located.isNotEmpty
                ? LatLng(located.first.latitude!, located.first.longitude!)
                : (_userLocation ?? _defaultCenter);

            return Stack(
              children: [
                // ─── 1. OpenStreetMap Layer ─────────────────────────────────
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: located.isNotEmpty ? 14.0 : 12.0,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    onTap: (_, __) {
                      if (_selectedDiscovery != null) {
                        setState(() => _selectedDiscovery = null);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.mossy.app',
                    ),
                    // Plant Discovery Markers Layer
                    MarkerLayer(
                      markers: [
                        // Group center anchor hubs for spots with multiple discoveries
                        for (final group in locationGroups)
                          if (group.discoveries.length > 1)
                            Marker(
                              point: group.anchor,
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              child: _LocationGroupCenterHub(
                                count: group.discoveries.length,
                                onTap: () {
                                  final currentId = _selectedDiscovery?.id;
                                  final next = group.discoveries.firstWhere(
                                    (d) => d.id != currentId,
                                    orElse: () => group.discoveries.first,
                                  );
                                  setState(() => _selectedDiscovery = next);
                                  final pos = positionedMap[next.id]?.displayPosition ?? group.anchor;
                                  _mapController.move(
                                    pos,
                                    _mapController.camera.zoom.clamp(15.0, 17.5),
                                  );
                                },
                              ),
                            ),
                        // Individual positioned plant markers
                        ...positionedDiscoveries.map((pd) {
                          final isSelected = _selectedDiscovery?.id == pd.discovery.id;
                          return Marker(
                            point: pd.displayPosition,
                            width: isSelected ? 58 : 46,
                            height: isSelected ? 58 : 46,
                            alignment: Alignment.center,
                            child: _PlantMapMarker(
                              discovery: pd.discovery,
                              isSelected: isSelected,
                              groupIndex: pd.groupIndex,
                              groupSize: pd.groupSize,
                              onTap: () {
                                setState(() => _selectedDiscovery = pd.discovery);
                                _mapController.move(
                                  pd.displayPosition,
                                  _mapController.camera.zoom.clamp(14.0, 17.0),
                                );
                              },
                            ),
                          );
                        }),
                        // "You are here" Device Location Pin
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            child: const _UserLocationMarker(),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),

                // ─── 2. Top Header Bar & Discoveries Count Chip ─────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.darkGreen),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              try {
                                context.go('/home');
                              } catch (_) {}
                            }
                          },
                        ),
                      ),
                      // Mapped count pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.sageGreen.withAlpha(120)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🗺️', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              isFr
                                  ? '${located.length} ${located.length == 1 ? 'plante sur la carte' : 'plantes sur la carte'}'
                                  : '${located.length} ${located.length == 1 ? 'Plant Mapped' : 'Plants Mapped'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── 3. Right-side Floating Controls ────────────────────────
                Positioned(
                  right: 16,
                  bottom: _selectedDiscovery != null ? 220 : 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fit all plants button (only active when plants are located)
                      if (located.isNotEmpty) ...[
                        _MapControlButton(
                          icon: Icons.filter_center_focus_rounded,
                          tooltip: isFr ? 'Voir toutes mes plantes' : 'Fit all plants',
                          onTap: () {
                            final displayPoints = positionedDiscoveries.map((pd) => pd.displayPosition).toList();
                            _fitAllDiscoveries(located, displayPoints);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      // My location button
                      _MapControlButton(
                        icon: _isLocating ? Icons.hourglass_top_rounded : Icons.my_location_rounded,
                        tooltip: isFr ? 'Ma position' : 'My location',
                        isLoading: _isLocating,
                        onTap: () => _locateUser(animate: true),
                      ),
                      const SizedBox(height: 10),
                      // Zoom in (+)
                      _MapControlButton(
                        icon: Icons.add_rounded,
                        tooltip: isFr ? 'Zoomer' : 'Zoom in',
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                      ),
                      const SizedBox(height: 6),
                      // Zoom out (-)
                      _MapControlButton(
                        icon: Icons.remove_rounded,
                        tooltip: isFr ? 'Dézoomer' : 'Zoom out',
                        onTap: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                      ),
                    ],
                  ),
                ),

                // ─── 4. Selected Discovery Preview Card ─────────────────────
                if (_selectedDiscovery != null) () {
                  final currentGroup = locationGroups.firstWhere(
                    (g) => g.discoveries.any((d) => d.id == _selectedDiscovery!.id),
                    orElse: () => _DiscoveryMapLocationGroup(
                      anchor: LatLng(_selectedDiscovery!.latitude!, _selectedDiscovery!.longitude!),
                      discoveries: [_selectedDiscovery!],
                    ),
                  );

                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                    child: _DiscoveryMapPreviewCard(
                      discovery: _selectedDiscovery!,
                      locationGroup: currentGroup.discoveries,
                      isFr: isFr,
                      onSelectDiscovery: (next) {
                        setState(() => _selectedDiscovery = next);
                        final pos = positionedMap[next.id]?.displayPosition ??
                            LatLng(next.latitude!, next.longitude!);
                        _mapController.move(pos, _mapController.camera.zoom.clamp(14.0, 17.5));
                      },
                      onClose: () => setState(() => _selectedDiscovery = null),
                      onViewDetail: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DiscoveryDetailPage(discovery: _selectedDiscovery!),
                          ),
                        );
                      },
                    ),
                  );
                }(),

                // ─── 5. Empty State Helper (When 0 plants have location) ─────
                if (located.isEmpty)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    child: _EmptyDiscoveriesBanner(
                      isFr: isFr,
                      onExplore: () => context.go('/explore'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Plant Map Marker ────────────────────────────────────────────────────────
class _PlantMapMarker extends StatelessWidget {
  final Discovery discovery;
  final bool isSelected;
  final int groupIndex;
  final int groupSize;
  final VoidCallback onTap;

  const _PlantMapMarker({
    required this.discovery,
    required this.isSelected,
    this.groupIndex = 0,
    this.groupSize = 1,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarity = discovery.rarity;
    final size = isSelected ? 54.0 : 44.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Marker circle with rarity glow
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: isSelected ? rarity.color : rarity.color.withAlpha(220),
                width: isSelected ? 3.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? rarity.color.withAlpha(140)
                      : Colors.black.withAlpha(35),
                  blurRadius: isSelected ? 12 : 6,
                  spreadRadius: isSelected ? 2 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: _buildPlantThumbnail(discovery.imagePath, rarity),
            ),
          ),
          // Rarity emoji indicator
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: rarity.color, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 4),
                ],
              ),
              child: Text(
                rarity.emoji,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          // Group index badge when multiple discoveries are at the same spot
          if (groupSize > 1)
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? rarity.color : AppColors.darkGreen,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(35), blurRadius: 3),
                  ],
                ),
                child: Text(
                  '${groupIndex + 1}/$groupSize',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlantThumbnail(String path, DiscoveryRarity rarity) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(rarity),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(rarity),
      );
    }
    return _fallback(rarity);
  }

  Widget _fallback(DiscoveryRarity rarity) {
    return Container(
      color: rarity.softColor,
      child: Center(
        child: Icon(Icons.eco_rounded, color: rarity.color, size: 22),
      ),
    );
  }
}

// ─── "You Are Here" Device Location Marker ───────────────────────────────────
class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2196F3).withAlpha(50),
          ),
        ),
        // Middle ring
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withAlpha(100),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        // Inner blue dot
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }
}

// ─── Floating Discovery Preview Card ─────────────────────────────────────────
class _DiscoveryMapPreviewCard extends StatelessWidget {
  final Discovery discovery;
  final List<Discovery> locationGroup;
  final bool isFr;
  final ValueChanged<Discovery>? onSelectDiscovery;
  final VoidCallback onClose;
  final VoidCallback onViewDetail;

  const _DiscoveryMapPreviewCard({
    required this.discovery,
    this.locationGroup = const [],
    required this.isFr,
    this.onSelectDiscovery,
    required this.onClose,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final rarity = discovery.rarity;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: RarityFrame.border(rarity),
        boxShadow: RarityFrame.shadows(rarity, [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ]),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location group carousel bar if multiple plants are at this spot
          if (locationGroup.length > 1) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.mintLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sageGreen.withAlpha(120)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.darkGreen),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 28),
                    tooltip: isFr ? 'Plante précédente' : 'Previous plant',
                    onPressed: () {
                      final currIdx = locationGroup.indexWhere((d) => d.id == discovery.id);
                      final prevIdx = (currIdx - 1 + locationGroup.length) % locationGroup.length;
                      onSelectDiscovery?.call(locationGroup[prevIdx]);
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📍', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        isFr
                            ? 'Plante ${locationGroup.indexWhere((d) => d.id == discovery.id) + 1} sur ${locationGroup.length} à cet endroit'
                            : 'Plant ${locationGroup.indexWhere((d) => d.id == discovery.id) + 1} of ${locationGroup.length} at this spot',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.darkGreen),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 28),
                    tooltip: isFr ? 'Plante suivante' : 'Next plant',
                    onPressed: () {
                      final currIdx = locationGroup.indexWhere((d) => d.id == discovery.id);
                      final nextIdx = (currIdx + 1) % locationGroup.length;
                      onSelectDiscovery?.call(locationGroup[nextIdx]);
                    },
                  ),
                ],
              ),
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: _buildImage(discovery.imagePath, rarity),
                ),
              ),
              const SizedBox(width: 12),
              // Plant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discovery.commonName.isNotEmpty
                          ? discovery.commonName
                          : discovery.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.darkGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        RarityBadge(rarity: rarity, compact: true, isFr: isFr),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: rarity.softColor,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: rarity.color.withAlpha(80)),
                          ),
                          child: Text(
                            '+${rarity.totalPoints} XP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: rarity.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 8),
          // Metadata + Action button row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.mutedText),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(discovery.discoveredAt),
                          style: const TextStyle(fontSize: 10.5, color: AppColors.mutedText, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, size: 11, color: AppColors.sageGreen),
                        const SizedBox(width: 4),
                        Text(
                          '${discovery.latitude!.toStringAsFixed(4)}°, ${discovery.longitude!.toStringAsFixed(4)}°',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.sageGreen, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onViewDetail,
                icon: const Icon(Icons.menu_book_rounded, size: 15),
                label: Text(isFr ? 'Voir la fiche' : 'View in Journal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sageGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String path, DiscoveryRarity rarity) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(rarity),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(rarity),
      );
    }
    return _fallback(rarity);
  }

  Widget _fallback(DiscoveryRarity rarity) {
    return Container(
      color: rarity.softColor,
      child: Center(
        child: Icon(Icons.eco_rounded, color: rarity.color, size: 24),
      ),
    );
  }
}

// ─── Floating Control Button ─────────────────────────────────────────────────
class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isLoading;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isLoading ? null : onTap,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sageGreen),
                    )
                  : Icon(icon, color: AppColors.darkGreen, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State Banner ──────────────────────────────────────────────────────
class _EmptyDiscoveriesBanner extends StatelessWidget {
  final bool isFr;
  final VoidCallback onExplore;

  const _EmptyDiscoveriesBanner({
    required this.isFr,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sageGreen.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mintLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.explore_rounded, color: AppColors.sageGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isFr ? 'Aucune plante cartographiée' : 'No Mapped Plants Yet',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.darkGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  isFr
                      ? 'Photographiez une plante dehors pour la voir sur la carte !'
                      : 'Photograph a plant outside to see it on your map!',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onExplore,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sageGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isFr ? 'Explorer' : 'Explore',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location Group Center Hub ───────────────────────────────────────────────
class _LocationGroupCenterHub extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _LocationGroupCenterHub({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkGreen,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(45),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Models for Map Coordinate Clustering ────────────────────────────
class _DiscoveryMapLocationGroup {
  final LatLng anchor;
  final List<Discovery> discoveries;

  _DiscoveryMapLocationGroup({
    required this.anchor,
    required this.discoveries,
  });
}

class _PositionedDiscovery {
  final Discovery discovery;
  final LatLng displayPosition;
  final int groupIndex;
  final int groupSize;
  final LatLng groupAnchor;

  const _PositionedDiscovery({
    required this.discovery,
    required this.displayPosition,
    required this.groupIndex,
    required this.groupSize,
    required this.groupAnchor,
  });
}
