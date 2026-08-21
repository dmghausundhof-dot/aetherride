import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/compatibility/engine.dart';
import 'package:aetherride_mobile/domain/compatibility/rules.dart';
import 'package:aetherride_mobile/domain/component.dart';
import 'package:aetherride_mobile/domain/post_ride/analyze.dart';
import 'package:aetherride_mobile/domain/ride.dart';

void main() {
  test('compat equals freehub microspline', () {
    final comps = [
      BikeComponent(
        id: '1',
        bikeId: 'b',
        slot: ComponentSlot.cassette,
        attributes: const {'freehub_standard': 'microspline'},
      ),
      BikeComponent(
        id: '2',
        bikeId: 'b',
        slot: ComponentSlot.rearHub,
        attributes: const {
          'freehub_standard': 'microspline',
          'rear_spacing': '148x12',
          'rotor_mount': '6bolt',
        },
      ),
    ];
    final r = evaluateRule(
      comps,
      compatibilityRules.firstWhere((x) => x.code == 'RL-DRV-011'),
    );
    expect(r?.verdict, CompatVerdict.compatible);
  });

  test('compat insufficient without attrs', () {
    final comps = [
      const BikeComponent(
        id: '1',
        bikeId: 'b',
        slot: ComponentSlot.cassette,
      ),
      const BikeComponent(
        id: '2',
        bikeId: 'b',
        slot: ComponentSlot.rearHub,
      ),
    ];
    final r = evaluateRule(
      comps,
      compatibilityRules.firstWhere((x) => x.code == 'RL-DRV-011'),
    );
    expect(r?.verdict, CompatVerdict.insufficientData);
  });

  test('checkCandidateOnBike replaces slot', () {
    final installed = [
      BikeComponent(
        id: '1',
        bikeId: 'b',
        slot: ComponentSlot.cassette,
        attributes: const {'freehub_standard': 'hg'},
      ),
      BikeComponent(
        id: '2',
        bikeId: 'b',
        slot: ComponentSlot.rearHub,
        attributes: const {
          'freehub_standard': 'microspline',
          'rear_spacing': '148x12',
          'rotor_mount': '6bolt',
        },
      ),
    ];
    final candidate = BikeComponent(
      id: 'c',
      bikeId: 'b',
      slot: ComponentSlot.cassette,
      catalogModelId: 'cat-1',
      attributes: const {'freehub_standard': 'microspline'},
    );
    final results = checkCandidateOnBike(installed, candidate);
    final drv = results.where((r) => r.ruleCode == 'RL-DRV-011');
    expect(drv, isNotEmpty);
    expect(drv.first.verdict, CompatVerdict.compatible);
  });

  test('compat placeholder attrs are insufficient, not a silent fit', () {
    final comps = [
      BikeComponent(
        id: '1',
        bikeId: 'b',
        slot: ComponentSlot.cassette,
        attributes: const {
          'freehub_standard': 'microspline',
          '_compat_placeholder': true,
        },
      ),
      BikeComponent(
        id: '2',
        bikeId: 'b',
        slot: ComponentSlot.rearHub,
        attributes: const {
          'freehub_standard': 'microspline',
          'rear_spacing': '148x12',
          'rotor_mount': '6bolt',
        },
      ),
    ];
    final r = evaluateRule(
      comps,
      compatibilityRules.firstWhere((x) => x.code == 'RL-DRV-011'),
    );
    expect(r?.verdict, CompatVerdict.insufficientData);
  });

  test('post-ride suggests slower rebound on harsh feedback', () {
    final ride = RideRecord(
      id: 'r1',
      bikeId: 'b',
      startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      endedAt: DateTime.now(),
      distanceKm: 18,
      movingTimeSec: 3600,
      elevationM: 600,
      summary: const {'peakG': 3.2, 'avgFlow': 60, 'gForceRms': 1.3},
    );
    final analysis = analyzePostRide(
      ride: ride,
      feedback: const RideFeedback(
        overallFeel: 3,
        frontFeel: 'too_firm',
        smallBump: 'harsh',
      ),
    );
    expect(analysis.setupSuggestion, isNotNull);
    expect(analysis.setupSuggestion!.suggestedDelta, -2);
    expect(analysis.observations, isNotEmpty);
  });
}
