import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/bike.dart';
import '../../domain/ebike/range.dart';
import '../../domain/ai/coach_inbox.dart';
import '../../domain/ai/coach_watch.dart';
import '../../domain/rider_profile.dart';

/// Persistiert Rider-Profil + Familien-Fahrer (Sync-fähig).
class UserProfileStore {
  static const _fileName = 'user_profile.json';

  RiderProfile riderProfile = const RiderProfile();
  List<FamilyRider> familyRiders = [];
  String? activeFamilyRiderId;
  String? displayName;
  String?
      bikePhotoPath; // active bike local photo override path map via bikePhotos

  /// Profilbild (lokal oder https).
  String? profilePhotoPath;

  Map<String, String> bikePhotos = {}; // bikeId → local path oder https-URL
  /// Pending local paths still needing Storage-Upload (bikeId → path).
  Map<String, String> bikePhotoPending = {};
  List<String> wishlistIds = []; // catalog / shop ids
  List<Map<String, dynamic>> chatHistory = [];
  Map<String, CoachMeta> coachMeta = {};

  /// Sync-Feld: `affiliate` | `marketplace` (Web-Parität).
  String commerceMode = 'affiliate';
  RangeCalibration? rangeCalibration;
  List<Map<String, dynamic>> maintenanceLogs = [];

  /// Einmaliges Onboarding (Sport → Gewicht → erster Ride / Garage).
  bool onboardingDone = false;

  /// Haupt-Disziplin (Onboarding, Discover-Default, Garage-Wizard).
  BikeCategory? preferredSport;

