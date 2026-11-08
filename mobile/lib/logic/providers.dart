import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../core/api_client.dart';
import '../data/local/database.dart';
import 'sync/sync_service.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

final targetMapLocationProvider = StateProvider<LatLng?>((ref) => null);
final userLocationProvider = StateProvider<LatLng?>((ref) => null);
final incidentSearchQueryProvider = StateProvider<String>((ref) => '');
final incidentCategoryFilterProvider = StateProvider<String>((ref) => 'All');
final incidentSyncFilterProvider = StateProvider<String>((ref) => 'All');

final filteredIncidentsProvider = Provider<List<LocalIncident>>((ref) {
  final incidents = ref.watch(incidentsStreamProvider).value ?? [];
  final query = ref.watch(incidentSearchQueryProvider).toLowerCase().trim();
  final category = ref.watch(incidentCategoryFilterProvider);
  final syncFilter = ref.watch(incidentSyncFilterProvider);

  return incidents.where((item) {
    if (category != 'All' && item.category != category) return false;
    if (syncFilter == 'Queued' && item.isSynced) return false;
    if (syncFilter == 'Synced' && !item.isSynced) return false;
    if (query.isNotEmpty) {
      final titleMatches = item.title.toLowerCase().contains(query);
      final descMatches = item.description?.toLowerCase().contains(query) ?? false;
      final catMatches = item.category.toLowerCase().contains(query);
      if (!titleMatches && !descMatches && !catMatches) return false;
    }
    return true;
  }).toList();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  final conn = ref.watch(connectivityProvider);
  final service = SyncService(database: db, apiClient: api, connectivity: conn);
  ref.onDispose(() => service.dispose());
  return service;
});

final incidentsStreamProvider = StreamProvider<List<LocalIncident>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllIncidents();
});

final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final conn = ref.watch(connectivityProvider);
  return conn.onConnectivityChanged;
});
