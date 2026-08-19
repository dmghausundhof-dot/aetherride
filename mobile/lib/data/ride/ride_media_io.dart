import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/privacy/consents.dart';
import '../../domain/ride.dart';
import '../../domain/ride_journal.dart';
import '../../domain/ride_media_exif.dart';
import '../../domain/ride_media_geo.dart';

Future<Directory> rideMediaDirectory(String name) async {
  final root = await getApplicationSupportDirectory();
  final dir = Directory(p.join(root.path, name));
  await dir.create(recursive: true);
  return dir;
}

List<Map<String, dynamic>> trackJsonOf(List<TrackPoint> track) =>
    [for (final t in track) t.toJson()];

Future<RideMedia?> pickRidePhoto({
  required ImageSource source,
  required RideJournal journal,
  TrackPoint? lastFix,
  List<Map<String, dynamic>> track = const [],
  List<PrivacyZone> zones = const [],
  bool fallbackLastTrack = false,
}) async {
  if (!journal.canAddPhoto) return null;
  final x = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1920,
    imageQuality: 85,
  );
  if (x == null) return null;
  final dest = File(
    p.join((await rideMediaDirectory('ride_photos')).path, '${const Uuid().v4()}.jpg'),
  );
  await File(x.path).copy(dest.path);
  return _stampPicked(
    dest: dest,
    originalPath: x.path,
    kind: RideMediaKind.photo,
    source: source,
    lastFix: lastFix,
    track: track,
    zones: zones,
    fallbackLastTrack: fallbackLastTrack,
  );
}

Future<RideMedia?> pickRideVideo({
  required ImageSource source,
  required RideJournal journal,
  TrackPoint? lastFix,
  List<Map<String, dynamic>> track = const [],
  List<PrivacyZone> zones = const [],
  bool fallbackLastTrack = false,
}) async {
  if (!journal.canAddVideo) return null;
  final x = await ImagePicker().pickVideo(
    source: source,
    maxDuration: RideJournal.maxVideo,
  );
  if (x == null) return null;
  final ext = p.extension(x.path).toLowerCase();
  final safe = {'.mp4', '.mov', '.m4v', '.webm', '.3gp'}.contains(ext)
      ? ext
      : '.mp4';
  final dest = File(
    p.join(
      (await rideMediaDirectory('ride_videos')).path,
      '${const Uuid().v4()}$safe',
    ),
  );
  await File(x.path).copy(dest.path);
  return _stampPicked(
    dest: dest,
    originalPath: x.path,
    kind: RideMediaKind.video,
    source: source,
    lastFix: lastFix,
    track: track,
    zones: zones,
    fallbackLastTrack: fallbackLastTrack,
  );
}

Future<RideMedia> _stampPicked({
  required File dest,
  required String originalPath,
  required RideMediaKind kind,
  required ImageSource source,
  TrackPoint? lastFix,
  required List<Map<String, dynamic>> track,
  required List<PrivacyZone> zones,
  bool fallbackLastTrack = false,
}) async {
  final fromCamera = source == ImageSource.camera;
  DateTime capturedAt = DateTime.now().toUtc();
  if (!fromCamera) {
    try {
      capturedAt = (await File(originalPath).lastModified()).toUtc();
    } catch (_) {}
  }
  var lat = fromCamera ? lastFix?.lat : null;
  var lng = fromCamera ? lastFix?.lng : null;
  if (lat == null || lng == null) {
    try {
      final gps = readJpegGps(await dest.readAsBytes());
      lat = gps?.lat;
      lng = gps?.lng;
    } catch (_) {}
  }
  final media = RideMedia(
    id: 'media-${const Uuid().v4()}',
    path: dest.path,
    kind: kind,
    capturedAt: capturedAt,
    source: fromCamera ? RideMediaSource.camera : RideMediaSource.gallery,
  );
  return stampRideMedia(
    media,
    lat: lat,
    lng: lng,
    track: track,
    zones: zones,
    fallbackLastTrack: fallbackLastTrack,
  );
}
