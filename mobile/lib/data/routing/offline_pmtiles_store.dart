import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'map_style_url.dart';

/// Local PMTiles archives (DACH / France-West). MapLibre OfflineRegion on
/// `pmtiles://` stalls — this copies the CDN archive into app documents.
abstract final class OfflinePmtilesStore {
  static const dachId = 'dach-z11';
  static const franceWestId = 'france-west-z11';

  static const minArchiveBytes = 8 * 1024 * 1024;

  static Future<Directory> dir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'basemap'));
  }

  static Future<File> archiveFile(String id) async {
    final d = await dir();
    return File(p.join(d.path, '$id.pmtiles'));
  }

  static Future<File> styleFile(String id) async {
    final d = await dir();
    return File(p.join(d.path, '$id-style.json'));
  }

  static String cdnArchiveUrl(String id) =>
      '$kOfflinePacksPublicCdnRoot/basemap/$id.pmtiles';

  static String cdnStyleUrl(String id) =>
      '$kOfflinePacksPublicCdnRoot/basemap/$id-style.json';

  static Future<String> resolveStyleUrl({
    required String remoteFallback,
    List<double>? packBbox,
  }) async {
    final id = basemapArchiveIdForBbox(packBbox);
    final local = await localStyleUri(id);
    if (local != null) return local;
    if (id == franceWestId) return kFranceWestBasemapStyleUrl;
    return remoteFallback;
  }

  static Future<bool> isReady(String id) async {
    final f = await archiveFile(id);
    if (!await f.exists()) return false;
    return await f.length() > minArchiveBytes;
  }

  static Future<String?> localStyleUri(String id) async {
    if (!await isReady(id)) return null;
    final style = await styleFile(id);
    if (!await style.exists()) return null;
    return style.uri.toString();
  }

  /// Stream CDN archive to documents and rewrite style to `pmtiles://file://…`.
  /// Resumes a `.part` file when the CDN answers 206.
  static Future<File> downloadArchive({
    required String id,
    void Function(int received, int? total)? onProgress,
  }) async {
    final d = await dir();
    await d.create(recursive: true);
    final dest = await archiveFile(id);
    final part = File('${dest.path}.part');
    final client = http.Client();
    try {
      var startAt = 0;
      if (await part.exists()) {
        startAt = await part.length();
        if (startAt < 0) startAt = 0;
      }
      final req = http.Request('GET', Uri.parse(cdnArchiveUrl(id)));
      if (startAt > 0) {
        req.headers['range'] = 'bytes=$startAt-';
      }
      final res = await client.send(req).timeout(const Duration(seconds: 45));
      if (res.statusCode != 200 && res.statusCode != 206) {
        throw HttpException('HTTP ${res.statusCode} for $id');
      }
      final resume = startAt > 0 && res.statusCode == 206;
      final remaining = res.contentLength;
      final total = resume && remaining != null
          ? startAt + remaining
          : (res.statusCode == 200 ? remaining : remaining);
      final sink = part.openWrite(
        mode: resume ? FileMode.append : FileMode.write,
      );
      var got = resume ? startAt : 0;
      try {
        await for (final chunk
            in res.stream.timeout(const Duration(seconds: 90))) {
          sink.add(chunk);
          got += chunk.length;
          onProgress?.call(got, total);
        }
      } finally {
        await sink.close();
      }
      if (got < minArchiveBytes) {
        await part.delete();
        throw StateError('archive too small ($got bytes)');
      }
      if (await dest.exists()) await dest.delete();
      await part.rename(dest.path);
    } finally {
      client.close();
    }

    await _writeLocalStyle(id);
    return dest;
  }

  static Future<void> _writeLocalStyle(String id) async {
    final archive = await archiveFile(id);
    Map<String, dynamic> style;
    try {
      final res = await http
          .get(Uri.parse(cdnStyleUrl(id)))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200 || res.body.isEmpty) {
        throw StateError('style ${res.statusCode}');
      }
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) throw StateError('style not object');
      style = Map<String, dynamic>.from(decoded);
    } catch (_) {
      style = {
        'version': 8,
        'name': id,
        'glyphs':
            '$kOfflinePacksPublicCdnRoot/basemap/assets/fonts/{fontstack}/{range}.pbf',
        'sprite':
            '$kOfflinePacksPublicCdnRoot/basemap/assets/sprites/v4/light',
        'sources': {
          'protomaps': {
            'type': 'vector',
            'attribution': '© OpenStreetMap · Protomaps',
          },
        },
        'layers': [
          {
            'id': 'background',
            'type': 'background',
            'paint': {'background-color': '#e8eee9'},
          },
        ],
      };
    }
    rewriteStyleProtomapsUrl(style, archive.path);
    final out = await styleFile(id);
    await out.writeAsString(jsonEncode(style));
  }
}
