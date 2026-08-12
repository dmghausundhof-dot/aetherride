import 'dart:async';
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

  /// Pseudo-Zeile in `catalogCache` für den gesamten Bike-Katalog —
  /// „Bike anlegen" öffnet damit sofort statt auf die API zu warten.
  static const _bikesCacheId = '__bikes-catalog-v2__';
  static const _bikesCacheTtl = Duration(hours: 24);
  static const _bikesTimeout = Duration(seconds: 10);

  /// OEM-Bike-Katalog (Hersteller → Modelle).
  ///
  /// Die ungefilterte Vollliste (der „Bike anlegen"-Fall) kommt aus dem
  /// lokalen Cache und wird bei Bedarf im Hintergrund aufgefrischt —
  /// vorher wartete jeder Sheet-Open auf die volle API-Antwort.
  Future<List<CatalogManufacturer>> fetchBikes({
    String? q,
    String? manufacturer,
    String? category,
    bool forceRefresh = false,
  }) async {
    final hasFilter = (q != null && q.isNotEmpty) ||
        (manufacturer != null && manufacturer.isNotEmpty) ||
        (category != null && category.isNotEmpty);
    if (!hasFilter && !forceRefresh) {
      final cached = await _readBikesCache();
      if (cached != null) {
        if (cached.stale) {
          unawaited(
            _fetchBikesRemote().then(_storeBikesCache).catchError((_) {}),
          );
        }
        return cached.list;
      }
    }
    final List<CatalogManufacturer> list;
    try {
      list = await _fetchBikesRemote(
        q: q,
        manufacturer: manufacturer,
        category: category,
      );
    } catch (e) {
      // API down (z. B. Gerät offline): lieber den ggf. veralteten Cache
      // liefern als hart fehlschlagen — relevant für forceRefresh.
      if (!hasFilter) {
        final cached = await _readBikesCache();
        if (cached != null) return cached.list;
      }
      throw StateError(
        'Bike-Katalog nicht erreichbar (${AppConfig.apiBaseUrl}): $e',
      );
    }
    if (!hasFilter) {
      await _storeBikesCache(list);
    }
    return list;
  }

  Future<List<CatalogManufacturer>> _fetchBikesRemote({
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
    final res = await _http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(_bikesTimeout);
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

  Future<({List<CatalogManufacturer> list, bool stale})?>
      _readBikesCache() async {
    final row = await (_db.select(_db.catalogCache)
          ..where((t) => t.id.equals(_bikesCacheId)))
        .getSingleOrNull();
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.payloadJson);
      if (decoded is! List) return null;
      final list = [
        for (final e in decoded)
          if (e is Map)
            CatalogManufacturer.fromJson(Map<String, dynamic>.from(e)),
      ];
      if (list.isEmpty) return null;
      final age = DateTime.now().toUtc().difference(row.fetchedAt);
      return (list: list, stale: age > _bikesCacheTtl);
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeBikesCache(List<CatalogManufacturer> list) async {
    if (list.isEmpty) return;
    await _db.into(_db.catalogCache).insertOnConflictUpdate(
          CatalogCacheCompanion.insert(
            id: _bikesCacheId,
            slot: '__bikes__',
            manufacturer: '',
            model: '',
            payloadJson: jsonEncode([for (final m in list) m.toJson()]),
            fetchedAt: DateTime.now().toUtc(),
          ),
        );
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
