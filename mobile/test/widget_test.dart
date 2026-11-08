import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsesync/data/local/database.dart';
import 'package:pulsesync/logic/providers.dart';
import 'package:pulsesync/main.dart';

void main() {
  testWidgets('PulseSyncApp renders incident list and navigation items', (WidgetTester tester) async {
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
        ],
        child: const PulseSyncApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify app bar title
    expect(find.text('PulseSync Dispatch'), findsOneWidget);

    // Verify navigation tabs
    expect(find.text('Incidents'), findsOneWidget);
    expect(find.text('Field Map'), findsOneWidget);

    // Verify FAB
    expect(find.text('New Incident'), findsOneWidget);

    await testDb.close();
  });
}
