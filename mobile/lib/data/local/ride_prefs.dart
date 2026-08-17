import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/routing/battery_preset.dart';
import '../../domain/routing/live_engine.dart';
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

  /// Active nav-puck style id (`NavPuckStyle.name`). Null → default Chevron.
  static Future<String?> navPuckStyleId() async {
    final m = await read();
    final v = m['nav_puck_style'];
    return v is String ? v : null;
  }

  static Future<void> setNavPuckStyleId(String id) async {
    await merge({'nav_puck_style': id});
  }

  /// Rider dismissed the Pro-HUD “Musik im HUD” permission prompt.
  static Future<bool> hudMediaPromptDismissed() async {
    final m = await read();
    return m['hud_media_prompt_dismissed'] == true;
  }

  static Future<void> setHudMediaPromptDismissed(bool value) async {
    await merge({'hud_media_prompt_dismissed': value});
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
}
