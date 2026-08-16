import 'package:aetherride_mobile/domain/routing/bike_overlay_class.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/bike_overlay_legend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('City-Legende ist kompakt und ohne S0–S3+', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BikeOverlayLegend(
          family: BikeOverlayFamily.urban,
          visible: true,
          extraOn: overlayDefaultExtraOn(BikeOverlayFamily.urban),
          onToggleVisible: () {},
          onToggleClass: (_) {},
        ),
      ),
    );
    expect(find.textContaining('S0'), findsNothing);
    expect(find.textContaining('S3+'), findsNothing);
    expect(find.byKey(const Key('bike-overlay-legend-title')), findsOneWidget);
    await tester.tap(find.byKey(const Key('bike-overlay-legend-title')));
    await tester.pumpAndSettle();
    expect(find.text('S0'), findsNothing);
    expect(find.text('City'), findsWidgets);
  });

  testWidgets('MTB-Legende zeigt S-Skala erst nach Aufklappen', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BikeOverlayLegend(
          family: BikeOverlayFamily.mtb,
          visible: true,
          extraOn: overlayDefaultExtraOn(BikeOverlayFamily.mtb),
          onToggleVisible: () {},
          onToggleClass: (_) {},
        ),
      ),
    );
    expect(find.text('S0'), findsNothing);
    await tester.tap(find.byKey(const Key('bike-overlay-legend-title')));
    await tester.pumpAndSettle();
    expect(find.text('S0'), findsOneWidget);
    expect(find.text('S3+'), findsOneWidget);
  });
}
