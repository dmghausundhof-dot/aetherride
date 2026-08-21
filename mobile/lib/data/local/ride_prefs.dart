import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/routing/battery_preset.dart';
import '../../domain/routing/live_engine.dart';
import '../../domain/routing/tour_nav_geometry.dart';
import '../../domain/tours/add_route_start.dart';

/// Light mid-ride preferences (battery preset, first-ask flag).
/// JSON file under app support — no SharedPreferences plugin required.
abstract final class RidePrefs {
  static const fileName = 'ride_prefs.json';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, fileName));
  }

  static Future<Map<String, dynamic>> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return {};
      final decoded = jsonDecode(await f.readAsString());
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  static Future<void> merge(Map<String, dynamic> patch) async {
    final f = await _file();
    final m = await read();
    for (final e in patch.entries) {
      if (e.value == null) {
        m.remove(e.key);
      } else {
        m[e.key] = e.value;
      }
    }
    await f.writeAsString(jsonEncode(m));
  }

  static Future<RideBatteryPreset> batteryPreset() async {
    final m = await read();
    return RideBatteryPresetX.fromId(m['batteryPreset'] as String?);
  }

  static Future<void> setBatteryPreset(RideBatteryPreset preset) async {
    await merge({
      'batteryPreset': preset.id,
      'batteryPresetChosen': true,
    });
  }

  /// True after the rider has explicitly picked a preset at least once.
  static Future<bool> batteryPresetChosen() async {
    final m = await read();
    return m['batteryPresetChosen'] == true;
  }

  /// Active nav-puck style id (`NavPuckStyle.name`). Null → default Fahrer.
  static Future<String?> navPuckStyleId() async {
    final m = await read();
    final v = m['nav_puck_style'];
    return v is String ? v : null;
  }

  static Future<void> setNavPuckStyleId(String id) async {
    await merge({'nav_puck_style': id});
    navPuckRevision.value++;
  }

  /// Discover/Ride hören mit — Profil ändert den Puck ohne Karten-Remount.
  static final ValueNotifier<int> navPuckRevision = ValueNotifier(0);

  /// Rider dismissed the Pro-HUD “Musik im HUD” permission prompt.
  static Future<bool> hudMediaPromptDismissed() async {
    final m = await read();
    return m['hud_media_prompt_dismissed'] == true;
  }

  static Future<void> setHudMediaPromptDismissed(bool value) async {
    await merge({'hud_media_prompt_dismissed': value});
  }

  /// Start/Ziel-Kapsel (200 m) bei Export, Strava, Heatmap. Default an.
  static Future<bool> privacyTrimEndsEnabled() async {
    final m = await read();
    return m['privacy_trim_ends'] != false;
  }

  static Future<void> setPrivacyTrimEndsEnabled(bool value) async {
    await merge({'privacy_trim_ends': value ? null : false});
  }

  static Future<double> privacyTrimEndsM() async {
    return (await privacyTrimEndsEnabled()) ? 200 : 0;
  }

  /// Live engine picker. Hybrid = server chooses GraphHopper / ORS per profile.
  static Future<LiveRoutingEngine> routingEngine() async {
    final m = await read();
    return LiveRoutingEngineX.parse(m['routingEngine'] as String?);
  }

  static Future<void> setRoutingEngine(LiveRoutingEngine engine) async {
    await merge({
      'routingEngine': engine == LiveRoutingEngine.hybrid ? null : engine.apiId,
    });
  }

  static const _viewportKey = 'discoverViewport';

  /// Letzte lokale Discover-Kartenmitte — kein DACH-Übersichtspin.
  static Future<DiscoverViewport?> discoverViewport() async {
    final m = await read();
    final v = DiscoverViewport.fromJson(m[_viewportKey]);
    if (v == null || !isLocalDiscoverZoom(v.zoom)) return null;
    if (isPlaceholderDiscoverCenter(v.lat, v.lng)) return null;
    return v;
  }

  /// Hof: ungepaarter Puls-Sensor nach Dismiss nicht wieder als Hero.
  static Future<bool> hofWatchHeroDismissed() async {
    final m = await read();
    return m['hof_watch_hero_dismissed'] == true;
  }

  static Future<void> setHofWatchHeroDismissed(bool value) async {
    await merge({'hof_watch_hero_dismissed': value ? true : null});
  }

  static Future<void> setDiscoverViewport(DiscoverViewport view) async {
    if (!isLocalDiscoverZoom(view.zoom)) return;
    if (isPlaceholderDiscoverCenter(view.lat, view.lng)) return;
    await merge({_viewportKey: view.toJson()});
  }

  static const _leanOffsetKey = 'lean_offset_deg';

  /// Mount-zero for HUD lean (phone clamp rest angle). 0 = uncalibrated.
  static Future<double> leanOffsetDeg() async {
    final m = await read();
    final v = m[_leanOffsetKey];
    return v is num ? v.toDouble() : 0;
  }

  static Future<void> setLeanOffsetDeg(double deg) async {
    await merge({_leanOffsetKey: deg == 0 ? null : deg});
  }

  static const _chassisMountedKey = 'chassis_mounted';

  /// Last ride marked the phone as bar-mounted (or a lean zero exists).
  static Future<bool> chassisMounted() async {
    final m = await read();
    return m[_chassisMountedKey] == true;
  }

  static Future<void> setChassisMounted(bool value) async {
    await merge({_chassisMountedKey: value ? true : null});
  }

  static const _lastPlanDestKey = 'last_plan_dest';
  static const _lastPlanDestDismissedKey = 'last_plan_dest_dismissed';

  /// Last Navigieren destination — restore only in the plan sheet, not Explore.
  static Future<LastPlanDest?> lastPlanDest() async {
    final m = await read();
    return LastPlanDest.fromJson(m[_lastPlanDestKey]);
  }

  static Future<void> setLastPlanDest(LastPlanDest dest) async {
    await merge({
      _lastPlanDestKey: dest.toJson(),
      _lastPlanDestDismissedKey: null,
    });
  }

  static Future<void> dismissLastPlanDest(LastPlanDest dest) async {
    await merge({
      _lastPlanDestDismissedKey: {'lat': dest.lat, 'lng': dest.lng},
    });
  }

  static Future<bool> lastPlanDestIsDismissed(LastPlanDest dest) async {
    final m = await read();
    final d = LastPlanDest.fromJson(m[_lastPlanDestDismissedKey]);
    if (d == null) return false;
    return (d.lat - dest.lat).abs() < 1e-5 && (d.lng - dest.lng).abs() < 1e-5;
  }

  static const _planGeocodeRecentsKey = 'plan_geocode_recents';

  static Future<List<PlanGeocodeRecent>> planGeocodeRecents() async {
    final m = await read();
    return parsePlanGeocodeRecents(m[_planGeocodeRecentsKey]);
  }

  static Future<void> setPlanGeocodeRecents(List<PlanGeocodeRecent> hits) async {
    await merge({
      _planGeocodeRecentsKey: [for (final h in hits.take(5)) h.toJson()],
    });
  }

  static const _showFarmTracksKey = 'browse_farm_tracks';

  /// OSM farm tracks on Explore. Default on; A–B still force-hides them.
  static Future<bool> showFarmTracks() async {
    final m = await read();
    return m[_showFarmTracksKey] != false;
  }

  static Future<void> setShowFarmTracks(bool value) async {
    await merge({_showFarmTracksKey: value});
  }

  static const _planLineCoachKey = 'plan_line_coach_dismissed';

  static Future<bool> planLineCoachDismissed() async {
    final m = await read();
    return !planLineCoachShouldShow(stored: m[_planLineCoachKey]);
  }

  static Future<void> setPlanLineCoachDismissed(bool value) async {
    await merge({
      _planLineCoachKey: value
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    });
  }
}

