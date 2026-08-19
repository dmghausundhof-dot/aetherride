import '../bike.dart';
import '../component.dart';
import '../saved_route.dart';
import '../saved_route_note.dart';

/// Join SavedRoute ↔ Katalog-Stimmen. Kein Fake-Rating.
String? catalogTourIdOf(String routeId, [SavedRouteMeta meta = SavedRouteMeta.empty]) {
  final explicit = meta.catalogTourId?.trim();
  if (explicit != null && explicit.isNotEmpty) return explicit;
  const privatePrefixes = [
    'saved-',
    'gpx-',
    'import-',
    'recorded-',
    'library-',
    'engine-',
  ];
  for (final p in privatePrefixes) {
    if (routeId.startsWith(p)) return null;
  }
  return routeId;
}

/// Verbrauch seit Einbau: Zähler minus Snapshot, nie der Snapshot selbst.
({double km, double hours}) componentWearSinceInstall(
  Bike bike,
  BikeComponent component,
) {
  return (
    km: (bike.odometerKm - component.odometerKm).clamp(0, double.infinity),
    hours: (bike.hours - component.hoursAtInstallResolved)
        .clamp(0, double.infinity),
  );
}

/// Private Host-GPX braucht eine Mitglieds-Kopie — Katalog nicht.
bool needsMemberTrack({
  required String savedRouteId,
  String? catalogTourId,
}) {
  final catalog = catalogTourId?.trim();
  if (catalog != null && catalog.isNotEmpty) return false;
  return catalogTourIdOf(savedRouteId) == null;
}

/// Losfahren aus der Gruppe: Mappe-Treffer oder Katalog-Id, nie Fake-Track.
String? startRidePendingIdForGroup({
  required String savedRouteId,
  String? catalogTourId,
  required List<SavedRouteEntry> saved,
  required Map<String, SavedRouteMeta> metas,
}) {
  final catalog = catalogTourId?.trim();
  final match = resolveAkteSavedRoute(
        pendingId: savedRouteId,
        saved: saved,
        metas: metas,
      ) ??
      (catalog != null && catalog.isNotEmpty
          ? resolveAkteSavedRoute(
              pendingId: catalog,
              saved: saved,
              metas: metas,
            )
          : null);
  if (match != null) return match.id;
  if (catalog != null && catalog.isNotEmpty) return catalog;
  return catalogTourIdOf(savedRouteId);
}

/// Post-Ride / Tafel / Deep-Link: Akte über Saved-ID oder Katalog-Join.
SavedRouteEntry? resolveAkteSavedRoute({
  required String pendingId,
  required List<SavedRouteEntry> saved,
  required Map<String, SavedRouteMeta> metas,
}) {
  final id = pendingId.trim();
  if (id.isEmpty) return null;
  for (final s in saved) {
    if (s.id == id) return s;
  }
  for (final s in saved) {
    final meta = metas[s.id] ?? SavedRouteMeta.empty;
    if (catalogTourIdOf(s.id, meta) == id) return s;
  }
  return null;
}

enum HofTafelKind { care, stimmen, mappe, gruppe, listing }

class HofTafelItem {
  const HofTafelItem({
    required this.id,
    required this.kind,
    required this.text,
  });

  final String id;
  final HofTafelKind kind;
  final String text;
}

/// Höchstens drei Zeilen — Pflege, Freigabe, Gruppe, Stimme, Mappe. Kein Feed.
List<HofTafelItem> buildHofTafel({
  String? careText,
  String? listingText,
  String? stimmenText,
  String? groupText,
  int savedCount = 0,
}) {
  final out = <HofTafelItem>[];
  void add(HofTafelItem item) {
    if (out.length >= 3) return;
    out.add(item);
  }

  final care = careText?.trim();
  if (care != null && care.isNotEmpty) {
    add(HofTafelItem(id: 'care', kind: HofTafelKind.care, text: care));
  }
  final listing = listingText?.trim();
  if (listing != null && listing.isNotEmpty) {
    add(HofTafelItem(id: 'listing', kind: HofTafelKind.listing, text: listing));
  }
  final group = groupText?.trim();
  if (group != null && group.isNotEmpty) {
    add(HofTafelItem(id: 'gruppe', kind: HofTafelKind.gruppe, text: group));
  }
  final stimmen = stimmenText?.trim();
  if (stimmen != null && stimmen.isNotEmpty) {
    add(
      HofTafelItem(id: 'stimmen', kind: HofTafelKind.stimmen, text: stimmen),
    );
  }
  if (savedCount > 0) {
    add(
      HofTafelItem(
        id: 'mappe',
        kind: HofTafelKind.mappe,
        text: formatTourCount(savedCount),
      ),
    );
  }
  return out;
}

/// „1 Tour“ / „2 Touren“ — kein „1 Touren“.
String formatTourCount(int count, {String suffix = ''}) {
  final n = count < 0 ? 0 : count;
  final noun = n == 1 ? 'Tour' : 'Touren';
  final tail = suffix.isEmpty ? '' : ' $suffix';
  return '$n $noun$tail';
}

bool shouldAssignRideWear(String? bikeId) {
  if (bikeId == null) return false;
  final id = bikeId.trim();
  return id.isNotEmpty && id != 'unknown';
}
