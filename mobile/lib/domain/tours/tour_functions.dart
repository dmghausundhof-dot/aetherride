import '../bike.dart';
import '../community/community_seed.dart';

/// Redaktionelle Referenz-Tour — Spiegel von `src/lib/tours/tourFunctions.ts`.
const String referenceTourId = 'r-heidelberg-neckar-voll';

const List<String> tourFunctionIds = [
  'map',
  'elevation',
  'weather',
  'stimmen',
  'share',
  'mappe',
  'gpx',
  'plan',
  'ride',
  'group',
  'event',
  'club',
  'places',
];

class TourFunctionState {
  const TourFunctionState({required this.id, required this.available});

  final String id;
  final bool available;
}

List<CommunityEventSeed> eventsForTour(String tourId) {
  final id = tourId.trim();
  if (id.isEmpty) return const [];
  return [
    for (final e in communityEventSeeds)
      if (e.catalogTourId == id) e,
  ];
}

List<CommunityEventSeed> eventsForRegionSlug(String regionSlug) {
  final slug = regionSlug.trim();
  if (slug.isEmpty) return const [];
  return [
    for (final e in communityEventSeeds)
      if (e.regionSlug == slug) e,
  ];
}

bool tourMatchesSport(Iterable<BikeCategory> categories, String sport) {
  final s = sport.toLowerCase();
  final cats = categories.toList();
  if (s == 'mtb') {
    return cats.any(
      (c) =>
          c == BikeCategory.mtbTrail ||
          c == BikeCategory.mtbAm ||
          c == BikeCategory.mtbEnduro ||
          c == BikeCategory.dh ||
          c == BikeCategory.emtb,
    );
  }
  if (s == 'road') return cats.contains(BikeCategory.road);
  if (s == 'gravel') return cats.contains(BikeCategory.gravel);
  if (s == 'urban') return cats.contains(BikeCategory.urban);
  if (s == 'ebike') {
    return cats.contains(BikeCategory.emtb) ||
        cats.contains(BikeCategory.etrekking);
  }
  if (s == 'touring') {
    return cats.contains(BikeCategory.etrekking) ||
        cats.contains(BikeCategory.road) ||
        cats.contains(BikeCategory.gravel);
  }
  if (s == 'hiking') return cats.contains(BikeCategory.hiking);
  return false;
}

String? regionSlugForTour(String tourId, [Iterable<String> tags = const []]) {
  for (final e in eventsForTour(tourId)) {
    final slug = e.regionSlug?.trim();
    if (slug != null && slug.isNotEmpty) return slug;
  }
  final known = <String>{
    for (final c in communityClubSeeds)
      if (c.regionSlug != null && c.regionSlug!.isNotEmpty) c.regionSlug!,
    for (final e in communityEventSeeds)
      if (e.regionSlug != null && e.regionSlug!.isNotEmpty) e.regionSlug!,
  };
  for (final tag in tags) {
    if (known.contains(tag)) return tag;
  }
  return null;
}

List<CommunityClubSeed> clubsForTour({
  required String tourId,
  String? regionSlug,
  Iterable<BikeCategory> categories = const [],
}) {
  final slug = (regionSlug ?? regionSlugForTour(tourId))?.trim();
  if (slug == null || slug.isEmpty) return const [];
  return [
    for (final club in communityClubSeeds)
      if (club.regionSlug == slug &&
          club.sports.any((sport) => tourMatchesSport(categories, sport)))
        club,
  ];
}

List<TourFunctionState> tourFunctionStates({
  required String tourId,
  String? regionSlug,
  Iterable<BikeCategory> categories = const [],
}) {
  final hasEvent = eventsForTour(tourId).isNotEmpty;
  final hasClub = clubsForTour(
    tourId: tourId,
    regionSlug: regionSlug,
    categories: categories,
  ).isNotEmpty;
  return [
    for (final id in tourFunctionIds)
      TourFunctionState(
        id: id,
        available: id == 'event'
            ? hasEvent
            : id == 'club'
                ? hasClub
                : true,
      ),
  ];
}
