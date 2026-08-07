/// Compile-time / runtime config for mobile.
/// Pass via `--dart-define=SUPABASE_URL=...` etc.
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

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// MapLibre style URL: Stadia Outdoors if key set, else demo tiles.
  static String get mapStyleUrl {
    if (stadiaApiKey.isNotEmpty) {
      return 'https://tiles.stadiamaps.com/styles/outdoors.json'
          '?api_key=$stadiaApiKey';
    }
    return 'https://demotiles.maplibre.org/style.json';
  }
}
