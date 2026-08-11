import 'package:aetherride_mobile/data/routing/discover_card_hero.dart';
import 'package:aetherride_mobile/data/routing/naehe_seeds.dart';
import 'package:aetherride_mobile/domain/bike.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RN premium seeds resolve curated photo heroes (not gray)', () {
    expect(
      hasCuratedDiscoverHero('seed-dach-60-rn-1-heidelberg-neckarwiese'),
      isTrue,
    );
    expect(
      hasCuratedDiscoverHero('seed-dach-60-rn-2-mannheim-schloss-waldpark'),
      isTrue,
    );
    expect(
      hasCuratedDiscoverHero('seed-dach-60-rn-3-heidelberg-boxberg-gaisberg'),
      isTrue,
    );
    for (final id in const [
      'seed-dach-60-rn-1-heidelberg-neckarwiese',
      'seed-dach-60-rn-2-mannheim-schloss-waldpark',
      'seed-dach-60-rn-3-heidelberg-boxberg-gaisberg',
    ]) {
      final url = resolveDiscoverCardHeroUrl(
        id: id,
        lat: 49.4,
        lng: 8.7,
      );
      expect(url, startsWith('https://'));
      expect(url.contains('upload.wikimedia.org'), isTrue);
    }
  });

  test('thumbnail_url wins over curated map', () {
    final url = resolveDiscoverCardHeroUrl(
      id: 'seed-dach-60-rn-1-heidelberg-neckarwiese',
      lat: 49.4,
      lng: 8.7,
      thumbnailUrl: 'https://example.com/hero.jpg',
    );
    expect(url, 'https://example.com/hero.jpg');
  });

  test('unknown seed falls back to place static map', () {
    final url = resolveDiscoverCardHeroUrl(
      id: 'seed-unknown-xyz',
      lat: 49.294,
      lng: 8.698,
    );
    expect(url, contains('maps.wikimedia.org'));
    expect(url, contains('49.294'));
    expect(url, contains('8.698'));
  });

  test('ebike seed categories include E-MTB (Wiesloch filter)', () {
    final route = NaeheSeedRoute.fromPremiumBikeKnowledge({
      'id': 'seed-dach-60-rn-1-heidelberg-neckarwiese',
      'title': 'HD',
      'sport': 'ebike',
      'duration_min': 60,
      'distance_km': 16,
      'loop': true,
      'start_area': {'lat': 49.409, 'lng': 8.694},
    });
    expect(route.categories, contains(BikeCategory.emtb));
    expect(route.categories, contains(BikeCategory.etrekking));
  });

  test('envelope parse reads thumbnail_url without requiring seed edits', () {
    final bundle = NaeheSeedsBundle.parse('''
{
  "label_without_location": "test",
  "label_with_location": "test",
  "default_center": {"lat": 52.52, "lng": 13.4},
  "seeds": [{
    "id": "seed-thumb-demo",
    "title": "Thumb",
    "type": "route",
    "is_loop": true,
    "duration_min": 55,
    "distance_km": 12,
    "ascent_m": 40,
    "effort_label": "Leicht",
    "sport_tags": ["city"],
    "center": {"lat": 52.5, "lng": 13.4},
    "thumbnail_url": "https://cdn.example/t.jpg"
  }]
}
''');
    expect(bundle.byId('seed-thumb-demo')!.thumbnailUrl,
        'https://cdn.example/t.jpg');
  });
}
