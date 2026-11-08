import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import '../../core/api_client.dart';
import '../../data/local/database.dart';

class SyncService {
  final AppDatabase database;
  final ApiClient apiClient;
  final Connectivity connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  DateTime? _lastSyncTimestamp;

  SyncService({
    required this.database,
    required this.apiClient,
    required this.connectivity,
  }) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (isConnected) {
        triggerSync();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<bool> triggerSync() async {
    if (_isSyncing) return false;
    _isSyncing = true;

    try {
      // 1. Gather unsynced incidents
      final unsynced = await database.getUnsyncedIncidents();
      final queueItems = await database.getPendingQueue();

      final incidentsToPush = unsynced.map((inc) {
        return {
          'client_id': inc.clientId,
          'title': inc.title,
          'description': inc.description,
          'status': inc.status,
          'priority': inc.priority,
          'latitude': inc.latitude,
          'longitude': inc.longitude,
          'assigned_to_id': inc.assignedToId,
          'version': inc.version,
          'client_created_at': inc.createdAt.toUtc().toIso8601String(),
        };
      }).toList();

      final pushPayload = {
        'client_timestamp': DateTime.now().toUtc().toIso8601String(),
        'incidents': incidentsToPush,
        'locations': <Map<String, dynamic>>[],
      };

      // 2. Push to server
      if (incidentsToPush.isNotEmpty) {
        final pushResult = await apiClient.pushSync(pushPayload);
        final syncedIncidents = pushResult['synced_incidents'] as List<dynamic>? ?? [];

        for (final item in syncedIncidents) {
          final clientId = item['client_id'] as String;
          final serverVersion = item['version'] as int;
          await database.markIncidentSynced(clientId, serverVersion);
        }

        // Clean up queue
        for (final q in queueItems) {
          await database.removeQueueItem(q.id);
        }
      }

      // 3. Pull incremental updates from server
      final pullResult = await apiClient.pullSync(_lastSyncTimestamp);
      final serverTimestampStr = pullResult['server_timestamp'] as String;
      _lastSyncTimestamp = DateTime.parse(serverTimestampStr);

      final incomingIncidents = pullResult['incidents'] as List<dynamic>? ?? [];
      for (final raw in incomingIncidents) {
        final clientId = raw['client_id'] as String;
        final title = raw['title'] as String;
        final desc = raw['description'] as String?;
        final status = raw['status'] as String;
        final priority = raw['priority'] as String;
        final lat = (raw['latitude'] as num).toDouble();
        final lon = (raw['longitude'] as num).toDouble();
        final version = raw['version'] as int;
        final createdAt = DateTime.parse(raw['created_at'] as String);
        final updatedAt = DateTime.parse(raw['updated_at'] as String);

        await database.insertIncident(
          LocalIncidentsCompanion(
            clientId: Value(clientId),
            title: Value(title),
            description: Value(desc),
            status: Value(status),
            priority: Value(priority),
            latitude: Value(lat),
            longitude: Value(lon),
            version: Value(version),
            isSynced: const Value(true),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
          ),
        );
      }

      return true;
    } catch (e) {
      // Sync failed (offline or server error) - keep local changes queued
      return false;
    } finally {
      _isSyncing = false;
    }
  }
}
