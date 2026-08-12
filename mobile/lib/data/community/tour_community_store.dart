import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/config.dart';

enum CloudSubmitResult { pending, localOnly, failed }

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
  });

  final String id;
  final String tourId;
  final int rating; // 1–5
  final String body;
  final String authorLabel;
  final DateTime createdAt;
  final List<String> photoUris;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tourId': tourId,
        'rating': rating,
        'body': body,
        'authorLabel': authorLabel,
        'createdAt': createdAt.toIso8601String(),
        'photoUris': photoUris,
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
    );
  }
}

class TourCommunityStore {
  TourCommunityStore({Future<Directory> Function()? dirProvider})
      : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;
  List<TourCommunityReview>? _cache;

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
  }) async {
    final review = TourCommunityReview(
      id: const Uuid().v4(),
      tourId: tourId,
      rating: rating.clamp(1, 5),
      body: body.trim(),
      authorLabel: authorLabel.trim().isEmpty ? 'Du' : authorLabel.trim(),
      createdAt: DateTime.now(),
      photoUris: photoUris,
    );
    final all = List<TourCommunityReview>.from(await _load())..add(review);
    await _save(all);
    return review;
  }

  Future<void> removeReview(String id) async {
    final all = List<TourCommunityReview>.from(await _load())
      ..removeWhere((r) => r.id == id);
    await _save(all);
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
          .replace(queryParameters: {'tourId': tourId});
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        return (reviews: local, photoUrls: const <String>[]);
      }
      final parsed = parseCloudPayload(jsonDecode(res.body), tourId);
      final ids = local.map((r) => r.id).toSet();
      return (
        reviews: [...local, ...parsed.reviews.where((r) => !ids.contains(r.id))],
        photoUrls: parsed.photoUrls,
      );
    } catch (_) {
      return (reviews: local, photoUrls: const <String>[]);
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
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return CloudSubmitResult.pending;
      }
      return CloudSubmitResult.failed;
    } catch (_) {
      return CloudSubmitResult.failed;
    }
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
        cloud.add(
          TourCommunityReview(
            id: (m['id'] as String?) ?? const Uuid().v4(),
            tourId: (m['tour_id'] as String?) ?? tourId,
            rating: (m['rating'] as num?)?.round().clamp(1, 5) ?? 4,
            body: (m['body'] as String?) ?? '',
            authorLabel: (m['author_label'] as String?) ?? 'Rider',
            createdAt:
                DateTime.tryParse('${m['created_at']}') ?? DateTime.now(),
            photoUris: photoUrlsFrom(m['photoUris'] ?? m['photos']),
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

  static List<String> photoUrlsFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final e in raw) {
      if (e is String && e.trim().isNotEmpty) out.add(e.trim());
    }
    return out;
  }
}
