import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/bike.dart';
import 'package:aetherride_mobile/domain/setup/bracketing.dart';
import 'package:aetherride_mobile/domain/setup/templates.dart';

void main() {
  test('fox OEM template resolves rebound and pressure', () {
    final tpl = setupTemplates.firstWhere((t) => t.id == 'tpl-fox-oem-base');
    final values = tpl.toValues(75, BikeCategory.mtbAm);
    expect(values.any((v) => v.adjusterKey == 'fork.rebound'), isTrue);
    expect(values.any((v) => v.adjusterKey == 'fork.air_pressure_psi'), isTrue);
  });

  test('bracketing evaluates missing runs', () {
    final series = createBlindPair(
      adjusterKey: 'fork.rebound',
      currentValue: 8,
    );
    final eval = evaluateBracketingSeries(series);
    expect(eval.ready, isFalse);
    expect(eval.missingRuns, isNotEmpty);
  });

  test('bracketing no proven difference with similar runs', () {
    final eval = evaluateBracketingSeries(
      const BracketingSeries(
        adjusterKey: 'fork.rebound',
        rangeFrom: 6,
        rangeTo: 10,
        step: 4,
        runs: [
          BracketingRun(
            configValue: 6,
            segmentTimeSec: 120,
            flowScore: 70,
            impactHardness: 4,
            subjectiveRating: 3,
          ),
          BracketingRun(
            configValue: 6,
            segmentTimeSec: 118,
            flowScore: 71,
            impactHardness: 4,
            subjectiveRating: 3,
          ),
          BracketingRun(
            configValue: 10,
            segmentTimeSec: 121,
            flowScore: 70.5,
            impactHardness: 4.1,
            subjectiveRating: 3,
          ),
          BracketingRun(
            configValue: 10,
            segmentTimeSec: 119,
            flowScore: 70.2,
            impactHardness: 4,
            subjectiveRating: 3,
          ),
        ],
      ),
    );
    expect(eval.ready, isTrue);
    expect(eval.noProvenDifference, isTrue);
  });
}
