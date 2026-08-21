import 'package:uuid/uuid.dart';

import 'ride_media.dart';

/// Lokaler Kommentar / Notiz an einer eigenen Strecke.
///
/// Kein Fake-Social: ohne Auth bleibt authorLabel lokal („Du“).
/// Sync-fähig als JSON; öffentliche Community-Comments = Phase 2.
class SavedRouteNote {
  const SavedRouteNote({
    required this.id,
    required this.text,
    required this.createdAt,
    this.authorLabel = 'Du',
    this.authorUserId,
    this.lat,
    this.lng,
    this.kind,
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String authorLabel;
  final String? authorUserId;
  final double? lat;
  final double? lng;
  final String? kind;

  bool get hasPin =>
      lat != null &&
      lng != null &&
      lat!.isFinite &&
      lng!.isFinite &&
      lat!.abs() <= 90 &&
      lng!.abs() <= 180;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'authorLabel': authorLabel,
        if (authorUserId != null) 'authorUserId': authorUserId,
        if (hasPin) 'lat': lat,
        if (hasPin) 'lng': lng,
        if (kind != null && kind!.trim().isNotEmpty) 'kind': kind!.trim(),
      };

  factory SavedRouteNote.fromJson(Map<String, dynamic> json) {
    return SavedRouteNote(
      id: json['id'] as String? ?? '',
      text: (json['text'] as String? ?? '').trim(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      authorLabel: (json['authorLabel'] as String?)?.trim().isNotEmpty == true
          ? (json['authorLabel'] as String).trim()
          : 'Du',
      authorUserId: json['authorUserId'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      kind: (json['kind'] as String?)?.trim(),
    );
  }

  static SavedRouteNote create({
    required String text,
    String authorLabel = 'Du',
    String? authorUserId,
    double? lat,
    double? lng,
    String? kind,
  }) {
    return SavedRouteNote(
      id: 'note-${const Uuid().v4()}',
      text: text.trim(),
      createdAt: DateTime.now().toUtc(),
      authorLabel: authorLabel,
      authorUserId: authorUserId,
      lat: lat,
      lng: lng,
      kind: kind,
    );
  }
}

/// Neben Geometrie: Beschreibung, Fotos, Notizen an Saved Routes.
class SavedRouteMeta {
  const SavedRouteMeta({
    this.description = '',
    this.photoPaths = const [],
    this.media = const [],
    this.notes = const [],
    this.rideId,
    this.catalogTourId,
    this.preferredBikeId,
    this.visibility = 'private',
    this.shareEpoch = 0,
    this.listing = 'none',
    this.candidateSince,
    this.listedAt,
    this.updatedAt,
    this.mtbScale,
    this.surface,
  });

  final String description;
  final List<String> photoPaths;
  /// Geotagged Fotos/Videos. [photoPaths] bleibt der String-Spiegel.
  final List<RideMedia> media;
  final List<SavedRouteNote> notes;
  final String? rideId;
  /// Join zur öffentlichen Tour (Stimmen). Nur Katalog, nie GPX-Import.
  final String? catalogTourId;
  /// Welches Rad für diese Runde — optional.
  final String? preferredBikeId;
  /// `private` (Default) oder `shared`. Altbestand ohne Feld = privat.
  final String visibility;
  /// Steigt bei „zurück auf privat“ — Token-Invalidierung lokal.
  final int shareEpoch;
  /// `none` / `candidate` / `listed` / `reverted`. Explore nur bei listed.
  final String listing;
  final DateTime? candidateSince;
  final DateTime? listedAt;
  final DateTime? updatedAt;
  /// Echte Scale/Belag — nur setzen wenn die Quelle sie trägt.
  final String? mtbScale;
  final String? surface;

  static const empty = SavedRouteMeta();

  bool get isEmpty =>
      description.trim().isEmpty &&
      photoPaths.isEmpty &&
      media.isEmpty &&
      notes.isEmpty &&
      rideId == null &&
      catalogTourId == null &&
      preferredBikeId == null &&
      visibility != 'shared' &&
      shareEpoch == 0 &&
      (listing == 'none' || listing.isEmpty) &&
      candidateSince == null &&
      listedAt == null &&
      mtbScale == null &&
      surface == null;

  Map<String, dynamic> toJson() => {
        'description': description,
        'photoPaths': photoPaths.isNotEmpty
            ? photoPaths
            : [for (final m in media) if (m.isPhoto) m.path],
        if (media.isNotEmpty) 'rideMedia': [for (final m in media) m.toJson()],
        'notes': [for (final n in notes) n.toJson()],
        if (rideId != null) 'rideId': rideId,
        if (catalogTourId != null) 'catalogTourId': catalogTourId,
        if (preferredBikeId != null) 'preferredBikeId': preferredBikeId,
        if (visibility == 'shared') 'visibility': 'shared',
        if (shareEpoch > 0) 'shareEpoch': shareEpoch,
        if (listing != 'none' && listing.isNotEmpty) 'listing': listing,
        if (candidateSince != null)
          'candidateSince': candidateSince!.toUtc().toIso8601String(),
        if (listedAt != null) 'listedAt': listedAt!.toUtc().toIso8601String(),
        if (mtbScale != null && mtbScale!.trim().isNotEmpty)
          'mtbScale': mtbScale,
        if (surface != null && surface!.trim().isNotEmpty) 'surface': surface,
        'updatedAt':
            (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      };

  factory SavedRouteMeta.fromJson(Map<String, dynamic> json) {
    final tagged = rideMediaFromSummary(json);
    final paths = (json['photoPaths'] as List?)
            ?.map((e) => '$e')
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final media = tagged.isNotEmpty
        ? tagged
        : [
            for (final p in paths) RideMedia.fromPath(p, kind: RideMediaKind.photo),
          ];
    return SavedRouteMeta(
      description: json['description'] as String? ?? '',
      photoPaths: paths.isNotEmpty
          ? paths
          : [for (final m in media) if (m.isPhoto) m.path],
      media: media,
      notes: [
        for (final e in (json['notes'] as List? ?? const []))
          if (e is Map)
            SavedRouteNote.fromJson(Map<String, dynamic>.from(e)),
      ],
      rideId: json['rideId'] as String?,
      catalogTourId: json['catalogTourId'] as String?,
      preferredBikeId: json['preferredBikeId'] as String?,
      visibility: json['visibility'] == 'shared' ? 'shared' : 'private',
      shareEpoch: (json['shareEpoch'] as num?)?.toInt() ?? 0,
      listing: _listingFromJson(json['listing']),
      candidateSince: DateTime.tryParse(json['candidateSince'] as String? ?? ''),
      listedAt: DateTime.tryParse(json['listedAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      mtbScale: (json['mtbScale'] as String?)?.trim(),
      surface: (json['surface'] as String?)?.trim(),
    );
  }

  SavedRouteMeta copyWith({
    String? description,
    List<String>? photoPaths,
    List<RideMedia>? media,
    List<SavedRouteNote>? notes,
    String? rideId,
    bool clearRideId = false,
    String? catalogTourId,
    bool clearCatalogTourId = false,
    String? preferredBikeId,
    bool clearPreferredBikeId = false,
    String? visibility,
    int? shareEpoch,
    String? listing,
    DateTime? candidateSince,
    bool clearCandidateSince = false,
    DateTime? listedAt,
    bool clearListedAt = false,
    DateTime? updatedAt,
    String? mtbScale,
    bool clearMtbScale = false,
    String? surface,
    bool clearSurface = false,
  }) {
    return SavedRouteMeta(
      description: description ?? this.description,
      photoPaths: photoPaths ??
          (media != null
              ? [for (final m in media) if (m.isPhoto) m.path]
              : this.photoPaths),
      media: media ?? this.media,
      notes: notes ?? this.notes,
      rideId: clearRideId ? null : (rideId ?? this.rideId),
      catalogTourId:
          clearCatalogTourId ? null : (catalogTourId ?? this.catalogTourId),
      preferredBikeId: clearPreferredBikeId
          ? null
          : (preferredBikeId ?? this.preferredBikeId),
      visibility: visibility ?? this.visibility,
      shareEpoch: shareEpoch ?? this.shareEpoch,
      listing: listing ?? this.listing,
      candidateSince: clearCandidateSince
          ? null
          : (candidateSince ?? this.candidateSince),
      listedAt: clearListedAt ? null : (listedAt ?? this.listedAt),
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
      mtbScale: clearMtbScale ? null : (mtbScale ?? this.mtbScale),
      surface: clearSurface ? null : (surface ?? this.surface),
    );
  }
}

String _listingFromJson(Object? raw) {
  if (raw == 'candidate' || raw == 'listed' || raw == 'reverted') {
    return raw as String;
  }
  return 'none';
}
