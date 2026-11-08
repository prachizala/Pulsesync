import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../data/local/database.dart';
import 'sync/sync_service.dart';

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
