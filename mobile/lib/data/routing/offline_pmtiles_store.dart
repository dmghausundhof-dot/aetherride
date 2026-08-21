import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'map_style_url.dart';
import 'overview_browse_paint.dart';

/// Thrown when the Offline-Routing sheet closes mid-download.
class OfflineDownloadCancelled implements Exception {
  const OfflineDownloadCancelled();

  @override
  String toString() => 'offline download cancelled';
}

/// Local PMTiles archives (CDN catalog). MapLibre OfflineRegion on
/// `pmtiles://` stalls — this copies the CDN archive into app documents.
abstract final class OfflinePmtilesStore {
  static const dachId = kDachBasemapId;
  static const franceWestId = kFranceWestBasemapId;
  static const alpsSouthId = kAlpsSouthBasemapId;
  static const beneluxId = kBeneluxBasemapId;
  static const italyNorthId = kItalyNorthBasemapId;
  static const italyCenterId = kItalyCenterBasemapId;
  static const italySouthId = kItalySouthBasemapId;
  static const cataloniaPyreneesId = kCataloniaPyreneesBasemapId;
  static const ukSouthId = kUkSouthBasemapId;

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
      '$kOfflinePacksPublicCdnRoot/basemap/$id-style.json?v=$kBasemapStylePaintRev';

  static Future<String> resolveStyleUrl({
    required String remoteFallback,
    List<double>? packBbox,
  }) async {
    final id = basemapArchiveIdForBbox(packBbox);
    final local = await localStyleUri(id);
    if (local != null) return local;
    return styleUrlForArchiveId(id);
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
    await ensureLocalStyleBrowsePaint(id);
    return style.uri.toString();
  }

