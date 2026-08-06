import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config.dart';
import '../local/app_database.dart';

class CatalogClient {
  CatalogClient(this._db, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final AppDatabase _db;
  final http.Client _http;

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
}
