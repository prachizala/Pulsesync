import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../logic/location/location_service.dart';
import '../logic/providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLocating = false;
  bool _showRadarRings = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = ref.read(targetMapLocationProvider);
      if (target != null) {
        _mapController.move(target, AppConstants.defaultZoomDetailed);
        ref.read(targetMapLocationProvider.notifier).state = null;
      } else {
        _detectAndCenterLocation();
      }
    });
  }

  Future<void> _detectAndCenterLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationService.getCurrentPosition(context);
      if (position != null) {
        final userLatLng = LatLng(position.latitude, position.longitude);
        setState(() => _currentPosition = userLatLng);
        ref.read(userLocationProvider.notifier).state = userLatLng;
        _mapController.move(userLatLng, AppConstants.defaultZoomDetailed);
      }
    } catch (_) {
      // Fallback stays on India center
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Color _getMarkerColor(String priority) {
    switch (priority) {
      case AppConstants.priorityCritical:
        return Colors.red.shade700;
      case AppConstants.priorityHigh:
        return Colors.deepOrange;
      case AppConstants.priorityMedium:
        return Colors.amber.shade800;
      case AppConstants.priorityLow:
      default:
        return Colors.green.shade600;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case AppConstants.categorySOS:
        return Icons.crisis_alert_rounded;
      case AppConstants.categoryFire:
        return Icons.local_fire_department_rounded;
      case AppConstants.categoryMedical:
        return Icons.medical_services_rounded;
      case AppConstants.categoryFlood:
        return Icons.water_drop_rounded;
      case AppConstants.categoryRoadAccident:
        return Icons.car_crash_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    // Initial center is either user's live position or center of India
    final defaultCenter = _currentPosition ??
        const LatLng(AppConstants.defaultIndiaLat, AppConstants.defaultIndiaLon);
    final defaultZoom = _currentPosition != null
        ? AppConstants.defaultZoomDetailed
        : AppConstants.defaultZoomIndia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tactical Operations Map'),
        actions: [
          IconButton(
            tooltip: _showRadarRings ? 'Hide Radar Rings' : 'Show Radar Rings',
            icon: Icon(
              Icons.radar_rounded,
              color: _showRadarRings ? Colors.cyanAccent : Colors.white60,
            ),
            onPressed: () => setState(() => _showRadarRings = !_showRadarRings),
          ),
          IconButton(
            tooltip: 'Go to My Exact GPS Location',
            icon: _isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location),
            onPressed: _detectAndCenterLocation,
          ),
        ],
      ),
      body: incidentsAsync.when(
        data: (incidents) {
          final markers = <Marker>[];

          // 1. User's exact live location marker (Glowing Blue Pin)
          if (_currentPosition != null) {
            markers.add(
              Marker(
                point: _currentPosition!,
                width: 70,
                height: 70,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'You',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.circle, color: Colors.white, size: 10),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Incident markers
          for (final inc in incidents) {
            final color = _getMarkerColor(inc.priority);
            final icon = _getCategoryIcon(inc.category);

            markers.add(
              Marker(
                point: LatLng(inc.latitude, inc.longitude),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    inc.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Chip(
                                  label: Text(inc.priority.toUpperCase()),
                                  backgroundColor: color.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Category: ${inc.category}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(inc.description ?? 'No description provided.'),
                            const SizedBox(height: 10),
                            Text(
                              'Location: ${inc.latitude.toStringAsFixed(4)}, ${inc.longitude.toStringAsFixed(4)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  inc.isSynced ? Icons.cloud_done : Icons.cloud_off,
                                  size: 16,
                                  color: inc.isSynced ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(inc.isSynced ? 'Synced to HQ' : 'Offline (Pending Sync)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Icon(icon, color: Colors.white, size: 18),
                      ),
                      Icon(Icons.arrow_drop_down, color: color, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: defaultCenter,
                  initialZoom: defaultZoom,
                  minZoom: 3.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.pulsesync.app',
                  ),
                  if (_showRadarRings && _currentPosition != null)
                    CircleLayer(
                      circles: [
                        // 500m Red Hazard Ring
                        CircleMarker(
                          point: _currentPosition!,
                          radius: 500,
                          useRadiusInMeter: true,
                          color: Colors.redAccent.withValues(alpha: 0.08),
                          borderColor: Colors.redAccent.withValues(alpha: 0.7),
                          borderStrokeWidth: 1.5,
                        ),
                        // 1000m Orange Warning Ring
                        CircleMarker(
                          point: _currentPosition!,
                          radius: 1000,
                          useRadiusInMeter: true,
                          color: Colors.orangeAccent.withValues(alpha: 0.04),
                          borderColor: Colors.orangeAccent.withValues(alpha: 0.5),
                          borderStrokeWidth: 1.2,
                        ),
                        // 2500m Cyan Perimeter Ring
                        CircleMarker(
                          point: _currentPosition!,
                          radius: 2500,
                          useRadiusInMeter: true,
                          color: Colors.cyan.withValues(alpha: 0.02),
                          borderColor: Colors.cyan.withValues(alpha: 0.4),
                          borderStrokeWidth: 1.0,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Floating controls (My Location and Zoom)
              Positioned(
                right: 16,
                bottom: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_my_location',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blueAccent,
                      onPressed: _detectAndCenterLocation,
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom + 1);
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom - 1);
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Map error: $err')),
      ),
    );
  }
}
