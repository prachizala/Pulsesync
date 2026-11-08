import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants.dart';
import '../data/local/database.dart';
import '../logic/providers.dart';

class IncidentDetailModal extends ConsumerWidget {
  final LocalIncident incident;
  final VoidCallback onNavigateToMap;

  const IncidentDetailModal({
    super.key,
    required this.incident,
    required this.onNavigateToMap,
  });

  static void show(BuildContext context, LocalIncident incident, VoidCallback onNavigateToMap) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncidentDetailModal(
        incident: incident,
        onNavigateToMap: onNavigateToMap,
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case AppConstants.priorityCritical:
        return Colors.red;
      case AppConstants.priorityHigh:
        return Colors.deepOrange;
      case AppConstants.priorityMedium:
        return Colors.amber.shade800;
      case AppConstants.priorityLow:
      default:
        return Colors.green;
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

  String _calculateDistanceAndEta(LatLng? userPos) {
    if (userPos == null) return 'Distance unavailable (GPS disabled)';
    final incPos = LatLng(incident.latitude, incident.longitude);
    const distanceCalculator = Distance();
    final meters = distanceCalculator.as(LengthUnit.Meter, userPos, incPos);

    if (meters < 1000) {
      final walkEta = (meters / 80).ceil(); // ~80m per min walk
      return '${meters.toInt()} m away • ~$walkEta min walk ETA';
    } else {
      final km = (meters / 1000.0);
      final driveEta = (km * 2).ceil(); // ~30 km/h in city disaster zone
      return '${km.toStringAsFixed(1)} km away • ~$driveEta min drive ETA';
    }
  }

  bool _isInHazardZone(LatLng? userPos) {
    if (userPos == null) return false;
    final incPos = LatLng(incident.latitude, incident.longitude);
    const distanceCalculator = Distance();
    return distanceCalculator.as(LengthUnit.Meter, userPos, incPos) <= 500;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userPos = ref.watch(userLocationProvider);
    final distanceStr = _calculateDistanceAndEta(userPos);
    final isHazard = _isInHazardZone(userPos);
    final dateStr = DateFormat('EEEE, MMM d, yyyy • HH:mm').format(incident.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141920) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Category Icon + Title + Priority
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _getPriorityColor(incident.priority).withValues(alpha: 0.15),
                child: Icon(
                  _getCategoryIcon(incident.category),
                  color: _getPriorityColor(incident.priority),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(incident.priority).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            incident.priority.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(incident.priority),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: incident.isSynced
                                ? Colors.teal.withValues(alpha: 0.2)
                                : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                incident.isSynced ? Icons.cloud_done : Icons.cloud_queue,
                                size: 12,
                                color: incident.isSynced ? Colors.teal : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                incident.isSynced ? 'Synced to HQ' : 'Queued (Offline)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: incident.isSynced ? Colors.teal : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Proximity & Hazard Warning Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isHazard
                  ? Colors.red.withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF1E2631) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHazard
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isHazard ? Icons.warning_rounded : Icons.navigation_rounded,
                  color: isHazard ? Colors.redAccent : Colors.blueAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHazard ? '⚠️ CRITICAL PROXIMITY: Within 500m Hazard Zone' : 'Tactical Proximity',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isHazard ? Colors.redAccent : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      Text(
                        distanceStr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Description & Details
          Text(
            'Situation Report:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            incident.description != null && incident.description!.isNotEmpty
                ? incident.description!
                : 'No additional situation details provided.',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),

          const SizedBox(height: 12),
          Text(
            'GPS Coordinates: ${incident.latitude.toStringAsFixed(5)}, ${incident.longitude.toStringAsFixed(5)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          Text(
            'Reported: $dateStr',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),

          const SizedBox(height: 20),

          // Action Buttons: Locate on Map + Status Toggle
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Show on Map'),
                  onPressed: () {
                    ref.read(targetMapLocationProvider.notifier).state =
                        LatLng(incident.latitude, incident.longitude);
                    Navigator.pop(context);
                    onNavigateToMap();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: incident.status == 'resolved' ? Colors.green : Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(incident.status == 'resolved' ? Icons.check_circle_rounded : Icons.update_rounded),
                  label: Text(
                    incident.status == 'resolved' ? 'Resolved' : 'Mark In-Progress',
                  ),
                  onPressed: () async {
                    final newStatus = incident.status == 'reported' ? 'in_progress' : 'resolved';
                    final db = ref.read(databaseProvider);
                    await db.updateIncidentStatus(incident.clientId, newStatus);
                    await db.enqueueSync(
                      entityType: 'incident',
                      entityId: incident.clientId,
                      operation: 'update',
                      payload: '{"status": "$newStatus"}',
                    );
                    ref.read(syncServiceProvider).triggerSync();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
