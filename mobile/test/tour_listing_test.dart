import 'package:aetherride_mobile/domain/tours/tour_listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 18, 10);

  test('share starts as candidate, not a map pin', () {
    final shared = beginTourShare(
      const ListingSnapshot(),
      now: t0,
      isCatalog: false,
    );
    expect(shared.visibility, 'shared');
    expect(shared.listing, TourListingState.candidate);
    expect(shared.candidateSince, t0);
    expect(
      listedForPublicExplore(
        visibility: shared.visibility,
        listing: shared.listing,
      ),
      isFalse,
    );
  });

  test('catalog share skips the listing gate', () {
    final shared = beginTourShare(
      const ListingSnapshot(),
      now: t0,
      isCatalog: true,
    );
    expect(shared.visibility, 'shared');
    expect(shared.listing, TourListingState.none);
  });

  test('three foreign stimmen list the tour', () {
    final shared = beginTourShare(
      const ListingSnapshot(),
      now: t0,
      isCatalog: false,
    );
    final reviews = confirmationsFromReviews([
      (
        authorLabel: 'Du',
        authorId: null,
        createdAt: t0,
        status: 'approved',
        editorial: false,
      ),
      (
        authorLabel: 'Ada',
        authorId: null,
        createdAt: t0,
        status: 'approved',
        editorial: false,
      ),
      (
        authorLabel: 'Bo',
        authorId: null,
        createdAt: t0,
        status: 'pending',
        editorial: false,
      ),
      (
        authorLabel: 'Cam',
        authorId: null,
        createdAt: t0,
        status: 'approved',
        editorial: false,
      ),
      (
        authorLabel: 'Dee',
        authorId: null,
        createdAt: t0,
        status: 'approved',
        editorial: false,
      ),
    ], ownerLabel: 'Du');
    expect(reviews, hasLength(3));
    final listed = tickTourListing(
      snap: shared,
      isCatalog: false,
      confirmations: reviews,
      now: t0,
    );
    expect(listed.listing, TourListingState.listed);
    expect(listed.visibility, 'shared');
    expect(listed.notice, ListingNotice.listed);
    expect(
      listedForPublicExplore(
        visibility: listed.visibility,
        listing: listed.listing,
      ),
      isTrue,
    );
  });

  test('window expiry reverts to private and bumps epoch', () {
    final shared = beginTourShare(
      const ListingSnapshot(),
      now: t0,
      isCatalog: false,
    );
    final expired = tickTourListing(
      snap: shared,
      isCatalog: false,
      confirmations: [
        ListingConfirmation(riderId: 'Ada', at: t0),
      ],
      now: t0.add(const Duration(days: 15)),
    );
    expect(expired.visibility, 'private');
    expect(expired.listing, TourListingState.reverted);
    expect(expired.shareEpoch, 1);
    expect(expired.notice, ListingNotice.reverted);
  });

  test('listed tours do not silently expire', () {
    final stay = tickTourListing(
      snap: ListingSnapshot(
        visibility: 'shared',
        listing: TourListingState.listed,
        candidateSince: t0,
        listedAt: t0,
      ),
      isCatalog: false,
      now: t0.add(const Duration(days: 40)),
    );
    expect(stay.listing, TourListingState.listed);
    expect(stay.visibility, 'shared');
  });

  test('old shared without listing becomes candidate', () {
    final migrated = tickTourListing(
      snap: const ListingSnapshot(visibility: 'shared'),
      isCatalog: false,
      now: t0,
    );
    expect(migrated.listing, TourListingState.candidate);
    expect(migrated.candidateSince, t0);
  });

  test('Tafel prefers reverted, then waiting, then nearby', () {
    expect(
      pickListingTafel(
        own: const [
          ListingTafelOwn(
            name: 'Neckar',
            notice: ListingNotice.candidate,
            confirmCount: 1,
          ),
          ListingTafelOwn(
            name: 'Odenwald',
            notice: ListingNotice.reverted,
            confirmCount: 0,
          ),
        ],
        nearbyWaiting: 4,
      ),
      'Odenwald wieder privat — zu wenig Stimmen.',
    );
    expect(
      pickListingTafel(
        own: const [
          ListingTafelOwn(
            name: 'Neckar',
            notice: ListingNotice.candidate,
            confirmCount: 1,
          ),
        ],
      ),
      'Neckar wartet auf Bestätigung (1/3).',
    );
    expect(
      nearbyListingTafelText(2),
      '2 Runden in der Nähe warten auf Bestätigung.',
    );
  });
}
