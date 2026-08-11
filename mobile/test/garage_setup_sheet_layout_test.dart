import 'dart:ffi' show DynamicLibrary;
import 'dart:io';

import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/data/local/app_database.dart';
import 'package:aetherride_mobile/data/local/setup_repository.dart';
import 'package:aetherride_mobile/data/local/user_profile_store.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/presentation/garage/bike_schema.dart';
import 'package:aetherride_mobile/presentation/garage/setup_sheet.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/open.dart';

/// Reproduces the S25 Garage→Setup killer:
/// Theme `minimumSize: Size.fromHeight(48)` (= w=Infinity) inside a [Row].
void main() {
  setUpAll(() {
    if (Platform.isLinux) {
      open.overrideFor(
        OperatingSystem.linux,
        () => DynamicLibrary.open('/usr/lib/x86_64-linux-gnu/libsqlite3.so.0'),
      );
    }
  });

  testWidgets(
    'Theme block-buttons in Row without minSize override hit Infinity width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          home: const Scaffold(
            body: SizedBox(
              width: 390,
              height: 200,
              child: Row(
                children: [
                  FilledButton(
                    onPressed: null,
                    child: Text('Neue Version'),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: null,
                    child: Text('Bracketing'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Layout must throw (same class as Discover Infinity / S25 white crash).
      expect(tester.takeException(), isNotNull);
    },
  );

  testWidgets('SetupSheet action Row stays finite under AppTheme.dark @390',
      (tester) async {
    final db = createMemoryDatabase();
    addTearDown(db.close);
    final setups = SetupRepository(db);
    final store = UserProfileStore();

    const bike = Bike(
      id: 'bike-setup-s25',
      name: 'Bulls Trail',
      category: BikeCategory.mtbAm,
      isActive: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          setupRepositoryProvider.overrideWith((ref) => setups),
          userProfileStoreProvider.overrideWith((ref) => store),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 720,
              child: SetupSheet(bike: bike),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.takeException(), isNull);
    expect(find.text('Neue Version'), findsOneWidget);
    expect(find.text('Bracketing'), findsOneWidget);
    expect(find.textContaining('Setups · Bulls Trail'), findsOneWidget);
  });

  testWidgets('BikeSchema diamond + legend stay bounded (G-SCH)', (tester) async {
    const bike = Bike(
      id: 'bike-schema',
      name: 'Schema Bulls',
      category: BikeCategory.mtbAm,
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 420,
            child: ListView(
              children: const [
                BikeSchema(
                  bike: bike,
                  installedSlots: {},
                  compact: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('gepflegt'), findsOneWidget);
    expect(find.text('Wartung'), findsOneWidget);
    expect(find.text('fehlt'), findsOneWidget);
  });

  testWidgets('detail Setup-tab tonal button pattern stays finite in Row',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 80,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Setup · Sag & km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Setup öffnen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Setup öffnen'), findsOneWidget);
  });
}
