import 'package:aetherride_mobile/domain/routing/street_from_instruction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractStreetNameFromInstruction', () {
    test('DE auf', () {
      expect(
        extractStreetNameFromInstruction('Rechts abbiegen auf Hauptstraße'),
        'Hauptstraße',
      );
    });

    test('DE nach', () {
      expect(
        extractStreetNameFromInstruction('Weiter nach Neckarstaden'),
        'Neckarstaden',
      );
    });

    test('EN onto', () {
      expect(
        extractStreetNameFromInstruction('Turn left onto Main Street'),
        'Main Street',
      );
    });

    test('no street returns null', () {
      expect(extractStreetNameFromInstruction('Links abbiegen'), isNull);
      expect(extractStreetNameFromInstruction('Ziel erreicht'), isNull);
    });
  });

  group('maneuverLabelFromInstruction', () {
    test('strips street suffix', () {
      expect(
        maneuverLabelFromInstruction('Rechts abbiegen auf Hauptstraße'),
        'Rechts abbiegen',
      );
    });
  });
}
