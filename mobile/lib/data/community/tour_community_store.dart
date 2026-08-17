import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config.dart';
import '../../domain/community/difficulty_crowd.dart';
import '../../domain/community/stimme_tags.dart';

enum CloudSubmitResult { pending, approved, rejected, localOnly, failed }

/// Live-Zähler — nur echte Counts, kein Stub-Rating.
class TourCommunityCounts {
  const TourCommunityCounts({
    this.reviewCount = 0,
    this.photoCount = 0,
    this.averageRating,
    this.difficulty,
  });

  final int reviewCount;
  final int photoCount;
  final double? averageRating;
  final DifficultyCrowd? difficulty;

  bool get hasCommunity => reviewCount > 0 || photoCount > 0;

  static const emptyCopy = 'Noch keine Stimmen.';

  static TourCommunityCounts fromPayload(Object? data) {
    if (data is! Map) return const TourCommunityCounts();
    final reviews = data['reviews'];
    final photos = data['photos'];
    final ratings = <int>[];
    if (reviews is List) {
      for (final e in reviews) {
        if (e is! Map) continue;
        final r = e['rating'];
        if (r is num) {
          final n = r.round();
          if (n >= 1 && n <= 5) ratings.add(n);
        }
      }
    }
    final reviewCount = _intField(data['reviewCount']) ?? ratings.length;
    final photoCount = _intField(data['photoCount']) ??
        (photos is List ? photos.length : 0);
    final avg = ratings.isEmpty
        ? null
        : ratings.fold<int>(0, (a, b) => a + b) / ratings.length;
    return TourCommunityCounts(
      reviewCount: reviewCount,
      photoCount: photoCount,
      averageRating: avg,
      difficulty: DifficultyCrowd.fromJson(data['difficulty']),
    );
  }

  static int? _intField(Object? raw) {
    if (raw is num && raw.isFinite) return raw.round().clamp(0, 9999);
    return null;
  }
}

/// Lokale Community-Basis (Bewertungen, Kommentare, Foto-URIs) pro Tour.
/// Privacy-first: nur gerätelokal; Cloud-Sync später optional (siehe supabase/).
class TourCommunityReview {
  const TourCommunityReview({
    required this.id,
    required this.tourId,
    required this.rating,
    required this.body,
    required this.authorLabel,
    required this.createdAt,
    this.photoUris = const [],
    this.tags = const [],
    this.alongM,
    this.pinLat,
    this.pinLng,
    this.difficultyDelta,
  });

  final String id;
  final String tourId;
  final int rating; // 1–5
  final String body;
  final String authorLabel;
  final DateTime createdAt;
  final List<String> photoUris;
  final List<String> tags;
  final double? alongM;
  final double? pinLat;
  final double? pinLng;
  final int? difficultyDelta;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tourId': tourId,
        'rating': rating,
        'body': body,
        'authorLabel': authorLabel,
        'createdAt': createdAt.toIso8601String(),
        'photoUris': photoUris,
        if (tags.isNotEmpty) 'tags': tags,
        if (alongM != null) 'alongM': alongM,
        if (pinLat != null) 'pinLat': pinLat,
        if (pinLng != null) 'pinLng': pinLng,
        if (difficultyDelta != null) 'difficultyDelta': difficultyDelta,
      };

  static TourCommunityReview? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final tourId = raw['tourId'];
    final rating = raw['rating'];
    final body = raw['body'];
    final author = raw['authorLabel'];
    final created = raw['createdAt'];
    if (id is! String ||
        tourId is! String ||
        rating is! num ||
        body is! String ||
        author is! String ||
        created is! String) {
      return null;
    }
    final r = rating.round().clamp(1, 5);
    final photos = <String>[];
    final rawPhotos = raw['photoUris'];
    if (rawPhotos is List) {
      for (final e in rawPhotos) {
        if (e is String && e.trim().isNotEmpty) photos.add(e.trim());
      }
    }
    return TourCommunityReview(
      id: id,
      tourId: tourId,
      rating: r,
      body: body,
      authorLabel: author,
      createdAt: DateTime.tryParse(created) ?? DateTime.now(),
      photoUris: photos,
      tags: parseStimmeTags(raw['tags']),
      alongM: _finiteDouble(raw['alongM'] ?? raw['along_m']),
      pinLat: _finiteDouble(raw['pinLat'] ?? raw['pin_lat']),
      pinLng: _finiteDouble(raw['pinLng'] ?? raw['pin_lng']),
      difficultyDelta: parseDifficultyDelta(
        raw['difficultyDelta'] ?? raw['difficulty_delta'],
      ),
    );
  }
}

