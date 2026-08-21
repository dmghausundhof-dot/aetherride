/// Freigabe-Gate für User-Touren.
///
/// Link-Share ≠ Karten-Pin. Erst [listingConfirmK] fremde Stimmen im
/// Zeitfenster machen eine Tour listen-fähig — sonst wieder privat.
library;

import '../saved_route_note.dart';


const listingConfirmK = 3;
const listingWindowDays = 14;

enum TourListingState { none, candidate, listed, reverted }

enum ListingNotice { none, candidate, listed, reverted }

enum ListingConfirmationKind { stimme, ride }

class ListingConfirmation {
  const ListingConfirmation({
    required this.riderId,
    required this.at,
    this.kind = ListingConfirmationKind.stimme,
  });

  final String riderId;
  final DateTime at;
  final ListingConfirmationKind kind;
}

class ListingSnapshot {
  const ListingSnapshot({
    this.visibility = 'private',
    this.listing = TourListingState.none,
    this.candidateSince,
    this.listedAt,
    this.shareEpoch = 0,
  });

  final String visibility;
  final TourListingState listing;
  final DateTime? candidateSince;
  final DateTime? listedAt;
  final int shareEpoch;

  ListingSnapshot copyWith({
    String? visibility,
    TourListingState? listing,
    DateTime? candidateSince,
    bool clearCandidateSince = false,
    DateTime? listedAt,
    bool clearListedAt = false,
    int? shareEpoch,
  }) {
    return ListingSnapshot(
      visibility: visibility ?? this.visibility,
      listing: listing ?? this.listing,
      candidateSince:
          clearCandidateSince ? null : (candidateSince ?? this.candidateSince),
      listedAt: clearListedAt ? null : (listedAt ?? this.listedAt),
      shareEpoch: shareEpoch ?? this.shareEpoch,
    );
  }
}

class ListingDecision extends ListingSnapshot {
  const ListingDecision({
    super.visibility,
    super.listing,
    super.candidateSince,
    super.listedAt,
    super.shareEpoch,
    required this.confirmCount,
    this.needed = listingConfirmK,
    this.notice = ListingNotice.none,
    this.changed = false,
    this.expiresAt,
  });

  final int confirmCount;
  final int needed;
  final ListingNotice notice;
  final bool changed;
  final DateTime? expiresAt;
}

const _ownerIds = {'', 'du', 'ich', 'you', 'me', 'rider'};

TourListingState parseListingState(Object? raw) {
  return switch (raw) {
    'candidate' => TourListingState.candidate,
    'listed' => TourListingState.listed,
    'reverted' => TourListingState.reverted,
    _ => TourListingState.none,
  };
}

String listingStateName(TourListingState s) => s.name;

int uniqueConfirmCount(
  List<ListingConfirmation> confirmations, {
  DateTime? since,
}) {
  final seen = <String>{};
  final start = since;
  for (final c in confirmations) {
    final id = c.riderId.trim().toLowerCase();
    if (id.isEmpty || _ownerIds.contains(id)) continue;
    if (start != null && c.at.isBefore(start)) continue;
    seen.add(id);
  }
  return seen.length;
}

/// Stimmen fremder Fahrer — eigene und redaktionelle zählen nicht.
List<ListingConfirmation> confirmationsFromReviews(
  Iterable<({
    String? authorLabel,
    String? authorId,
    DateTime createdAt,
    String? status,
    bool editorial,
  })> reviews, {
  String? ownerLabel,
}) {
  final owner = (ownerLabel ?? '').trim().toLowerCase();
  final out = <ListingConfirmation>[];
  final seen = <String>{};
  for (final r in reviews) {
    if (r.editorial) continue;
    if (r.status != null && r.status != 'approved') continue;
    final riderId = (r.authorId ?? r.authorLabel ?? '').trim();
    final key = riderId.toLowerCase();
    if (key.isEmpty || _ownerIds.contains(key) || key == owner) continue;
    if (!seen.add(key)) continue;
    out.add(
      ListingConfirmation(
        riderId: riderId,
        at: r.createdAt,
        kind: ListingConfirmationKind.stimme,
      ),
    );
  }
  return out;
}

bool _sameSnap(ListingSnapshot a, ListingSnapshot b) {
  return a.visibility == b.visibility &&
      a.listing == b.listing &&
      a.candidateSince == b.candidateSince &&
      a.listedAt == b.listedAt &&
      a.shareEpoch == b.shareEpoch;
}

