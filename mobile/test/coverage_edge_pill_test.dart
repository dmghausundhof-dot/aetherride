import 'package:aetherride_mobile/presentation/discover/offline_coverage_sketch.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/coverage_edge_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edge pill shows pack name and outside state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverageEdgePill(label: 'Rhein-Neckar · Routing'),
        ),
      ),
    );
    expect(
        find.byKey(const Key('discover-coverage-edge-pill')), findsOneWidget);
    expect(find.text('Rhein-Neckar · Routing'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverageEdgePill(
            label: 'Außerhalb Rhein-Neckar',
            outside: true,
          ),
        ),
      ),
    );
    expect(find.text('Außerhalb Rhein-Neckar'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverageEdgePill(
            label: 'Rhein-Neckar · Übersicht',
            overview: true,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoverageEdgePill(
            label: 'Rhein-Neckar · Karte: Netz',
            needsNet: true,
          ),
        ),
      ),
    );
    expect(find.text('Rhein-Neckar · Karte: Netz'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('coverage sketch tap reports the pack box', (tester) async {
    List<double>? shown;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineCoverageSketch(
            bbox: const [8.2, 48.9, 8.6, 49.2],
            progress: 0.4,
            semanticLabel: 'Region auf der Karte zeigen',
            onTap: () => shown = const [8.2, 48.9, 8.6, 49.2],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('offline-coverage-sketch')));
    expect(shown, [8.2, 48.9, 8.6, 49.2]);
  });
}