class LastPlanDest {
  const LastPlanDest({
    required this.lat,
    required this.lng,
    this.label,
  });

  final double lat;
  final double lng;
  final String? label;

  static LastPlanDest? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;
    final label = m['label'] as String?;
    return LastPlanDest(
      lat: lat,
      lng: lng,
      label: label?.trim().isEmpty == true ? null : label?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (label != null && label!.trim().isNotEmpty) 'label': label!.trim(),
      };
}

class PlanGeocodeRecent {
  const PlanGeocodeRecent({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  Map<String, dynamic> toJson() => {
        'label': label,
        'lat': lat,
        'lng': lng,
      };
}

List<PlanGeocodeRecent> parsePlanGeocodeRecents(Object? raw) {
  if (raw is! List) return const [];
  final out = <PlanGeocodeRecent>[];
  for (final e in raw) {
    if (e is! Map) continue;
    final m = Map<String, dynamic>.from(e);
    final label = (m['label'] as String?)?.trim() ?? '';
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    if (label.isEmpty || lat == null || lng == null) continue;
    if (lat.abs() > 90 || lng.abs() > 180) continue;
    if (out.any((x) => x.label == label)) continue;
    out.add(PlanGeocodeRecent(label: label, lat: lat, lng: lng));
    if (out.length >= 5) break;
  }
  return out;
}

List<PlanGeocodeRecent> mergePlanGeocodeRecents(
  List<PlanGeocodeRecent> recents,
  LastPlanDest? last,
) {
  final label = last?.label?.trim() ?? '';
  if (last == null || label.isEmpty) return recents.take(5).toList();
  final hit = PlanGeocodeRecent(label: label, lat: last.lat, lng: last.lng);
  return [
    hit,
    ...recents.where((e) => e.label != label),
  ].take(5).toList();
}
