import 'package:aetherride_mobile/domain/privacy/consents.dart';
import 'package:aetherride_mobile/domain/ride_journal.dart';
import 'package:aetherride_mobile/domain/ride_media.dart';
import 'package:aetherride_mobile/domain/ride_media_geo.dart';
import 'package:aetherride_mobile/domain/saved_route_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromSummary reads photos, videos and notes', () {
    final note = SavedRouteNote.create(text: 'Nasser Trail');
    final journal = RideJournal.fromSummary({
      'photoPaths': ['/tmp/a.jpg', '', 12],
      'videoPaths': ['/tmp/clip.mp4'],
      'notes': [note.toJson(), {'text': ''}],
    });
    expect(journal.photoPaths, ['/tmp/a.jpg']);
    expect(journal.videoPaths, ['/tmp/clip.mp4']);
    expect(journal.notes.single.text, 'Nasser Trail');
    expect(journal.hasMedia, isTrue);
    expect(journal.mediaCount, 2);
    expect(journal.photos.single.hasPin, isFalse);
  });

  test('fromSummary is empty without keys', () {
    expect(RideJournal.fromSummary(null).isEmpty, isTrue);
    expect(RideJournal.fromSummary({}).isEmpty, isTrue);
    expect(RideJournal.fromSummary({'photoPaths': []}).isEmpty, isTrue);
  });

  test('toSummaryPatch roundtrips photoPaths and rideMedia', () {
    final note = SavedRouteNote.create(text: 'Guter Flow');
    final patch = RideJournal(
      photoPaths: const ['/p.jpg'],
      videoPaths: const ['/v.mp4'],
      notes: [note],
    ).toSummaryPatch();
    expect(patch['photoPaths'], ['/p.jpg']);
    expect(patch['rideMedia'], isA<List>());
    final decoded = RideJournal.fromSummary(patch);
    expect(decoded.photoPaths, ['/p.jpg']);
    expect(decoded.videoPaths, ['/v.mp4']);
    expect(decoded.notes.single.text, 'Guter Flow');
  });

  test('fromSummary prefers geotagged rideMedia over path lists', () {
    final journal = RideJournal.fromSummary({
      'photoPaths': ['/old.jpg'],
      'rideMedia': [
        {
          'id': 'm1',
          'path': '/geo.jpg',
          'kind': 'photo',
          'capturedAt': '2026-08-18T10:00:00.000Z',
          'lat': 49.41,
          'lng': 8.67,
          'source': 'camera',
        },
      ],
    });
    expect(journal.photoPaths, ['/geo.jpg']);
    expect(journal.photos.single.hasPin, isTrue);
    expect(journal.photos.single.lat, 49.41);
  });

  test('sanitizeNoteText clamps length and whitespace', () {
    expect(sanitizeNoteText('  nass   trail  '), 'nass trail');
    final long = 'x' * 400;
    expect(sanitizeNoteText(long).length, RideJournal.maxNoteChars);
  });

  test('caps prevent overflowing the journal', () {
    final photos = [for (var i = 0; i < RideJournal.maxPhotos; i++) '/p$i.jpg'];
    final videos = [for (var i = 0; i < RideJournal.maxVideos; i++) '/v$i.mp4'];
    final notes = [
      for (var i = 0; i < RideJournal.maxNotes; i++)
        SavedRouteNote.create(text: 'n$i'),
    ];
    final full = RideJournal(
      photoPaths: photos,
      videoPaths: videos,
      notes: notes,
    );
    expect(full.canAddPhoto, isFalse);
    expect(full.canAddVideo, isFalse);
    expect(full.canAddNote, isFalse);
  });

  test('isRideVideoPath and mime', () {
    expect(isRideVideoPath('/clip.MP4'), isTrue);
    expect(isRideVideoPath('/shot.jpg'), isFalse);
    expect(rideMediaMime('/clip.mov'), 'video/quicktime');
    expect(rideMediaMime('/shot.jpg'), 'image/jpeg');
  });

  test('stampRideMedia uses last track and strips privacy zones', () {
    const home = PrivacyZone(
      id: 'z1',
      label: 'Zuhause',
      lat: 49.3,
      lng: 8.6,
      radiusM: 200,
    );
    final track = [
      {'lat': 49.3, 'lng': 8.6, 'time': 1000},
      {'lat': 49.31, 'lng': 8.61, 'time': 20000},
    ];
    final shot = RideMedia.fromPath(
      '/a.jpg',
      capturedAt: DateTime.fromMillisecondsSinceEpoch(20000, isUtc: true),
    );
    final pinned = stampRideMedia(
      shot,
      lat: 49.31,
      lng: 8.61,
      track: track,
      zones: const [home],
    );
    expect(pinned.hasPin, isTrue);
    expect(pinned.alongM, isNotNull);

    final hidden = stampRideMedia(
      shot,
      lat: 49.3,
      lng: 8.6,
      track: track,
      zones: const [home],
    );
    expect(hidden.hasPin, isFalse);
    expect(hidden.privacyStripped, isTrue);
  });

  test('nearestTrackPointByTime matches within window', () {
    final track = [
      {'lat': 48.0, 'lng': 9.0, 'time': 1000000},
      {'lat': 48.1, 'lng': 9.1, 'time': 1030000},
    ];
    final hit = nearestTrackPointByTime(
      track,
      DateTime.fromMillisecondsSinceEpoch(1025000, isUtc: true),
    );
    expect(hit?.lat, 48.1);
    expect(
      nearestTrackPointByTime(
        track,
        DateTime.fromMillisecondsSinceEpoch(1500000, isUtc: true),
      ),
      isNull,
    );
  });

  test('SavedRouteMeta roundtrips geotagged media', () {
    final media = RideMedia.fromPath('/tmp/a.jpg', kind: RideMediaKind.photo)
        .copyWith(lat: 49.4, lng: 8.6);
    final decoded = SavedRouteMeta.fromJson(
      SavedRouteMeta(
        description: 'Hausrunde',
        photoPaths: const ['/tmp/a.jpg'],
        media: [media],
        rideId: 'ride-1',
      ).toJson(),
    );
    expect(decoded.photoPaths, ['/tmp/a.jpg']);
    expect(decoded.media.single.hasPin, isTrue);
    expect(decoded.media.single.lat, 49.4);
  });
}