double? _finiteDouble(Object? raw) {
  if (raw is num && raw.isFinite) return raw.toDouble();
  return null;
}

class TourCommunityStore {
  TourCommunityStore({Future<Directory> Function()? dirProvider})
      : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;
  List<TourCommunityReview>? _cache;

  /// Prozess-Cache für Karten-Chips (kein erfundenes Default-Rating).
  static final Map<String, TourCommunityCounts> countsCache = {};

  /// Hof / Chips hören zu — nach lokalem Schreiben ohne App-Neustart.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<File> _file() async {
    final dir = await _dirProvider();
    return File(p.join(dir.path, 'tour_community_local.json'));
  }

  Future<List<TourCommunityReview>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final f = await _file();
      if (!await f.exists()) return _cache = [];
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! List) return _cache = [];
      final out = <TourCommunityReview>[];
      for (final e in decoded) {
        final r = TourCommunityReview.fromJson(e);
        if (r != null) out.add(r);
      }
      return _cache = out;
    } catch (_) {
      return _cache = [];
    }
  }

  Future<void> _save(List<TourCommunityReview> list) async {
    _cache = list;
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode([for (final r in list) r.toJson()]));
    } catch (_) {}
  }

  Future<List<TourCommunityReview>> allReviews() async {
    final all = await _load();
    return List<TourCommunityReview>.from(all)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<TourCommunityReview>> reviewsForTour(String tourId) async {
    final all = await _load();
    final out = all.where((r) => r.tourId == tourId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<double?> averageRating(String tourId) async {
    final list = await reviewsForTour(tourId);
    if (list.isEmpty) return null;
    final sum = list.fold<int>(0, (a, r) => a + r.rating);
    return sum / list.length;
  }

  Future<TourCommunityReview> addReview({
    required String tourId,
    required int rating,
    required String body,
    required String authorLabel,
    List<String> photoUris = const [],
    List<String> tags = const [],
    double? alongM,
    double? pinLat,
    double? pinLng,
    int? difficultyDelta,
  }) async {
    final review = TourCommunityReview(
      id: const Uuid().v4(),
      tourId: tourId,
      rating: rating.clamp(1, 5),
      body: body.trim(),
      authorLabel: authorLabel.trim().isEmpty ? 'Du' : authorLabel.trim(),
      createdAt: DateTime.now(),
      photoUris: photoUris,
      tags: parseStimmeTags(tags),
      alongM: alongM,
      pinLat: pinLat,
      pinLng: pinLng,
      difficultyDelta: parseDifficultyDelta(difficultyDelta),
    );
    final all = List<TourCommunityReview>.from(await _load())..add(review);
    await _save(all);
    _publishLocalCounts(tourId, all);
    return review;
  }

  Future<void> removeReview(String id) async {
    final all = List<TourCommunityReview>.from(await _load());
    String? tourId;
    for (final r in all) {
      if (r.id == id) {
        tourId = r.tourId;
        break;
      }
    }
    all.removeWhere((r) => r.id == id);
    await _save(all);
    if (tourId != null) _publishLocalCounts(tourId, all);
  }

  void _publishLocalCounts(String tourId, List<TourCommunityReview> all) {
    final local = [for (final r in all) if (r.tourId == tourId) r];
    final photos = local.fold<int>(0, (n, r) => n + r.photoUris.length);
    final ratings = [for (final r in local) r.rating];
    countsCache[tourId] = TourCommunityCounts(
      reviewCount: local.length,
      photoCount: photos,
      averageRating: ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      difficulty: countsCache[tourId]?.difficulty,
    );
    revision.value++;
  }

  /// Approved Cloud-Reviews mergen — Fehler = lokal bleiben.
  Future<List<TourCommunityReview>> mergeCloud(String tourId) async {
    final bundle = await mergeCloudBundle(tourId);
    return bundle.reviews;
  }

  Future<({List<TourCommunityReview> reviews, List<String> photoUrls})>
      mergeCloudBundle(String tourId) async {
    final local = await reviewsForTour(tourId);
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/community/tour')
          .replace(queryParameters: {'id': tourId, 'tourId': tourId});
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return _bundleWithCache(tourId, local);
      }
      final body = jsonDecode(res.body);
      final parsed = parseCloudPayload(body, tourId);
      countsCache[tourId] = TourCommunityCounts.fromPayload(body);
      unawaited(_writeCloudCache(tourId, parsed.reviews, parsed.photoUrls));
      final ids = local.map((r) => r.id).toSet();
      return (
        reviews: [...local, ...parsed.reviews.where((r) => !ids.contains(r.id))],
        photoUrls: parsed.photoUrls,
      );
    } catch (_) {
      return _bundleWithCache(tourId, local);
    }
  }

  Future<({List<TourCommunityReview> reviews, List<String> photoUrls})>
      _bundleWithCache(
    String tourId,
    List<TourCommunityReview> local,
  ) async {
    final cached = await _readCloudCache(tourId);
    if (cached == null) {
      return (reviews: local, photoUrls: const <String>[]);
    }
    final ids = local.map((r) => r.id).toSet();
    return (
      reviews: [...local, ...cached.reviews.where((r) => !ids.contains(r.id))],
      photoUrls: cached.photoUrls,
    );
  }

  Future<File> _cloudCacheFile(String tourId) async {
    final dir = await _dirProvider();
    final safe = tourId.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File(p.join(dir.path, 'tour_community_cloud_$safe.json'));
  }

  Future<void> _writeCloudCache(
    String tourId,
    List<TourCommunityReview> reviews,
    List<String> photoUrls,
  ) async {
    try {
      final f = await _cloudCacheFile(tourId);
      await f.writeAsString(
        jsonEncode({
          'reviews': [for (final r in reviews) r.toJson()],
          'photoUrls': photoUrls,
        }),
      );
    } catch (_) {}
  }

  Future<({List<TourCommunityReview> reviews, List<String> photoUrls})?>
      _readCloudCache(String tourId) async {
    try {
      final f = await _cloudCacheFile(tourId);
      if (!await f.exists()) return null;
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return null;
      final reviews = <TourCommunityReview>[];
      final raw = decoded['reviews'];
      if (raw is List) {
        for (final e in raw) {
          final r = TourCommunityReview.fromJson(e);
          if (r != null) reviews.add(r);
        }
      }
      final photos = <String>[];
      final p = decoded['photoUrls'];
      if (p is List) {
        for (final e in p) {
          if (e is String && e.trim().isNotEmpty) photos.add(e.trim());
        }
      }
      return (reviews: reviews, photoUrls: photos);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> cloudPhotoUrls(String tourId) async {
    final bundle = await mergeCloudBundle(tourId);
    return bundle.photoUrls;
  }

  /// Nach Login: lokale Bewertung an die API (pending bis Moderation).
  Future<CloudSubmitResult> submitToCloud(TourCommunityReview review) async {
    try {
      String? token;
      try {
        token = Supabase.instance.client.auth.currentSession?.accessToken;
      } catch (_) {
        token = null;
      }
      if (token == null || token.isEmpty) return CloudSubmitResult.localOnly;
      final photoPaths = await _uploadTourPhotos(
        tourId: review.tourId,
        localPaths: review.photoUris,
      );
      final res = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/api/community/tour'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'tourId': review.tourId,
              'rating': review.rating,
              'body': review.body,
              'authorLabel': review.authorLabel,
              'tags': review.tags,
              if (review.pinLat != null && review.pinLng != null)
                'pin': {
                  'lat': review.pinLat,
                  'lng': review.pinLng,
                  if (review.alongM != null) 'alongM': review.alongM,
                },
              if (review.alongM != null) 'alongM': review.alongM,
              if (review.difficultyDelta != null)
                'difficultyDelta': review.difficultyDelta,
              'photos': [
                for (final path in photoPaths) {'storagePath': path},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final data = jsonDecode(res.body);
          final st = data is Map ? data['status'] : null;
          if (st == 'approved') return CloudSubmitResult.approved;
          if (st == 'rejected') return CloudSubmitResult.rejected;
        } catch (_) {}
        return CloudSubmitResult.pending;
      }
      return CloudSubmitResult.failed;
    } catch (_) {
      return CloudSubmitResult.failed;
    }
  }

  /// Batch-Counts für Tour-Karten (`GET ?ids=`).
  Future<Map<String, TourCommunityCounts>> prefetchCounts(
    List<String> tourIds,
  ) async {
    final ids = tourIds.where((e) => e.trim().isNotEmpty).take(40).toList();
    if (ids.isEmpty) return Map<String, TourCommunityCounts>.from(countsCache);
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/community/tour')
          .replace(queryParameters: {'ids': ids.join(',')});
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return Map.from(countsCache);
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return Map.from(countsCache);
      final raw = decoded['counts'];
      if (raw is Map) {
        raw.forEach((k, v) {
          if (k is! String) return;
          if (v is Map) {
            countsCache[k] = TourCommunityCounts(
              reviewCount: (v['reviewCount'] as num?)?.round() ?? 0,
              photoCount: (v['photoCount'] as num?)?.round() ?? 0,
            );
          }
        });
      }
    } catch (_) {}
    return Map<String, TourCommunityCounts>.from(countsCache);
  }

  /// Test-/Parser-Hilfe: GET `/api/community/tour` Body.
  static ({List<TourCommunityReview> reviews, List<String> photoUrls})
      parseCloudPayload(Object? data, String tourId) {
    if (data is! Map) {
      return (reviews: const <TourCommunityReview>[], photoUrls: const <String>[]);
    }
    final raw = data['reviews'];
    final cloud = <TourCommunityReview>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final ratingRaw = m['rating'];
        if (ratingRaw is! num) continue;
        final rating = ratingRaw.round();
        if (rating < 1 || rating > 5) continue;
        cloud.add(
          TourCommunityReview(
            id: (m['id'] as String?) ?? const Uuid().v4(),
            tourId: (m['tour_id'] as String?) ?? tourId,
            rating: rating,
            body: (m['body'] as String?) ?? '',
            authorLabel: (m['author_label'] as String?) ?? 'Rider',
            createdAt:
                DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
            photoUris: photoUrlsFrom(m['photoUris'] ?? m['photos']),
            tags: parseStimmeTags(m['tags']),
            alongM: _finiteDouble(m['alongM'] ?? m['along_m']),
            pinLat: _finiteDouble(m['pinLat'] ?? m['pin_lat']),
            pinLng: _finiteDouble(m['pinLng'] ?? m['pin_lng']),
            difficultyDelta: parseDifficultyDelta(
              m['difficultyDelta'] ?? m['difficulty_delta'],
            ),
          ),
        );
      }
    }
    final photos = <String>[];
    void addUrl(String? u) {
      final t = u?.trim() ?? '';
      if (t.startsWith('http://') || t.startsWith('https://')) {
        if (!photos.contains(t)) photos.add(t);
      }
    }

    final rawPhotos = data['photos'];
    if (rawPhotos is List) {
      for (final e in rawPhotos) {
        if (e is String) {
          addUrl(e);
        } else if (e is Map) {
          addUrl('${e['url'] ?? e['signed_url'] ?? e['signedUrl'] ?? ''}');
        }
      }
    }
    for (final r in cloud) {
      for (final u in r.photoUris) {
        addUrl(u);
      }
    }
    return (reviews: cloud, photoUrls: photos);
  }

  Future<List<String>> _uploadTourPhotos({
    required String tourId,
    required List<String> localPaths,
  }) async {
    if (localPaths.isEmpty || !AppConfig.isSupabaseConfigured) {
      return const [];
    }
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return const [];
      final out = <String>[];
      for (final raw in localPaths.take(4)) {
        if (raw.startsWith('http://') || raw.startsWith('https://')) continue;
        final file = File(raw);
        if (!await file.exists()) continue;
        final objectPath = '${user.id}/$tourId/${const Uuid().v4()}.jpg';
        await client.storage.from('tour-photos').upload(
              objectPath,
              file,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        out.add(objectPath);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static List<String> photoUrlsFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final e in raw) {
      if (e is String && e.trim().isNotEmpty) out.add(e.trim());
    }
    return out;
  }
}
