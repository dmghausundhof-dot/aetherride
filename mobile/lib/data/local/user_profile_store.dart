import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/rider_profile.dart';

/// Persistiert Rider-Profil + Familien-Fahrer (Sync-fähig).
class UserProfileStore {
  static const _fileName = 'user_profile.json';

  RiderProfile riderProfile = const RiderProfile();
  List<FamilyRider> familyRiders = [];
  String? activeFamilyRiderId;
  String? displayName;
  String? bikePhotoPath; // active bike local photo override path map via bikePhotos

  Map<String, String> bikePhotos = {}; // bikeId → local path
  List<String> wishlistIds = []; // catalog / shop ids
  List<Map<String, dynamic>> chatHistory = [];
  /// Sync-Feld: `affiliate` | `marketplace` (Web-Parität).
  String commerceMode = 'affiliate';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<void> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return;
      final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      riderProfile = RiderProfile.fromJson(
        m['riderProfile'] is Map
            ? Map<String, dynamic>.from(m['riderProfile'] as Map)
            : null,
      );
      familyRiders = [
        for (final e in (m['familyRiders'] as List? ?? const []))
          if (e is Map) FamilyRider.fromJson(Map<String, dynamic>.from(e)),
      ];
      activeFamilyRiderId = m['activeFamilyRiderId'] as String?;
      displayName = m['displayName'] as String?;
      bikePhotos = {
        for (final e in (m['bikePhotos'] as Map? ?? {}).entries)
          e.key.toString(): e.value.toString(),
      };
      wishlistIds = [
        for (final e in (m['wishlistIds'] as List? ?? const []))
          if (e is String) e,
      ];
      chatHistory = [
        for (final e in (m['chatHistory'] as List? ?? const []))
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      final cm = m['commerceMode'] as String?;
      if (cm == 'affiliate' || cm == 'marketplace') {
        commerceMode = cm!;
      }
    } catch (_) {}
  }

  Future<void> save() async {
    final f = await _file();
    await f.writeAsString(
      jsonEncode({
        'riderProfile': riderProfile.toJson(),
        'familyRiders': [for (final r in familyRiders) r.toJson()],
        'activeFamilyRiderId': activeFamilyRiderId,
        'displayName': displayName,
        'bikePhotos': bikePhotos,
        'wishlistIds': wishlistIds,
        'chatHistory': chatHistory,
        'commerceMode': commerceMode,
      }),
    );
  }

  Future<void> setRiderProfile(RiderProfile p) async {
    riderProfile = p;
    await save();
  }

  Future<void> setFamilyRiders(List<FamilyRider> riders) async {
    familyRiders = riders;
    if (activeFamilyRiderId != null &&
        !riders.any((r) => r.id == activeFamilyRiderId)) {
      activeFamilyRiderId = null;
    }
    await save();
  }

  Future<void> setActiveFamilyRider(String? id) async {
    activeFamilyRiderId = id;
    await save();
  }

  Future<void> setCommerceMode(String mode) async {
    if (mode != 'affiliate' && mode != 'marketplace') return;
    commerceMode = mode;
    await save();
  }

  /// Gewicht des aktiven Familien-Fahrers oder eigenes Rider-Gewicht.
  double get effectiveWeightKg {
    final id = activeFamilyRiderId;
    if (id != null) {
      for (final r in familyRiders) {
        if (r.id == id) return r.weightKg;
      }
    }
    return riderProfile.riderWeightKg;
  }

  Future<void> setBikePhoto(String bikeId, String path) async {
    bikePhotos[bikeId] = path;
    await save();
  }

  Future<void> toggleWishlist(String id) async {
    if (wishlistIds.contains(id)) {
      wishlistIds.remove(id);
    } else {
      wishlistIds.add(id);
    }
    await save();
  }

  Future<void> appendChat(String role, String text) async {
    chatHistory.add({
      'role': role,
      'text': text,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    if (chatHistory.length > 80) {
      chatHistory = chatHistory.sublist(chatHistory.length - 80);
    }
    await save();
  }

  Future<void> clear() async {
    riderProfile = const RiderProfile();
    familyRiders = [];
    activeFamilyRiderId = null;
    displayName = null;
    bikePhotos = {};
    wishlistIds = [];
    chatHistory = [];
    commerceMode = 'affiliate';
    await save();
  }
}