ListingDecision _decision({
  required ListingSnapshot snap,
  required ListingSnapshot prev,
  required int confirmCount,
  required ListingNotice notice,
  DateTime? expiresAt,
}) {
  return ListingDecision(
    visibility: snap.visibility,
    listing: snap.listing,
    candidateSince: snap.candidateSince,
    listedAt: snap.listedAt,
    shareEpoch: snap.shareEpoch,
    confirmCount: confirmCount,
    notice: notice,
    changed: !_sameSnap(snap, prev),
    expiresAt: expiresAt,
  );
}

/// Ein Tick: Share starten, listen, oder nach dem Fenster zurück auf privat.
ListingDecision tickTourListing({
  required ListingSnapshot snap,
  required bool isCatalog,
  List<ListingConfirmation> confirmations = const [],
  DateTime? now,
}) {
  final clock = now ?? DateTime.now().toUtc();
  final confirmCount = uniqueConfirmCount(
    confirmations,
    since: snap.candidateSince,
  );

  if (isCatalog) {
    return _decision(
      snap: ListingSnapshot(
        visibility: snap.visibility,
        shareEpoch: snap.shareEpoch,
      ),
      prev: snap,
      confirmCount: confirmCount,
      notice: ListingNotice.none,
    );
  }

  if (snap.visibility != 'shared') {
    final listing = snap.listing == TourListingState.reverted
        ? TourListingState.reverted
        : TourListingState.none;
    return _decision(
      snap: ListingSnapshot(
        visibility: 'private',
        listing: listing,
        candidateSince:
            listing == TourListingState.reverted ? snap.candidateSince : null,
        shareEpoch: snap.shareEpoch,
      ),
      prev: snap,
      confirmCount: confirmCount,
      notice: listing == TourListingState.reverted
          ? ListingNotice.reverted
          : ListingNotice.none,
    );
  }

  if (snap.listing == TourListingState.listed) {
    return _decision(
      snap: ListingSnapshot(
        visibility: 'shared',
        listing: TourListingState.listed,
        candidateSince: snap.candidateSince,
        listedAt: snap.listedAt ?? clock,
        shareEpoch: snap.shareEpoch,
      ),
      prev: snap,
      confirmCount: confirmCount < listingConfirmK
          ? listingConfirmK
          : confirmCount,
      notice: ListingNotice.listed,
    );
  }

  final candidateSince = snap.candidateSince ?? clock;
  final expiresAt = candidateSince.add(const Duration(days: listingWindowDays));

  if (confirmCount >= listingConfirmK) {
    return _decision(
      snap: ListingSnapshot(
        visibility: 'shared',
        listing: TourListingState.listed,
        candidateSince: candidateSince,
        listedAt: clock,
        shareEpoch: snap.shareEpoch,
      ),
      prev: snap,
      confirmCount: confirmCount,
      notice: ListingNotice.listed,
    );
  }

  if (!clock.isBefore(expiresAt)) {
    return _decision(
      snap: ListingSnapshot(
        visibility: 'private',
        listing: TourListingState.reverted,
        candidateSince: candidateSince,
        shareEpoch: snap.shareEpoch + 1,
      ),
      prev: snap,
      confirmCount: confirmCount,
      notice: ListingNotice.reverted,
      expiresAt: expiresAt,
    );
  }

  return _decision(
    snap: ListingSnapshot(
      visibility: 'shared',
      listing: TourListingState.candidate,
      candidateSince: candidateSince,
      shareEpoch: snap.shareEpoch,
    ),
    prev: snap,
    confirmCount: confirmCount,
    notice: ListingNotice.candidate,
    expiresAt: expiresAt,
  );
}

ListingSnapshot beginTourShare(
  ListingSnapshot snap, {
  required DateTime now,
  required bool isCatalog,
}) {
  if (isCatalog) {
    return ListingSnapshot(
      visibility: 'shared',
      shareEpoch: snap.shareEpoch,
    );
  }
  if (snap.listing == TourListingState.listed && snap.visibility == 'shared') {
    return snap;
  }
  return ListingSnapshot(
    visibility: 'shared',
    listing: TourListingState.candidate,
    candidateSince: now,
    shareEpoch: snap.shareEpoch,
  );
}

ListingSnapshot unpublishTour(ListingSnapshot snap) {
  final bump = snap.visibility == 'shared' ||
      snap.listing == TourListingState.listed;
  return ListingSnapshot(
    visibility: 'private',
    shareEpoch: bump ? snap.shareEpoch + 1 : snap.shareEpoch,
  );
}

