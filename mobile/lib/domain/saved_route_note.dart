import 'package:uuid/uuid.dart';

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
  });

  final String id;
  final String text;
  final DateTime createdAt;
  final String authorLabel;
  final String? authorUserId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'authorLabel': authorLabel,
        if (authorUserId != null) 'authorUserId': authorUserId,
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
    );
  }

  static SavedRouteNote create({
    required String text,
    String authorLabel = 'Du',
    String? authorUserId,
  }) {
    return SavedRouteNote(
      id: 'note-${const Uuid().v4()}',
      text: text.trim(),
      createdAt: DateTime.now().toUtc(),
      authorLabel: authorLabel,
      authorUserId: authorUserId,
    );
  }
}

/// Neben Geometrie: Beschreibung, Fotos, Notizen an Saved Routes.
class SavedRouteMeta {
  const SavedRouteMeta({
    this.description = '',
    this.photoPaths = const [],
    this.notes = const [],
    this.rideId,
    this.catalogTourId,
    this.preferredBikeId,
    this.visibility = 'private',
    this.shareEpoch = 0,
    this.updatedAt,
  });

  final String description;
  final List<String> photoPaths;
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
  final DateTime? updatedAt;

  static const empty = SavedRouteMeta();

  bool get isEmpty =>
      description.trim().isEmpty &&
      photoPaths.isEmpty &&
      notes.isEmpty &&
      rideId == null &&
      catalogTourId == null &&
      preferredBikeId == null &&
      visibility != 'shared' &&
      shareEpoch == 0;

  Map<String, dynamic> toJson() => {
        'description': description,
        'photoPaths': photoPaths,
        'notes': [for (final n in notes) n.toJson()],
        if (rideId != null) 'rideId': rideId,
        if (catalogTourId != null) 'catalogTourId': catalogTourId,
        if (preferredBikeId != null) 'preferredBikeId': preferredBikeId,
        if (visibility == 'shared') 'visibility': 'shared',
        if (shareEpoch > 0) 'shareEpoch': shareEpoch,
        'updatedAt':
            (updatedAt ?? DateTime.now().toUtc()).toIso8601String(),
      };

  factory SavedRouteMeta.fromJson(Map<String, dynamic> json) {
    return SavedRouteMeta(
      description: json['description'] as String? ?? '',
      photoPaths: (json['photoPaths'] as List?)
              ?.map((e) => '$e')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
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
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  SavedRouteMeta copyWith({
    String? description,
    List<String>? photoPaths,
    List<SavedRouteNote>? notes,
    String? rideId,
    bool clearRideId = false,
    String? catalogTourId,
    bool clearCatalogTourId = false,
    String? preferredBikeId,
    bool clearPreferredBikeId = false,
    String? visibility,
    int? shareEpoch,
    DateTime? updatedAt,
  }) {
    return SavedRouteMeta(
      description: description ?? this.description,
      photoPaths: photoPaths ?? this.photoPaths,
      notes: notes ?? this.notes,
      rideId: clearRideId ? null : (rideId ?? this.rideId),
      catalogTourId:
          clearCatalogTourId ? null : (catalogTourId ?? this.catalogTourId),
      preferredBikeId: clearPreferredBikeId
          ? null
          : (preferredBikeId ?? this.preferredBikeId),
      visibility: visibility ?? this.visibility,
      shareEpoch: shareEpoch ?? this.shareEpoch,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }
}
