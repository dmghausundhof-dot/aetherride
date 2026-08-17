import 'package:aetherride_mobile/domain/tours/tour_display_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shortens editorial English titles', () {
    expect(
      tourDisplayName(
        'Heidelberg foothills — Boxberg, Bierhelderhof & Gaisberg gravel',
      ),
      'Boxberg-Gravel',
    );
    expect(
      tourDisplayName('Karlsruhe — Hardtwald MTB-Loop'),
      'Hardtwald-MTB',
    );
    expect(
      tourDisplayName('Wiesloch Feierabend-Runde'),
      'Wiesloch Feierabend',
    );
    expect(tourDisplayName('Neckartal'), 'Neckartal');
  });
}
