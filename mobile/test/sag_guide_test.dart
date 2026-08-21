import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/setup/sag_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('target sag mm from travel and percent', () {
    expect(targetSagMm(150, 22), 33);
    expect(targetSagMm(160, 30), 48);
  });

  test('e-MTB extra mass loads the shock more than the fork', () {
    final shock = equivalentRiderKg(
      riderWeightKg: 78,
      gearWeightKg: 5,
      bikeWeightKg: 24,
      end: 'shock',
    );
    final fork = equivalentRiderKg(
      riderWeightKg: 78,
      gearWeightKg: 5,
      bikeWeightKg: 24,
      end: 'fork',
    );
    expect(shock, 89);
    expect(fork, 87);
  });

  test('heavier bike raises shock start psi in the same category', () {
    final light = estimateAirPsi(
      riderWeightKg: 78,
      gearWeightKg: 5,
      bikeWeightKg: 15,
      category: BikeCategory.emtb,
      end: 'shock',
      travelMm: 150,
    );
    final heavy = estimateAirPsi(
      riderWeightKg: 78,
      gearWeightKg: 5,
      bikeWeightKg: 24,
      category: BikeCategory.emtb,
      end: 'shock',
      travelMm: 150,
    );
    expect(heavy.psiTarget, greaterThan(light.psiTarget));
  });

  test('peak g maps to travel usage after sag is known', () {
    expect(remainingTravelExcessG(25), 3);
    final rest = estimateTravelUsage(
      gForcePeak: 1,
      sagPct: 25,
      travelMm: 150,
    )!;
    expect(rest.usagePct, 25);
    final full = estimateTravelUsage(
      gForcePeak: 4,
      sagPct: 25,
      travelMm: 150,
    )!;
    expect(full.usagePct, 100);
  });
}
