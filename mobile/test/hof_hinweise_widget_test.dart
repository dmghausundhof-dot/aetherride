import 'package:aetherride_mobile/domain/ai/coach_inbox.dart';
import 'package:aetherride_mobile/domain/ai/coach_watch.dart';
import 'package:aetherride_mobile/l10n/app_localizations.dart';
import 'package:aetherride_mobile/presentation/home/hof_coach_banner.dart';
import 'package:aetherride_mobile/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _notice = CoachNotice(
  id: 'n1',
  kind: CoachKind.maintenance,
  severity: CoachSeverity.info,
  title: 'Kette prüfen',
  detail: 'Bald fällig',
  reasoning: 'km',
  href: '/garage',
  tool: 'watch',
  query: 'was steht an',
  fingerprint: 'fp1',
);

Widget _app({required List<CoachInboxItem> inbox}) {
  return ProviderScope(
    overrides: [
      coachWatchProvider.overrideWith((ref) async => inbox),
    ],
    child: const MaterialApp(
      locale: Locale('de', 'DE'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Row(
          children: [
            HofCoachBellButton(),
            HofChatButton(),
          ],
        ),
      ),
    ),
  );
}

void main() {
  Badge _bellBadge(WidgetTester tester) {
    return tester.widget<Badge>(
      find.descendant(
        of: find.byKey(const Key('coach-bell')),
        matching: find.byType(Badge),
      ),
    );
  }

  testWidgets('Glocke ist immer da, ohne Badge wenn nichts ungelesen',
      (tester) async {
    await tester.pumpWidget(_app(inbox: const []));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('coach-bell')), findsOneWidget);
    expect(find.byKey(const Key('coach-chat')), findsOneWidget);
    expect(_bellBadge(tester).isLabelVisible, isFalse);
  });

  testWidgets('Badge nur auf der Glocke bei Ungelesenem', (tester) async {
    await tester.pumpWidget(
      _app(
        inbox: const [CoachInboxItem(notice: _notice, unread: true)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('coach-bell')), findsOneWidget);
    expect(_bellBadge(tester).isLabelVisible, isTrue);
  });

  testWidgets('Glocke öffnet Hinweise, nicht den Chat', (tester) async {
    await tester.pumpWidget(
      _app(
        inbox: const [CoachInboxItem(notice: _notice, unread: true)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('coach-bell')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hof-hinweise-title')), findsOneWidget);
    expect(find.text('Hinweise'), findsOneWidget);
    expect(find.text('Kette prüfen'), findsOneWidget);
    expect(find.text('Frag mich'), findsNothing);
    expect(find.text('Assistent'), findsNothing);
  });
}
