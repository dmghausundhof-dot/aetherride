import 'package:aetherride_mobile/data/weather/weather_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeatherSnapshot parses without 72h fields', () {
    final w = WeatherSnapshot.fromJson({
      'current': {'temperature_2m': 11, 'precipitation': 0},
      'trailHint': 'dry_likely',
    });
    expect(w.trailHint, 'dry_likely');
    expect(w.tempC, 11);
    expect(w.precip72hMm, isNull);
    expect(w.trailHintSource, isNull);
    expect(w.rideWindowLabel, isNull);
    expect(w.trailLabel, 'eher trocken');
  });

  test('WeatherSnapshot keeps trailHint enum with soil source', () {
    final w = WeatherSnapshot.fromJson({
      'current': {'temperature_2m': 8, 'precipitation': 0},
      'trailHint': 'wet_likely',
      'trailHintSource': 'soil_72h',
      'precip72hMm': 14.7,
    });
    expect(w.trailHint, 'wet_likely');
    expect(w.trailHintSource, 'soil_72h');
    expect(w.precip72hMm, 14.7);
    expect(w.trailLabel, 'eher nass');
  });

  test('WeatherSnapshot reads optional rideWindow without Hof sky fields', () {
    final w = WeatherSnapshot.fromJson({
      'current': {'temperature_2m': 14, 'precipitation': 0},
      'trailHint': 'damp_possible',
      'rideWindow': {'label': 'heute 16–18 Uhr trockener', 'kind': 'drier'},
    });
    expect(w.trailHint, 'damp_possible');
    expect(w.rideWindowLabel, 'heute 16–18 Uhr trockener');
    expect(w.precip72hMm, isNull);
  });
}
