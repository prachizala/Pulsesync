import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../logic/providers.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  Color _getMarkerColor(String priority) {
    switch (priority) {
      case AppConstants.priorityCritical:
        return Colors.red;
      case AppConstants.priorityHigh:
        return Colors.deepOrange;
      case AppConstants.priorityMedium:
        return Colors.amber.shade700;
      case AppConstants.priorityLow:
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Operations Map'),
      ),
      body: incidentsAsync.when(
        data: (incidents) {
          final center = incidents.isNotEmpty
              ? LatLng(incidents.first.latitude, incidents.first.longitude)
              : const LatLng(37.7749, -122.4194);

          final markers = incidents.map((inc) {
            return Marker(
              point: LatLng(inc.latitude, inc.longitude),
              width: 50,
              height: 50,
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
                                backgroundColor: _getMarkerColor(inc.priority).withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(inc.description ?? 'No description provided.'),
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
                child: Icon(
                  Icons.location_on,
                  color: _getMarkerColor(inc.priority),
                  size: 40,
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pulsesync.app',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Map error: $err')),
      ),
    );
  }
}
