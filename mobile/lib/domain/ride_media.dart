/// Geotagged ride photo/video. Paths stay device-local.
///
/// [photoPaths] in RideJournal/SavedRouteMeta remains a string mirror so
/// older summaries and UI keep working.
enum RideMediaKind { photo, video }

enum RideMediaSource { camera, gallery, postRide }

class RideMedia {
  const RideMedia({
    required this.id,
    required this.path,
    required this.kind,
    required this.capturedAt,
    this.lat,
    this.lng,
    this.alongM,
    this.caption,
    this.source = RideMediaSource.camera,
    this.privacyStripped = false,
  });

  final String id;
  final String path;
  final RideMediaKind kind;
  final DateTime capturedAt;
  final double? lat;
  final double? lng;
  final double? alongM;
  final String? caption;
  final RideMediaSource source;
  final bool privacyStripped;

  bool get hasPin =>
      lat != null &&
      lng != null &&
      lat!.isFinite &&
      lng!.isFinite &&
      lat!.abs() <= 90 &&
      lng!.abs() <= 180;

  bool get isPhoto => kind == RideMediaKind.photo;
  bool get isVideo => kind == RideMediaKind.video;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'kind': kind == RideMediaKind.video ? 'video' : 'photo',
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        if (hasPin) 'lat': lat,
        if (hasPin) 'lng': lng,
        if (alongM != null && alongM!.isFinite) 'alongM': alongM,
        if (caption != null && caption!.trim().isNotEmpty)
          'caption': caption!.trim(),
        'source': sourceWire(source),
        if (privacyStripped) 'privacyStripped': true,
      };

  factory RideMedia.fromJson(Map<String, dynamic> json) {
    final path = (json['path'] as String? ?? '').trim();
    final kindRaw = (json['kind'] as String? ?? '').trim().toLowerCase();
    final kind = kindRaw == 'video' || isRideVideoPath(path)
        ? RideMediaKind.video
        : RideMediaKind.photo;
    return RideMedia(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? (json['id'] as String).trim()
          : path,
      path: path,
      kind: kind,
      capturedAt: DateTime.tryParse('${json['capturedAt'] ?? ''}') ??
          DateTime.now().toUtc(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      alongM: (json['alongM'] as num?)?.toDouble(),
      caption: (json['caption'] as String?)?.trim(),
      source: sourceFromWire(json['source']),
      privacyStripped: json['privacyStripped'] == true,
    );
  }

  factory RideMedia.fromPath(
    String path, {
    RideMediaKind? kind,
    DateTime? capturedAt,
    RideMediaSource source = RideMediaSource.postRide,
  }) {
    final trimmed = path.trim();
    final resolved = kind ??
        (isRideVideoPath(trimmed) ? RideMediaKind.video : RideMediaKind.photo);
    return RideMedia(
      id: trimmed,
      path: trimmed,
      kind: resolved,
      capturedAt: capturedAt ?? DateTime.now().toUtc(),
      source: source,
    );
  }

  RideMedia copyWith({
    String? id,
    String? path,
    RideMediaKind? kind,
    DateTime? capturedAt,
    double? lat,
    double? lng,
    double? alongM,
    String? caption,
    RideMediaSource? source,
    bool? privacyStripped,
    bool clearPin = false,
    bool clearAlong = false,
  }) {
    return RideMedia(
      id: id ?? this.id,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      capturedAt: capturedAt ?? this.capturedAt,
      lat: clearPin ? null : (lat ?? this.lat),
      lng: clearPin ? null : (lng ?? this.lng),
      alongM: clearAlong ? null : (alongM ?? this.alongM),
      caption: caption ?? this.caption,
      source: source ?? this.source,
      privacyStripped: privacyStripped ?? this.privacyStripped,
    );
  }
}

String sourceWire(RideMediaSource source) => switch (source) {
      RideMediaSource.camera => 'camera',
      RideMediaSource.gallery => 'gallery',
      RideMediaSource.postRide => 'post_ride',
    };

RideMediaSource sourceFromWire(Object? raw) {
  final s = '$raw'.trim().toLowerCase();
  if (s == 'camera') return RideMediaSource.camera;
  if (s == 'gallery') return RideMediaSource.gallery;
  return RideMediaSource.postRide;
}

bool isRideVideoPath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.3gp');
}

List<RideMedia> rideMediaFromSummary(Map<String, dynamic> summary) {
  final raw = summary['rideMedia'];
  if (raw is! List) return const [];
  return [
    for (final e in raw)
      if (e is Map)
        RideMedia.fromJson(Map<String, dynamic>.from(e)),
  ].where((m) => m.path.isNotEmpty).toList();
}
