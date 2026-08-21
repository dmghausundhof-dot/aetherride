import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/tours/tour_functions.dart';
import 'package:aetherride_mobile/presentation/discover/widgets/tour_function_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('reference tour kit shows chips and attached event', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: TourFunctionKit(
                tourId: referenceTourId,
                regionSlug: 'rhein-neckar',
                categories: [
                  BikeCategory.gravel,
                  BikeCategory.road,
                  BikeCategory.etrekking,
                  BikeCategory.urban,
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Funktionen dieser Tour'), findsOneWidget);
    expect(find.byKey(const Key('tour-fn-map')), findsOneWidget);
    expect(find.byKey(const Key('tour-event-ev-neckar-voll')), findsOneWidget);
    expect(find.text('Neckar-Vollrunde Feierabend'), findsOneWidget);
    expect(find.textContaining('Rhein-Neckar Allround'), findsOneWidget);
  });
}
