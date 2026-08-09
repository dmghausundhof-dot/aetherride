import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../../domain/catalog_bike.dart';
import '../local/app_database.dart';

class CatalogClient {
  CatalogClient(this._db, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final AppDatabase _db;
  final http.Client _http;

  /// OEM-Bike-Katalog (Hersteller → Modelle).
  Future<List<CatalogManufacturer>> fetchBikes({
    String? q,
    String? manufacturer,
    String? category,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/catalog/bikes').replace(
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (manufacturer != null && manufacturer.isNotEmpty)
          'manufacturer': manufacturer,
        if (category != null && category.isNotEmpty) 'category': category,
      },
    );
    final res = await _http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw StateError('Katalog-Bikes HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['manufacturers'];
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map)
          CatalogManufacturer.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  Future<List<CatalogCacheData>> search({
    String? slot,
    String? q,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/catalog').replace(
        queryParameters: {
          if (slot != null) 'slot': slot,
          if (q != null && q.isNotEmpty) 'q': q,
          'limit': '$limit',
        },
      );
      final res = await _http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        final now = DateTime.now().toUtc();
        for (final raw in items) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final id = m['id'] as String?;
          if (id == null) continue;
          await _db.into(_db.catalogCache).insertOnConflictUpdate(
                CatalogCacheCompanion.insert(
                  id: id,
                  slot: (m['slot'] as String?) ?? '',
                  manufacturer: (m['manufacturer'] as String?) ?? '',
                  model: (m['model'] as String?) ?? '',
                  payloadJson: jsonEncode(m),
                  fetchedAt: now,
                ),
              );
        }
      }
    } catch (_) {
      // Offline: fall through to local cache
    }

    final query = _db.select(_db.catalogCache)..limit(limit);
    if (slot != null) {
      query.where((t) => t.slot.equals(slot));
    }
    return query.get();
  }

  /// Einzelnes Komponentenmodell aus Cache/API (für OEM-Install).
  Future<CatalogCacheData?> getModel(String id) async {
    final local = await (_db.select(_db.catalogCache)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (local != null) return local;
    try {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/catalog').replace(
        queryParameters: {'id': id, 'limit': '1'},
      );
      final res = await _http.get(uri, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        final now = DateTime.now().toUtc();
        for (final raw in items) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final mid = m['id'] as String?;
          if (mid == null) continue;
          await _db.into(_db.catalogCache).insertOnConflictUpdate(
                CatalogCacheCompanion.insert(
                  id: mid,
                  slot: (m['slot'] as String?) ?? '',
                  manufacturer: (m['manufacturer'] as String?) ?? '',
                  model: (m['model'] as String?) ?? '',
                  payloadJson: jsonEncode(m),
                  fetchedAt: now,
                ),
              );
          if (mid == id) {
            return await (_db.select(_db.catalogCache)
                  ..where((t) => t.id.equals(id)))
                .getSingleOrNull();
          }
        }
      }
    } catch (_) {}
    final hits = await search(q: id, limit: 20);
    for (final h in hits) {
      if (h.id == id) return h;
    }
    return null;
  }
}
