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
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const pmtilesUrl = String.fromEnvironment(
    'PMTILES_URL',
    defaultValue: '',
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
}
