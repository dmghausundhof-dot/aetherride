import 'package:aetherride_mobile/data/community/tour_community_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseCloudPayload merges signed photo URLs for the carousel', () {
    final parsed = TourCommunityStore.parseCloudPayload(
      {
        'tourId': 'seed-loop-tempelhofer-60',
        'reviews': [
          {
            'id': 'r1',
            'tour_id': 'seed-loop-tempelhofer-60',
            'rating': 5,
            'body': 'Top',
            'author_label': 'Mira',
            'created_at': '2026-08-12T10:00:00Z',
          },
        ],
        'photos': [
          {
            'id': 'p1',
            'storage_path': 'user/a.jpg',
            'url': 'https://cdn.example/tour.jpg',
          },
        ],
        'stub': false,
      },
      'seed-loop-tempelhofer-60',
    );
    expect(parsed.reviews, hasLength(1));
    expect(parsed.reviews.first.authorLabel, 'Mira');
    expect(parsed.photoUrls, ['https://cdn.example/tour.jpg']);
  });

  test('parseCloudPayload ignores stub / missing tables', () {
    final parsed = TourCommunityStore.parseCloudPayload(
      {
        'tourId': 'x',
        'reviews': <Object>[],
        'photos': <Object>[],
        'stub': true,
      },
      'x',
    );
    expect(parsed.reviews, isEmpty);
    expect(parsed.photoUrls, isEmpty);
  });
}
