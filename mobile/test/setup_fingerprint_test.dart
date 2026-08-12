import 'package:aetherride_mobile/domain/setup.dart';
import 'package:aetherride_mobile/domain/setup/fingerprint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Reifendruck wird von psi nach bar umgerechnet', () {
    final setup = BikeSetup(
      id: 's1',
      bikeId: 'b1',
      label: 'Trail',
      createdAt: DateTime.utc(2026, 1, 1),
      values: const [
        SetupValue(adjusterKey: 'tire_front.pressure_psi', valueNum: 22),
        SetupValue(adjusterKey: 'fork.air_pressure_psi', valueNum: 87),
        SetupValue(adjusterKey: 'fork.sag_pct', valueNum: 23),
      ],
    );
    final fp = SetupFingerprint.fromSetup(setup);
    expect(fp.lines, contains('SAG 23%'));
    expect(fp.lines, contains('Gabel 87 psi'));
    expect(fp.lines, contains('Reifen 1.5 bar'));
    expect(fp.lines.join(), isNot(contains('22.0 bar')));
  });
}
