import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/garage/die_box.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Die Box primary is never Zum Setup', () {
    final plan = planDieBox(
      bike: const Bike(
        id: 'b1',
        name: 'Trail Buddy',
        category: BikeCategory.mtbTrail,
        isActive: true,
        travelFrontMm: 140,
        travelRearMm: 140,
      ),
    );
    expect(plan.primary?.cta, isNot('Zum Setup'));
    expect(plan.sentence.toLowerCase(), isNot(contains('teile')));
  });
}
