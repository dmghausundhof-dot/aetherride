import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/garage/stand_photo.dart';
import '../local/user_profile_store.dart';
import 'bike_photo_sync.dart';

/// Crop a picked photo to the stand strip and write JPEG.
Future<void> writeStandCroppedJpeg({
  required File source,
  required File dest,
}) async {
  final bytes = await source.readAsBytes();
  final out = croppedStandJpegBytes(bytes);
  await dest.parent.create(recursive: true);
  if (out == null) {
    if (source.path != dest.path) {
      await source.copy(dest.path);
    }
    return;
  }
  await dest.writeAsBytes(out);
}

/// Null when decode fails or the image is already the stand strip.
Uint8List? croppedStandJpegBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  if (!standPhotoNeedsCrop(
    decoded.width.toDouble(),
    decoded.height.toDouble(),
  )) {
    return null;
  }
  final r = standPhotoSourceRect(
    decoded.width.toDouble(),
    decoded.height.toDouble(),
  );
  final x = r.left.round().clamp(0, decoded.width - 1);
  final y = r.top.round().clamp(0, decoded.height - 1);
  final w = r.width.round().clamp(1, decoded.width - x);
  final h = r.height.round().clamp(1, decoded.height - y);
  var cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
  const maxSide = 1200;
  if (cropped.width >= cropped.height && cropped.width > maxSide) {
    cropped = img.copyResize(cropped, width: maxSide);
  } else if (cropped.height > maxSide) {
    cropped = img.copyResize(cropped, height: maxSide);
  }
  return Uint8List.fromList(img.encodeJpg(cropped, quality: 82));
}

/// One-shot crop of photos stored before stand-strip save. Returns true if a
/// file or URL changed (caller should rebuild).
Future<bool> ensureStandCroppedBikePhotos({
  required UserProfileStore store,
  Future<String?> Function(String bikeId, File file)? upload,
}) async {
  var changed = false;
  final entries = Map<String, String>.from(store.bikePhotos);
  for (final e in entries.entries) {
    final bikeId = e.key;
    final ref = e.value;
    if (store.isBikePhotoStandCropped(bikeId, ref)) continue;
    try {
      if (isRemotePhotoRef(ref)) {
        final did = await _cropRemote(
          store: store,
          bikeId: bikeId,
          url: ref,
          upload: upload,
        );
        if (did) changed = true;
        continue;
      }
      final file = File(ref);
      if (!await file.exists()) {
        await store.markBikePhotoStandCropped(bikeId, ref);
        continue;
      }
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        await store.markBikePhotoStandCropped(bikeId, ref);
        continue;
      }
      if (!standPhotoNeedsCrop(
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      )) {
        await store.markBikePhotoStandCropped(bikeId, ref);
        continue;
      }
      final dir = await getApplicationSupportDirectory();
      final dest = File(p.join(dir.path, 'bike_photos', '$bikeId.stand.jpg'));
      await writeStandCroppedJpeg(source: file, dest: dest);
      await FileImage(dest).evict();
      await store.setBikePhoto(bikeId, dest.path);
      final uploaded = await (upload ??
              (String id, File f) =>
                  uploadBikePhotoToStorage(bikeId: id, file: f))
          .call(bikeId, dest);
      if (uploaded != null && uploaded.isNotEmpty) {
        await store.setBikePhoto(bikeId, uploaded);
      }
      final now = store.bikePhotos[bikeId] ?? dest.path;
      await store.markBikePhotoStandCropped(bikeId, now);
      changed = true;
    } catch (_) {
      // Retry next open — do not stamp a failed pass.
    }
  }
  return changed;
}

Future<bool> _cropRemote({
  required UserProfileStore store,
  required String bikeId,
  required String url,
  Future<String?> Function(String bikeId, File file)? upload,
}) async {
  final bytes = await _downloadBytes(url);
  if (bytes == null) return false;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    await store.markBikePhotoStandCropped(bikeId, url);
    return false;
  }
  if (!standPhotoNeedsCrop(
    decoded.width.toDouble(),
    decoded.height.toDouble(),
  )) {
    await store.markBikePhotoStandCropped(bikeId, url);
    return false;
  }
  final jpeg = croppedStandJpegBytes(bytes);
  if (jpeg == null) {
    await store.markBikePhotoStandCropped(bikeId, url);
    return false;
  }
  final dir = await getApplicationSupportDirectory();
  final dest = File(p.join(dir.path, 'bike_photos', '$bikeId.stand.jpg'));
  await dest.parent.create(recursive: true);
  await dest.writeAsBytes(jpeg);
  await FileImage(dest).evict();
  try {
    await NetworkImage(url).evict();
  } catch (_) {}
  await store.setBikePhoto(bikeId, dest.path);
  final uploaded = await (upload ??
          (String id, File f) => uploadBikePhotoToStorage(bikeId: id, file: f))
      .call(bikeId, dest);
  if (uploaded != null && uploaded.isNotEmpty) {
    await store.setBikePhoto(bikeId, uploaded);
    try {
      await NetworkImage(uploaded).evict();
    } catch (_) {}
  }
  final now = store.bikePhotos[bikeId] ?? dest.path;
  await store.markBikePhotoStandCropped(bikeId, now);
  return true;
}

Future<Uint8List?> _downloadBytes(String url) async {
  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 12);
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close().timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    return Uint8List.fromList(await consolidateHttpClientResponseBytes(res));
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
