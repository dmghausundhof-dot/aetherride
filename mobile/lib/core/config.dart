/// Compile-time / runtime config for mobile.
/// Pass via `--dart-define=SUPABASE_URL=...` etc.
import '../data/routing/offline_maps_prefs.dart';

abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://krmgatsugplouzrhhozn.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Next.js API origin for sync / route / catalog (local or production).
  /// Emulator → host loopback: http://10.0.2.2:3001
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001',
  );

  static const pmtilesUrl = String.fromEnvironment(
    'PMTILES_URL',
    defaultValue: '',
  );

  static const stadiaApiKey = String.fromEnvironment(
    'STADIA_API_KEY',
    defaultValue: '',
  );

  /// Path to Valhalla extract dir or `offline_graph.json` (empty = bundled sample).
  static const offlineTilesPath = String.fromEnvironment(
    'OFFLINE_TILES_PATH',
    defaultValue: '',
  );

  /// Prefer FFI offline routing before HTTP `/api/route`.
  static const preferOfflineRouting = bool.fromEnvironment(
    'PREFER_OFFLINE_ROUTING',
    defaultValue: false,
  );

  static const outdooractiveApiKey = String.fromEnvironment(
    'OUTDOORACTIVE_API_KEY',
    defaultValue: '',
  );

  static const outdooractiveProjectKey = String.fromEnvironment(
    'OUTDOORACTIVE_PROJECT_KEY',
    defaultValue: '',
  );

  /// Off-Route → automatischer Rejoin (Cooldown). Default aus (manueller Button bleibt).
  static const autoReroute = bool.fromEnvironment(
    'AETHER_AUTO_REROUTE',
    defaultValue: false,
  );

  /// Mindestabstand zwischen Auto-Reroutes (Sekunden).
  static const autoRerouteCooldownSec = int.fromEnvironment(
    'AETHER_AUTO_REROUTE_COOLDOWN_SEC',
    defaultValue: 45,
  );

  /// OAuth Deep-Link zurück in die App (Android/iOS Intent + Supabase Redirect URLs).
  static const oauthRedirectUrl = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'io.aetherride.app://login-callback/',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Sync Style-URL: compile-time PMTiles-Style → Stadia → OpenFreeMap.
  /// Kein demotiles als Produkt-Default.
  static String get mapStyleUrl {
    final pm = pmtilesUrl.trim();
    if (pm.isNotEmpty &&
        (pm.endsWith('.json') ||
            pm.contains('/styles/') ||
            pm.contains('style.json'))) {
      return pm;
    }
    if (stadiaApiKey.isNotEmpty) {
      return 'https://tiles.stadiamaps.com/styles/outdoors.json'
          '?api_key=$stadiaApiKey';
    }
    return 'https://tiles.openfreemap.org/styles/liberty';
  }

  /// Runtime: Prefs-Override (Style-JSON-URL) vor compile-time Defaults.
  static Future<String> resolveMapStyleUrl() async {
    try {
      final m = await OfflineMapsPrefs.read();
      final override = (m['pmtilesUrl'] as String?)?.trim() ?? '';
      if (override.isNotEmpty &&
          (override.endsWith('.json') ||
              override.contains('/styles/') ||
              override.contains('style.json'))) {
        return override;
      }
    } catch (_) {}
    return mapStyleUrl;
  }

  static bool get usingFreeBasemap =>
      stadiaApiKey.isEmpty &&
      pmtilesUrl.trim().isEmpty;
}
