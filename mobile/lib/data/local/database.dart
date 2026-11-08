import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class LocalIncidents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text().unique()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get description => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('reported'))();
  TextColumn get priority => text().withDefault(const Constant('medium'))();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get assignedToId => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

class CachedLocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get batteryLevel => real().nullable()();
  RealColumn get heading => real().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [LocalIncidents, SyncQueue, CachedLocations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'pulsesync_db');
  }

  // --- DAO Methods for Incidents ---

  Stream<List<LocalIncident>> watchAllIncidents() {
    return (select(localIncidents)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<List<LocalIncident>> getAllIncidents() {
    return (select(localIncidents)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<List<LocalIncident>> getUnsyncedIncidents() {
    return (select(localIncidents)..where((t) => t.isSynced.equals(false))).get();
  }

  Future<int> insertIncident(LocalIncidentsCompanion incident) {
    return into(localIncidents).insert(incident, mode: InsertMode.insertOrReplace);
  }

  Future<bool> markIncidentSynced(String clientId, int serverVersion) {
    return (update(localIncidents)..where((t) => t.clientId.equals(clientId))).write(
      LocalIncidentsCompanion(
        isSynced: const Value(true),
        version: Value(serverVersion),
      ),
    ).then((count) => count > 0);
  }

  Future<bool> updateIncidentStatus(String clientId, String newStatus) {
    return (update(localIncidents)..where((t) => t.clientId.equals(clientId))).write(
      LocalIncidentsCompanion(
        status: Value(newStatus),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  // --- DAO Methods for Sync Queue ---

  Future<int> enqueueSync({
    required String entityType,
    required String entityId,
    required String operation,
    required String payload,
  }) {
    return into(syncQueue).insert(
      SyncQueueCompanion(
        entityType: Value(entityType),
        entityId: Value(entityId),
        operation: Value(operation),
        payload: Value(payload),
        createdAt: Value(DateTime.now()),
        retryCount: const Value(0),
      ),
    );
  }

  Future<List<SyncQueueData>> getPendingQueue() {
    return (select(syncQueue)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  Future<int> removeQueueItem(int id) {
    return (delete(syncQueue)..where((t) => t.id.equals(id))).go();
  }
}