  /// Older downloads kept Bright greens. Sage paper is a JSON rewrite.
  static Future<void> ensureLocalStyleBrowsePaint(String id) async {
    final file = await styleFile(id);
    if (!await file.exists()) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return;
      final style = Map<String, dynamic>.from(decoded);
      if (!ensureOverviewBrowseStyle(style)) return;
      await file.writeAsString(jsonEncode(style));
    } catch (_) {}
  }

  /// Charcoal HUD canvas when street tiles cannot load. Not the z11 Blatt.
  static Future<String> emptyHudStyleUri() async {
    final file = File(p.join((await dir()).path, kRideHudEmptyStyleFileName));
    await file.parent.create(recursive: true);
    if (!await file.exists() ||
        await file.readAsString() != kRideHudEmptyStyleJson) {
      await file.writeAsString(kRideHudEmptyStyleJson);
    }
    return file.uri.toString();
  }

  /// Stream CDN archive to documents and rewrite style to `pmtiles://file://…`.
  /// Resumes a `.part` file when the CDN answers 206.
  /// Closing the sheet sets [isCancelled]; the `.part` file stays for resume.
  static Future<File> downloadArchive({
    required String id,
    void Function(int received, int? total)? onProgress,
    bool Function()? isCancelled,
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
          if (isCancelled?.call() == true) {
            throw const OfflineDownloadCancelled();
          }
          sink.add(chunk);
          got += chunk.length;
          onProgress?.call(got, total);
        }
      } finally {
        await sink.close();
      }
      if (isCancelled?.call() == true) {
        throw const OfflineDownloadCancelled();
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

    if (isCancelled?.call() == true) {
      throw const OfflineDownloadCancelled();
    }
    await downloadAssets();
    await writeLocalStyle(id);
    return dest;
  }

  static const fontstack = 'Noto Sans Regular';

  static const spriteFiles = <String>[
    'light.json',
    'light.png',
    'light@2x.json',
    'light@2x.png',
  ];

  /// Non-empty Noto ranges on the public bucket (skip 29-byte stubs).
  static const glyphPbfs = <String>[
    '0-255.pbf',
    '256-511.pbf',
    '512-767.pbf',
    '768-1023.pbf',
    '1024-1279.pbf',
    '1280-1535.pbf',
    '1536-1791.pbf',
    '1792-2047.pbf',
    '2048-2303.pbf',
    '2304-2559.pbf',
    '2560-2815.pbf',
    '2816-3071.pbf',
    '3072-3327.pbf',
    '3328-3583.pbf',
    '3584-3839.pbf',
    '3840-4095.pbf',
    '4096-4351.pbf',
    '4608-4863.pbf',
    '4864-5119.pbf',
    '5120-5375.pbf',
    '5376-5631.pbf',
    '5632-5887.pbf',
    '5888-6143.pbf',
    '6144-6399.pbf',
    '6400-6655.pbf',
    '6656-6911.pbf',
    '6912-7167.pbf',
    '7168-7423.pbf',
    '7424-7679.pbf',
    '7680-7935.pbf',
    '7936-8191.pbf',
    '8192-8447.pbf',
    '8448-8703.pbf',
    '8704-8959.pbf',
    '8960-9215.pbf',
    '9216-9471.pbf',
    '9472-9727.pbf',
    '9728-9983.pbf',
    '9984-10239.pbf',
    '10240-10495.pbf',
    '10496-10751.pbf',
    '11008-11263.pbf',
    '11264-11519.pbf',
    '11520-11775.pbf',
    '11776-12031.pbf',
    '12288-12543.pbf',
    '19712-19967.pbf',
    '40960-41215.pbf',
    '41216-41471.pbf',
    '41472-41727.pbf',
    '41728-41983.pbf',
    '41984-42239.pbf',
    '42240-42495.pbf',
    '42496-42751.pbf',
    '42752-43007.pbf',
    '43008-43263.pbf',
    '43264-43519.pbf',
    '43520-43775.pbf',
    '43776-44031.pbf',
    '64256-64511.pbf',
    '64512-64767.pbf',
    '64768-65023.pbf',
    '65024-65279.pbf',
    '65280-65535.pbf',
  ];

  static Future<Directory> assetsDir() async {
    final d = await dir();
    return Directory(p.join(d.path, 'assets'));
  }

  static Future<bool> assetsReady() async {
    final d = await dir();
    final glyph = File(
      p.join(d.path, 'assets', 'fonts', fontstack, '0-255.pbf'),
    );
    final sprite = File(
      p.join(d.path, 'assets', 'sprites', 'v4', 'light.json'),
    );
    if (!await glyph.exists() || !await sprite.exists()) return false;
    return await glyph.length() > 20 && await sprite.length() > 20;
  }

  /// Copy glyphs + sprites (~6 MB) so labels work without CDN.
  static Future<void> downloadAssets({
    void Function(int done, int total)? onProgress,
  }) async {
    final d = await dir();
    final jobs = <({String rel, String url})>[
      for (final f in spriteFiles)
        (
          rel: 'assets/sprites/v4/$f',
          url: '$kOfflinePacksPublicCdnRoot/basemap/assets/sprites/v4/$f',
        ),
      for (final f in glyphPbfs)
        (
          rel: 'assets/fonts/$fontstack/$f',
          url:
              '$kOfflinePacksPublicCdnRoot/basemap/assets/fonts/${Uri.encodeComponent(fontstack)}/$f',
        ),
    ];
    var done = 0;
    onProgress?.call(done, jobs.length);
    for (final job in jobs) {
      final dest = File(p.join(d.path, job.rel));
      if (await dest.exists() && await dest.length() > 20) {
        done += 1;
        onProgress?.call(done, jobs.length);
        continue;
      }
      try {
        final res = await http
            .get(Uri.parse(job.url))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200 && res.bodyBytes.length > 20) {
          await dest.parent.create(recursive: true);
          await dest.writeAsBytes(res.bodyBytes);
        }
      } catch (_) {}
      done += 1;
      onProgress?.call(done, jobs.length);
    }
  }

  static Future<void> writeLocalStyle(String id) async {
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
        'sprite': '$kOfflinePacksPublicCdnRoot/basemap/assets/sprites/v4/light',
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
            'paint': {'background-color': kOverviewBrowseBg},
          },
        ],
      };
    }
    rewriteStyleProtomapsUrl(style, archive.path);
    if (await assetsReady()) {
      rewriteStyleLocalAssets(style, (await dir()).path);
    }
    restyleOverviewBrowse(style);
    final out = await styleFile(id);
    await out.writeAsString(jsonEncode(style));
  }

  static Future<int> totalBytes() async {
    try {
      final d = await dir();
      if (!await d.exists()) return 0;
      var n = 0;
      await for (final e in d.list(recursive: true, followLinks: false)) {
        if (e is File) n += await e.length();
      }
      return n;
    } catch (_) {
      return 0;
    }
  }
}
