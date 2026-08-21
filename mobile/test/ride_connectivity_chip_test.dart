import 'package:aetherride_mobile/domain/routing/connectivity_chip.dart';
import 'package:aetherride_mobile/presentation/ride/widgets/ride_connectivity_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('connectivity chip exposes label and opens on tap',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideConnectivityChip(
            state: ConnectivityChipState.offlineMapOk,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('ride-connectivity-chip')), findsOneWidget);
    expect(
      find.bySemanticsLabel('Offline · Straßenkarte · Reroute: Netz'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('ride-connectivity-chip')));
    expect(taps, 1);
  });

  testWidgets('maps-missing chip is labeled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RideConnectivityChip(
            state: ConnectivityChipState.mapsMissing,
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Karten fehlen'), findsOneWidget);
  });
}
