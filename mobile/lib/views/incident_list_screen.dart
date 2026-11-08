import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants.dart';
import '../logic/location/location_service.dart';
import '../logic/providers.dart';
import 'emergency_guide_screen.dart';
import 'incident_report_screen.dart';
import 'map_screen.dart';
import 'night_beacon_screen.dart';
import 'sos_beacon_dialog.dart';

class IncidentListScreen extends ConsumerStatefulWidget {
  const IncidentListScreen({super.key});

  @override
  ConsumerState<IncidentListScreen> createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends ConsumerState<IncidentListScreen> {
  int _currentIndex = 0;
  bool _isManualSyncing = false;
  bool _isLocationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final granted = await LocationService.isLocationPermissionGranted();
    if (mounted) setState(() => _isLocationEnabled = granted);
  }

  Future<void> _requestLocationPermission() async {
    final granted = await LocationService.requestLocationPermissionWithDialog(context);
    if (mounted) {
      setState(() => _isLocationEnabled = granted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted ? 'Location tracking is active.' : 'Location permission denied.',
          ),
          backgroundColor: granted ? Colors.teal : Colors.orange,
        ),
      );
    }
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

  Future<void> _performManualSync() async {
    setState(() => _isManualSyncing = true);
    final syncService = ref.read(syncServiceProvider);
    final success = await syncService.triggerSync();
    if (mounted) {
      setState(() => _isManualSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Sync completed successfully!' : 'Sync failed. Working in offline mode.',
          ),
          backgroundColor: success ? Colors.teal : Colors.orange,
        ),
      );
    }
  }

  void _showServerIpDialog() {
    final client = ref.read(apiClientProvider);
    final controller = TextEditingController(text: client.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Backend Server URL', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the PC Wi-Fi IP address where the FastAPI server is running (e.g. http://192.168.1.5:8000/api/v1):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Server Base URL',
                hintText: 'http://192.168.1.5:8000/api/v1',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.text = AppConstants.defaultBaseUrl;
            },
            child: const Text('Reset Default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                client.setBaseUrl(newUrl);
                Navigator.pop(ctx);
                _performManualSync();
              }
            },
            child: const Text('Save & Sync'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 1) {
      return Scaffold(
        body: const MapScreen(),
        bottomNavigationBar: _buildBottomNav(),
        floatingActionButton: _buildFab(),
      );
    }

    final incidentsAsync = ref.watch(incidentsStreamProvider);
    final connectivityAsync = ref.watch(connectivityStreamProvider);

    final isOffline = connectivityAsync.maybeWhen(
      data: (results) => results.every((r) => r == ConnectivityResult.none),
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('PulseSync Dispatch'),
        actions: [
          // 1-Tap SOS Emergency Beacon Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.crisis_alert_rounded, size: 16),
              label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              onPressed: () => SosBeaconDialog.show(context),
            ),
          ),
          IconButton(
            tooltip: _isLocationEnabled ? 'Location Tracking Allowed' : 'Allow Location Tracking',
            icon: Icon(
              _isLocationEnabled ? Icons.location_on : Icons.location_off,
              color: _isLocationEnabled ? Colors.greenAccent : Colors.amberAccent,
            ),
            onPressed: _requestLocationPermission,
          ),
          IconButton(
            tooltip: 'Sync Now',
            icon: _isManualSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.sync),
            onPressed: _isManualSyncing ? null : _performManualSync,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E1E2C), Color(0xFFE53935)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.shield_rounded, size: 40, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'PulseSync Operations',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Offline-First Emergency Dispatch',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.crisis_alert_rounded, color: Colors.redAccent),
              title: const Text('Instant SOS Distress Beacon', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Trigger immediate 1-tap distress signal'),
              onTap: () {
                Navigator.pop(context);
                SosBeaconDialog.show(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.medical_services_rounded, color: Colors.teal),
              title: const Text('Offline First-Aid Survival Guide'),
              subtitle: const Text('CPR, Bleeding, Burns, Snakebite steps'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyGuideScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_rounded, color: Colors.amber),
              title: const Text('Night Rescue Strobe Beacon'),
              subtitle: const Text('High-visibility signal for dark disaster zones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NightBeaconScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                _isLocationEnabled ? Icons.location_on : Icons.location_off,
                color: _isLocationEnabled ? Colors.green : Colors.orange,
              ),
              title: Text(_isLocationEnabled ? 'GPS Tracking Active' : 'Enable Location Permission'),
              onTap: () {
                Navigator.pop(context);
                _requestLocationPermission();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_rounded),
              title: const Text('Force Cloud Sync Now'),
              onTap: () {
                Navigator.pop(context);
                _performManualSync();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dns_rounded, color: Colors.blueAccent),
              title: const Text('Backend Server IP'),
              subtitle: Text(ref.read(apiClientProvider).baseUrl),
              onTap: () {
                Navigator.pop(context);
                _showServerIpDialog();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Connection status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: isOffline ? Colors.orange.shade800 : Colors.teal.shade700,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  isOffline
                      ? 'Offline Mode - Changes queued locally in Drift'
                      : 'Connected - Real-time auto-sync active',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (!_isLocationEnabled)
            InkWell(
              onTap: _requestLocationPermission,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.amber.shade900,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_disabled_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Location permission needed. Tap to allow.',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: incidentsAsync.when(
              data: (incidents) {
                final criticalCount = incidents.where((i) => i.priority == AppConstants.priorityCritical).length;
                final queuedCount = incidents.where((i) => !i.isSynced).length;
                final syncedCount = incidents.where((i) => i.isSynced).length;

                return Column(
                  children: [
                    // Tactical KPI Summary Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          _buildKpiCard('Total', '${incidents.length}', Colors.blueGrey),
                          const SizedBox(width: 6),
                          _buildKpiCard('Critical', '$criticalCount', Colors.redAccent),
                          const SizedBox(width: 6),
                          _buildKpiCard('Queued', '$queuedCount', Colors.orange),
                          const SizedBox(width: 6),
                          _buildKpiCard('Synced', '$syncedCount', Colors.teal),
                        ],
                      ),
                    ),
                    Expanded(
                      child: incidents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No incidents recorded yet.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tap + or SOS to report an emergency.',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              itemCount: incidents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, index) {
                                final item = incidents[index];
                                final dateStr = DateFormat('MMM d, HH:mm').format(item.createdAt);

                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: _getPriorityColor(item.priority).withValues(alpha: 0.2),
                                      child: Icon(
                                        _getCategoryIcon(item.category),
                                        color: _getPriorityColor(item.priority),
                                      ),
                                    ),
                                    title: Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (item.description != null && item.description!.isNotEmpty)
                                          Text(
                                            item.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '[${item.category}] • ${item.status.toUpperCase()} • $dateStr',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item.isSynced ? Icons.cloud_done : Icons.cloud_upload_outlined,
                                          color: item.isSynced ? Colors.teal : Colors.orange,
                                          size: 22,
                                        ),
                                        Text(
                                          item.isSynced ? 'Synced' : 'Queued',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: item.isSynced ? Colors.teal : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading incidents: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_rounded),
          label: 'Incidents',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_rounded),
          label: 'Field Map',
        ),
      ],
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
        );
      },
      icon: const Icon(Icons.add_alert_rounded),
      label: const Text('New Incident'),
    );
  }
}
