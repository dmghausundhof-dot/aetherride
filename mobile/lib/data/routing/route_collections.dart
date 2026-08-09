import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Collections-lite: benannte Listen für Saved Routes (lokal + Sync-Feld).
class RouteCollection {
  const RouteCollection({
    required this.id,
    required this.name,
    required this.routeIds,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> routeIds;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'routeIds': routeIds,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory RouteCollection.fromJson(Map<String, dynamic> json) {
    return RouteCollection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sammlung',
      routeIds: (json['routeIds'] as List?)
              ?.map((e) => '$e')
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

abstract final class RouteCollectionsStore {
  static const fileName = 'route_collections.json';
  static const syncField = 'routeCollections';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }

  static Future<List<RouteCollection>> list() async {
    try {
      final f = await _file();
      if (!await f.exists()) return [];
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is! Map) return [];
      final raw = decoded['collections'];
      if (raw is! List) return [];
      return [
        for (final e in raw)
          if (e is Map) RouteCollection.fromJson(Map<String, dynamic>.from(e)),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Payload-Fragment für Sync (LWW).
  static Future<Map<String, dynamic>> syncPayload() async {
    final cols = await list();
    return {
      syncField: [for (final c in cols) c.toJson()],
    };
  }

  static Future<void> _write(List<RouteCollection> cols) async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode({
        'collections': [for (final c in cols) c.toJson()],
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  static Future<RouteCollection> create(String name) async {
    final cols = await list();
    final c = RouteCollection(
      id: 'col-${const Uuid().v4()}',
      name: name.trim().isEmpty ? 'Sammlung' : name.trim(),
      routeIds: const [],
      updatedAt: DateTime.now().toUtc(),
    );
    await _write([...cols, c]);
    return c;
  }

  static Future<void> addRoute(String collectionId, String routeId) async {
    final cols = await list();
    await _write([
      for (final c in cols)
        if (c.id == collectionId)
          RouteCollection(
            id: c.id,
            name: c.name,
            routeIds: {
              ...c.routeIds,
              routeId,
            }.toList(),
            updatedAt: DateTime.now().toUtc(),
          )
        else
          c,
    ]);
  }

  static Future<void> applyFromSync(dynamic raw) async {
    if (raw is! List) return;
    final remote = <RouteCollection>[
      for (final e in raw)
        if (e is Map) RouteCollection.fromJson(Map<String, dynamic>.from(e)),
    ];
    if (remote.isEmpty) return;
    final local = await list();
    // LWW by updatedAt per id
    final byId = <String, RouteCollection>{
      for (final c in local) c.id: c,
    };
    for (final r in remote) {
      final prev = byId[r.id];
      if (prev == null || !r.updatedAt.isBefore(prev.updatedAt)) {
        byId[r.id] = r;
      }
    }
    await _write(byId.values.toList());
  }

  static Future<void> delete(String id) async {
    final cols = await list();
    await _write([for (final c in cols) if (c.id != id) c]);
  }
}