bool listedForPublicExplore({
  required String visibility,
  required TourListingState listing,
}) {
  return listing == TourListingState.listed && visibility == 'shared';
}

String? listingAkteHint(TourListingState listing) {
  return switch (listing) {
    TourListingState.candidate =>
      'Link ist aktiv. Karten-Pin erst nach 3 Stimmen in 14 Tagen.',
    TourListingState.listed => 'Liegt auf der Karte — 3 Stimmen erreicht.',
    TourListingState.reverted =>
      'Wieder privat — zu wenig Stimmen im Fenster.',
    TourListingState.none => null,
  };
}

String? listingTafelText({
  required String name,
  required ListingNotice notice,
  required int confirmCount,
  int needed = listingConfirmK,
}) {
  final n = name.trim().isEmpty ? 'Tour' : name.trim();
  return switch (notice) {
    ListingNotice.reverted => '$n wieder privat — zu wenig Stimmen.',
    ListingNotice.listed => '$n liegt auf der Karte.',
    ListingNotice.candidate =>
      '$n wartet auf Bestätigung ($confirmCount/$needed).',
    ListingNotice.none => null,
  };
}

String? nearbyListingTafelText(int count) {
  final n = count < 0 ? 0 : count;
  if (n <= 0) return null;
  if (n == 1) return '1 Runde in der Nähe wartet auf Bestätigung.';
  return '$n Runden in der Nähe warten auf Bestätigung.';
}

class ListingTafelOwn {
  const ListingTafelOwn({
    required this.name,
    required this.notice,
    required this.confirmCount,
    this.candidateSince,
  });

  final String name;
  final ListingNotice notice;
  final int confirmCount;
  final DateTime? candidateSince;
}

String? pickListingTafel({
  required List<ListingTafelOwn> own,
  int nearbyWaiting = 0,
}) {
  final reverted = [
    for (final o in own)
      if (o.notice == ListingNotice.reverted) o,
  ]..sort((a, b) {
      final aa = a.candidateSince ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bb = b.candidateSince ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bb.compareTo(aa);
    });
  if (reverted.isNotEmpty) {
    return listingTafelText(
      name: reverted.first.name,
      notice: reverted.first.notice,
      confirmCount: reverted.first.confirmCount,
    );
  }
  final waiting = [
    for (final o in own)
      if (o.notice == ListingNotice.candidate) o,
  ]..sort((a, b) => a.confirmCount.compareTo(b.confirmCount));
  if (waiting.isNotEmpty) {
    return listingTafelText(
      name: waiting.first.name,
      notice: waiting.first.notice,
      confirmCount: waiting.first.confirmCount,
    );
  }
  final listed = [
    for (final o in own)
      if (o.notice == ListingNotice.listed) o,
  ];
  if (listed.isNotEmpty) {
    return listingTafelText(
      name: listed.first.name,
      notice: listed.first.notice,
      confirmCount: listed.first.confirmCount,
    );
  }
  return nearbyListingTafelText(nearbyWaiting);
}

ListingSnapshot listingSnapshotOf(SavedRouteMeta meta) {
  return ListingSnapshot(
    visibility: meta.visibility == 'shared' ? 'shared' : 'private',
    listing: parseListingState(meta.listing),
    candidateSince: meta.candidateSince,
    listedAt: meta.listedAt,
    shareEpoch: meta.shareEpoch,
  );
}

SavedRouteMeta applyListingSnapshot(SavedRouteMeta meta, ListingSnapshot snap) {
  return meta.copyWith(
    visibility: snap.visibility,
    listing: listingStateName(snap.listing),
    candidateSince: snap.candidateSince,
    clearCandidateSince: snap.candidateSince == null,
    listedAt: snap.listedAt,
    clearListedAt: snap.listedAt == null,
    shareEpoch: snap.shareEpoch,
  );
}

({SavedRouteMeta meta, ListingDecision decision}) tickSavedMeta({
  required SavedRouteMeta meta,
  required bool isCatalog,
  List<ListingConfirmation> confirmations = const [],
  DateTime? now,
}) {
  final decision = tickTourListing(
    snap: listingSnapshotOf(meta),
    isCatalog: isCatalog,
    confirmations: confirmations,
    now: now,
  );
  return (
    meta: applyListingSnapshot(meta, decision),
    decision: decision,
  );
}
