import 'package:aetherride_mobile/core/theme/app_theme.dart';
import 'package:aetherride_mobile/domain/community/labeled_via.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/plan_waypoint_stack.dart';
import 'package:aetherride_mobile/presentation/map/map_pin_image.dart';
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
  late TextEditingController start;
  late TextEditingController end;
  late FocusNode startFocus;
  late FocusNode endFocus;

  setUp(() {
    start = TextEditingController(text: 'Start');
    end = TextEditingController(text: 'Ziel');
    startFocus = FocusNode();
    endFocus = FocusNode();
  });

  tearDown(() {
    start.dispose();
    end.dispose();
    startFocus.dispose();
    endFocus.dispose();
  });

  testWidgets('pins outside the pack use sage fill', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlanWaypointStack(
          startController: start,
          endController: end,
          startFocus: startFocus,
          endFocus: endFocus,
          vias: const [
            LabeledVia(lat: 49.0, lng: 8.0, label: 'Via'),
          ],
          hasStart: true,
          hasEnd: true,
          startOutside: true,
          endOutside: true,
          viaOutside: const [true],
          onMyLocation: () {},
          onSwap: () {},
          onAddVia: () {},
          onCloseLoop: () {},
          onViaReorder: (_, __) {},
          onViaRemove: (_) {},
          onStartChanged: (_) {},
          onEndChanged: (_) {},
          onStartSubmitted: () {},
          onEndSubmitted: () {},
          onViaChanged: (_, __) {},
          onViaSubmitted: (_, __) {},
        ),
      ),
    );
    final badges = tester.widgetList<MapPinBadge>(find.byType(MapPinBadge));
    expect(badges, hasLength(3));
    expect(badges.every((b) => b.fill == AppColors.sage), isTrue);
  });

  testWidgets('pins inside the pack keep default fill', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PlanWaypointStack(
          startController: start,
          endController: end,
          startFocus: startFocus,
          endFocus: endFocus,
          vias: const [
            LabeledVia(lat: 49.0, lng: 8.4, label: 'Via'),
          ],
          hasStart: true,
          hasEnd: true,
          onMyLocation: () {},
          onSwap: () {},
          onAddVia: () {},
          onCloseLoop: () {},
          onViaReorder: (_, __) {},
          onViaRemove: (_) {},
          onStartChanged: (_) {},
          onEndChanged: (_) {},
          onStartSubmitted: () {},
          onEndSubmitted: () {},
          onViaChanged: (_, __) {},
          onViaSubmitted: (_, __) {},
        ),
      ),
    );
    final badges = tester.widgetList<MapPinBadge>(find.byType(MapPinBadge));
    expect(badges, hasLength(3));
    expect(badges.every((b) => b.fill == null), isTrue);
  });
}
