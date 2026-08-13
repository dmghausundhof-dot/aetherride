import 'package:aetherride_mobile/presentation/discover/tour_sheet_pin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Auswahl bleibt Index 0, Rest unveränderte Rangfolge', () {
    final ranked = ['nah', 'mittel', 'weit', 'füller'];
    expect(
      pinSelectedFirst(ranked, (id) => id == 'weit'),
      ['weit', 'nah', 'mittel', 'füller'],
    );
  });

  test('ohne Auswahl bleibt die Rangfolge', () {
    final ranked = ['nah', 'mittel', 'weit'];
    expect(pinSelectedFirst(ranked, (_) => false), ranked);
  });

  test('schon oben bleibt oben', () {
    final ranked = ['gewählt', 'nah', 'weit'];
    expect(
      pinSelectedFirst(ranked, (id) => id == 'gewählt'),
      ranked,
    );
  });
}
