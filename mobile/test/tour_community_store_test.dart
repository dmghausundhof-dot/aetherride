import 'dart:io';

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
            'tags': ['nass', 'top', 'unknown'],
            'pin_lat': 49.41,
            'pin_lng': 8.67,
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
    expect(parsed.reviews.first.tags, ['nass', 'top']);
    expect(parsed.reviews.first.pinLat, 49.41);
    expect(parsed.reviews.first.pinLng, 8.67);
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

  test('parseCloudPayload skips reviews without a real 1–5 rating', () {
    final parsed = TourCommunityStore.parseCloudPayload(
      {
        'reviews': [
          {'id': 'ok', 'rating': 5, 'body': 'Top', 'author_label': 'A'},
          {'id': 'no-rating', 'body': 'ohne Sterne'},
          {'id': 'bad', 'rating': 9, 'body': 'fake'},
        ],
        'photos': <Object>[],
      },
      't1',
    );
    expect(parsed.reviews, hasLength(1));
    expect(parsed.reviews.single.rating, 5);
  });

  test('TourCommunityCounts never invents an average', () {
    final empty = TourCommunityCounts.fromPayload({
      'reviews': <Object>[],
      'photos': <Object>[],
      'stub': false,
    });
    expect(empty.hasCommunity, isFalse);
    expect(empty.averageRating, isNull);
    expect(TourCommunityCounts.emptyCopy, contains('Stimmen'));

    final live = TourCommunityCounts.fromPayload({
      'reviewCount': 2,
      'photoCount': 3,
      'reviews': [
        {'rating': 5},
        {'rating': 3},
      ],
    });
    expect(live.reviewCount, 2);
    expect(live.photoCount, 3);
    expect(live.averageRating, 4);
    expect(live.hasCommunity, isTrue);
  });

  test('addReview publishes counts and bumps revision', () async {
    final dir = await Directory.systemTemp.createTemp('tour_community_');
    addTearDown(() => dir.delete(recursive: true));
    final before = TourCommunityStore.revision.value;
    final store = TourCommunityStore(dirProvider: () async => dir);
    await store.addReview(
      tourId: 'seed-loop-x',
      rating: 4,
      body: 'flowig',
      authorLabel: 'Du',
    );
    expect(TourCommunityStore.revision.value, greaterThan(before));
    final counts = TourCommunityStore.countsCache['seed-loop-x'];
    expect(counts?.reviewCount, 1);
    expect(counts?.averageRating, 4);
  });

  test('addReview keeps allowlisted tags', () async {
    final dir = await Directory.systemTemp.createTemp('tour_community_tags_');
    addTearDown(() => dir.delete(recursive: true));
    final store = TourCommunityStore(dirProvider: () async => dir);
    final review = await store.addReview(
      tourId: 'seed-loop-x',
      rating: 5,
      body: 'nass oben',
      authorLabel: 'Du',
      tags: const ['nass', 'unknown', 'top', 'zu', 'baustelle'],
    );
    expect(review.tags, ['nass', 'top', 'zu']);
    final loaded = await store.reviewsForTour('seed-loop-x');
    expect(loaded.single.tags, ['nass', 'top', 'zu']);
  });
}
