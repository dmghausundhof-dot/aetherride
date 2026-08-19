import 'ride_media.dart';
import 'saved_route_note.dart';

export 'ride_media.dart' show isRideVideoPath, RideMedia, RideMediaKind, RideMediaSource;

/// Lokales Post-Ride-Journal: Fotos, kurze Videos, kleine Notizen.
///
/// Liegt in [RideRecord.summary] — kein Cloud-Feed, Pfade nur auf dem Gerät.
/// Geo hängt an [photos]/[videos]; [photoPaths] bleibt der String-Spiegel.
class RideJournal {
  const RideJournal._({
    this.photos = const [],
    this.videos = const [],
    this.notes = const [],
  });

  factory RideJournal({
    List<RideMedia>? photos,
    List<RideMedia>? videos,
    List<String> photoPaths = const [],
    List<String> videoPaths = const [],
    List<SavedRouteNote> notes = const [],
  }) {
    return RideJournal._(
      photos: photos ??
          [
            for (final p in photoPaths)
              if (p.trim().isNotEmpty)
                RideMedia.fromPath(p.trim(), kind: RideMediaKind.photo),
          ],
      videos: videos ??
          [
            for (final p in videoPaths)
              if (p.trim().isNotEmpty)
                RideMedia.fromPath(p.trim(), kind: RideMediaKind.video),
          ],
      notes: notes,
    );
  }

  static const empty = RideJournal._();
  static const maxPhotos = 8;
  static const maxVideos = 4;
  static const maxNotes = 6;
  static const maxNoteChars = 200;
  static const maxVideo = Duration(seconds: 45);

  final List<RideMedia> photos;
  final List<RideMedia> videos;
  final List<SavedRouteNote> notes;

  List<String> get photoPaths => [for (final m in photos) m.path];
  List<String> get videoPaths => [for (final m in videos) m.path];

  List<RideMedia> get media => [...photos, ...videos];

  bool get isEmpty => photos.isEmpty && videos.isEmpty && notes.isEmpty;

  bool get hasMedia => photos.isNotEmpty || videos.isNotEmpty;

  int get mediaCount => photos.length + videos.length;

  bool get canAddPhoto => photos.length < maxPhotos;
  bool get canAddVideo => videos.length < maxVideos;
  bool get canAddNote => notes.length < maxNotes;

  RideJournal copyWith({
    List<RideMedia>? photos,
    List<RideMedia>? videos,
    List<String>? photoPaths,
    List<String>? videoPaths,
    List<SavedRouteNote>? notes,
  }) {
    return RideJournal(
      photos: photos ??
          (photoPaths != null
              ? [
                  for (final p in photoPaths)
                    if (p.trim().isNotEmpty)
                      RideMedia.fromPath(p.trim(), kind: RideMediaKind.photo),
                ]
              : this.photos),
      videos: videos ??
          (videoPaths != null
              ? [
                  for (final p in videoPaths)
                    if (p.trim().isNotEmpty)
                      RideMedia.fromPath(p.trim(), kind: RideMediaKind.video),
                ]
              : this.videos),
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toSummaryPatch() => {
        'photoPaths': photoPaths,
        'videoPaths': videoPaths,
        'rideMedia': [for (final m in media) m.toJson()],
        'notes': [for (final n in notes) n.toJson()],
      };

  factory RideJournal.fromSummary(Map<String, dynamic>? summary) {
    if (summary == null || summary.isEmpty) return empty;
    final tagged = rideMediaFromSummary(summary);
    final photosFromMedia = [
      for (final m in tagged)
        if (m.isPhoto) m,
    ];
    final videosFromMedia = [
      for (final m in tagged)
        if (m.isVideo) m,
    ];
    final pathPhotos = pathsFromSummary(summary, 'photoPaths');
    final pathVideos = pathsFromSummary(summary, 'videoPaths');
    final photos = photosFromMedia.isNotEmpty
        ? photosFromMedia
        : [
            for (final p in pathPhotos)
              RideMedia.fromPath(p, kind: RideMediaKind.photo),
          ];
    final videos = videosFromMedia.isNotEmpty
        ? videosFromMedia
        : [
            for (final p in pathVideos)
              RideMedia.fromPath(p, kind: RideMediaKind.video),
          ];
    return RideJournal(
      photos: photos,
      videos: videos,
      notes: notesFromSummary(summary),
    );
  }
}

List<String> pathsFromSummary(Map<String, dynamic> summary, String key) {
  final raw = summary[key];
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is String && e.trim().isNotEmpty) e.trim(),
  ];
}

List<SavedRouteNote> notesFromSummary(Map<String, dynamic> summary) {
  final raw = summary['notes'];
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map)
        SavedRouteNote.fromJson(Map<String, dynamic>.from(e)),
  ].where((n) => n.text.isNotEmpty).toList();
}

String rideMediaMime(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.mp4') || lower.endsWith('.m4v')) return 'video/mp4';
  if (lower.endsWith('.mov')) return 'video/quicktime';
  if (lower.endsWith('.webm')) return 'video/webm';
  if (lower.endsWith('.3gp')) return 'video/3gpp';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
  return 'image/jpeg';
}

String sanitizeNoteText(String raw) {
  final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.length <= RideJournal.maxNoteChars) return t;
  return t.substring(0, RideJournal.maxNoteChars).trimRight();
}
