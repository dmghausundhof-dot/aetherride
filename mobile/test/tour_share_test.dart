import 'package:aetherride_mobile/data/community/tour_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seeds share Discover loop URLs, not /tours/', () {
    const id = 'seed-dach-60-winterthur-eschenberg-trail';
    expect(TourShare.usesDiscoverLoop(id), isTrue);
    expect(
      TourShare.httpsUrl(id),
      'https://aetherride.vercel.app/discover?loop=$id',
    );
    expect(
      TourShare.appUrl(id),
      'aetherride://discover?loop=$id',
    );
    expect(TourShare.text(id), contains('aetherride://discover?loop='));
  });

  test('catalog tours share /tours/{id}', () {
    const id = 'r-heidelberg-city';
    expect(TourShare.usesDiscoverLoop(id), isFalse);
    expect(
      TourShare.httpsUrl(id),
      'https://aetherride.vercel.app/tours/$id',
    );
    expect(TourShare.appUrl(id), 'aetherride://tours/$id');
  });
}
