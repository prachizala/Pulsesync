import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsesync/data/local/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Drift local DB saves incident offline and updates sync state', () async {
    final now = DateTime.now();
    await db.insertIncident(
      LocalIncidentsCompanion.insert(
        clientId: 'test-uuid-001',
        title: 'Collapsed Tunnel',
        latitude: 37.7749,
        longitude: -122.4194,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final incidents = await db.getAllIncidents();
    expect(incidents.length, 1);
    expect(incidents.first.title, 'Collapsed Tunnel');
    expect(incidents.first.isSynced, false);

    // Mark synced
    await db.markIncidentSynced('test-uuid-001', 2);
    final updated = await db.getAllIncidents();
    expect(updated.first.isSynced, true);
    expect(updated.first.version, 2);
  });

  test('Sync queue enqueues and dequeues operations', () async {
    await db.enqueueSync(
      entityType: 'incident',
      entityId: 'test-uuid-002',
      operation: 'create',
      payload: '{"title": "Wildfire"}',
    );

    final pending = await db.getPendingQueue();
    expect(pending.length, 1);
    expect(pending.first.entityId, 'test-uuid-002');

    await db.removeQueueItem(pending.first.id);
    final after = await db.getPendingQueue();
    expect(after.isEmpty, true);
  });
}
