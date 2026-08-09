import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';

/// Upload Bike-Foto nach Supabase Storage (`bike-photos`).
/// Returns public URL or null (offline / not signed in / bucket missing).
Future<String?> uploadBikePhotoToStorage({
  required String bikeId,
  required File file,
}) async {
  if (!AppConfig.isSupabaseConfigured) return null;
  try {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;
    if (!await file.exists()) return null;
    final objectPath = '${user.id}/$bikeId.jpg';
    await client.storage.from('bike-photos').upload(
          objectPath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    return client.storage.from('bike-photos').getPublicUrl(objectPath);
  } catch (e) {
    debugPrint('bike photo upload: $e');
    return null;
  }
}

bool isRemotePhotoRef(String? ref) =>
    ref != null &&
    (ref.startsWith('http://') || ref.startsWith('https://'));