  /// Alle gewählten Disziplinen inkl. Haupt. Nie ohne Haupt, wenn gesetzt.
  List<BikeCategory> preferredSports = [];

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
      profilePhotoPath = m['profilePhotoPath'] as String?;
      bikePhotos = {
        for (final e in (m['bikePhotos'] as Map? ?? {}).entries)
          e.key.toString(): e.value.toString(),
      };
      bikePhotoPending = {
        for (final e in (m['bikePhotoPending'] as Map? ?? {}).entries)
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
      coachMeta = {
        for (final e in (m['coachMeta'] as Map? ?? {}).entries)
          if (e.value is Map)
            e.key.toString(): CoachMeta.fromJson(
              Map<String, dynamic>.from(e.value as Map),
            ),
      };
      final cm = m['commerceMode'] as String?;
      if (cm == 'affiliate' || cm == 'marketplace') {
        commerceMode = cm!;
      }
      if (m['rangeCalibration'] is Map) {
        rangeCalibration = RangeCalibration.fromJson(
          Map<String, dynamic>.from(m['rangeCalibration'] as Map),
        );
      }
      maintenanceLogs = [
        for (final e in (m['maintenanceLogs'] as List? ?? const []))
          if (e is Map) Map<String, dynamic>.from(e),
      ];
      onboardingDone = m.containsKey('onboardingDone')
          ? m['onboardingDone'] == true
          : true; // Legacy: bestehende Profile ohne Key nicht erneut onboarden
      applyPreferredFromJson(m);
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
        if (profilePhotoPath != null) 'profilePhotoPath': profilePhotoPath,
        'bikePhotos': bikePhotos,
        'bikePhotoPending': bikePhotoPending,
        'wishlistIds': wishlistIds,
        'chatHistory': chatHistory,
        'coachMeta': {
          for (final e in coachMeta.entries) e.key: e.value.toJson(),
        },
        'commerceMode': commerceMode,
        if (rangeCalibration != null)
          'rangeCalibration': rangeCalibration!.toJson(),
        'maintenanceLogs': maintenanceLogs,
        'onboardingDone': onboardingDone,
        ...preferredSportsJson(),
      }),
    );
  }

  /// Legacy: nur `preferredSport` → Liste mit einem Eintrag.
  void applyPreferredFromJson(Map<String, dynamic> m) {
    preferredSport = bikeCategoryFromName(m['preferredSport'] as String?);
    final raw = m['preferredSports'];
    if (raw is List) {
      final parsed = <BikeCategory>[];
      for (final e in raw) {
        if (e is! String) continue;
        final c = bikeCategoryFromName(e);
        if (c != null) parsed.add(c);
      }
      preferredSports = parsed;
    } else if (preferredSport != null) {
      preferredSports = [preferredSport!];
    } else {
      preferredSports = [];
    }
    normalizePreferredSports();
  }

  Map<String, dynamic> preferredSportsJson() => {
        if (preferredSport != null) 'preferredSport': preferredSport!.name,
        if (preferredSports.isNotEmpty)
          'preferredSports': [for (final s in preferredSports) s.name],
      };

  /// Haupt immer in der Liste und vorn; Liste leer ↔ keine Haupt.
  void normalizePreferredSports() {
    final seen = <BikeCategory>{};
    preferredSports = [
      for (final s in preferredSports)
        if (seen.add(s)) s,
    ];
    final haupt = preferredSport;
    if (haupt != null) {
      preferredSports = [
        haupt,
        for (final s in preferredSports)
          if (s != haupt) s,
      ];
    } else if (preferredSports.isNotEmpty) {
      preferredSport = preferredSports.first;
    }
    if (preferredSports.isEmpty) {
      preferredSport = null;
    }
  }

  /// Mitgliedschaft umschalten. `false` wenn die letzte Disziplin bliebe.
  bool togglePreferredSport(BikeCategory sport) {
    if (preferredSports.contains(sport)) {
      if (preferredSports.length <= 1) return false;
      preferredSports = [
        for (final s in preferredSports)
          if (s != sport) s,
      ];
      if (preferredSport == sport) {
        preferredSport = preferredSports.first;
      }
    } else {
      preferredSports = [...preferredSports, sport];
      preferredSport ??= sport;
    }
    normalizePreferredSports();
    return true;
  }

  /// Setzt die Haupt-Disziplin und fügt sie der Liste hinzu.
  void setPrimarySport(BikeCategory sport) {
    preferredSport = sport;
    preferredSports = [
      sport,
      for (final s in preferredSports)
        if (s != sport) s,
    ];
    normalizePreferredSports();
  }

  bool prefersSport(BikeCategory sport) => preferredSports.contains(sport);

  Future<void> markOnboardingDone({
    BikeCategory? sport,
    double? weightKg,
  }) async {
    if (sport != null) {
      preferredSport = sport;
      preferredSports = [sport];
    }
    if (weightKg != null) {
      riderProfile = riderProfile.copyWith(riderWeightKg: weightKg);
    }
    onboardingDone = true;
    await save();
  }

  Future<void> setProfilePhoto(String? path) async {
    profilePhotoPath = path;
    await save();
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

  Future<void> setRangeCalibration(RangeCalibration cal) async {
    rangeCalibration = cal;
    await save();
  }

  Future<void> addMaintenanceLog({
    required String bikeId,
    required String activity,
    double? odometerKm,
    double? hours,
    String performer = 'self',
    String? notes,
  }) async {
    maintenanceLogs.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'bikeId': bikeId,
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'activity': activity,
      'performer': performer,
      if (odometerKm != null) 'odometerKm': odometerKm,
      if (hours != null) 'hours': hours,
      if (notes != null) 'notes': notes,
    });
    if (maintenanceLogs.length > 120) {
      maintenanceLogs = maintenanceLogs.sublist(0, 120);
    }
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
    if (path.startsWith('http://') || path.startsWith('https://')) {
      bikePhotoPending.remove(bikeId);
    } else {
      bikePhotoPending[bikeId] = path;
    }
    await save();
  }

  /// Nur syncbare Remote-URLs (keine Gerätepfade).
  Map<String, String> syncableBikePhotos() => {
        for (final e in bikePhotos.entries)
          if (e.value.startsWith('http://') || e.value.startsWith('https://'))
            e.key: e.value,
      };

  /// Pending lokale Fotos hochladen; bei Erfolg URL in [bikePhotos].
  Future<void> flushPendingBikePhotoUploads(
    Future<String?> Function(String bikeId, File file) upload,
  ) async {
    if (bikePhotoPending.isEmpty) return;
    final pending = Map<String, String>.from(bikePhotoPending);
    for (final e in pending.entries) {
      final file = File(e.value);
      if (!await file.exists()) {
        bikePhotoPending.remove(e.key);
        continue;
      }
      final url = await upload(e.key, file);
      if (url != null && url.isNotEmpty) {
        bikePhotos[e.key] = url;
        bikePhotoPending.remove(e.key);
      }
    }
    await save();
  }

  Future<void> mergeRemoteBikePhotos(Map<String, String> remote) async {
    for (final e in remote.entries) {
      if (!e.value.startsWith('http://') && !e.value.startsWith('https://')) {
        continue;
      }
      final local = bikePhotos[e.key];
      final localIsFile = local != null &&
          !local.startsWith('http') &&
          File(local).existsSync();
      if (localIsFile && bikePhotoPending.containsKey(e.key)) {
        // Lokaler Pending-Upload hat Vorrang bis Upload gelingt.
        continue;
      }
      bikePhotos[e.key] = e.value;
      bikePhotoPending.remove(e.key);
    }
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

  Future<void> snoozeCoachNotice(CoachNotice notice, {int days = 7}) async {
    coachMeta = snoozeMeta(coachMeta, notice, days: days);
    await save();
  }

  Future<void> markCoachNoticesRead(Iterable<CoachNotice> notices) async {
    coachMeta = markReadMeta(coachMeta, notices);
    await save();
  }

  Future<void> clear() async {
    riderProfile = const RiderProfile();
    familyRiders = [];
    activeFamilyRiderId = null;
    displayName = null;
    profilePhotoPath = null;
    bikePhotos = {};
    bikePhotoPending = {};
    wishlistIds = [];
    chatHistory = [];
    coachMeta = {};
    commerceMode = 'affiliate';
    rangeCalibration = null;
    maintenanceLogs = [];
    onboardingDone = false;
    preferredSport = null;
    preferredSports = [];
    await save();
  }
}

BikeCategory? bikeCategoryFromName(String? name) {
  if (name == null || name.isEmpty) return null;
  for (final c in BikeCategory.values) {
    if (c.name == name) return c;
  }
  return null;
}
