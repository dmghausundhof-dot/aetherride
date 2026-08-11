import 'package:flutter/foundation.dart';
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

  /// Compile-time override. Empty → debug emulator / release production host.
  static const _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Production Next.js origin (Play / TestFlight release builds).
  static const productionApiBaseUrl = 'https://aetherride.vercel.app';

  /// Emulator → host loopback when developing against local Next.js.
  static const debugApiBaseUrl = 'http://10.0.2.2:3001';

  /// Next.js API origin for sync / route / catalog.
  static String get apiBaseUrl {
    final fromEnv = _apiBaseUrlDefine.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kReleaseMode) return productionApiBaseUrl;
    return debugApiBaseUrl;
  }

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

  /// Show Demo-Geometrie / Routing-Key debug banners in Discover.
  /// Prod default off — set SHOW_ROUTING_DEBUG=true for local smoke.
  static const showRoutingDebug = bool.fromEnvironment(
    'SHOW_ROUTING_DEBUG',
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

  /// Off-Route → automatischer Rejoin. Default an (im Ride-HUD abschaltbar).
  static const autoReroute = bool.fromEnvironment(
    'AETHER_AUTO_REROUTE',
    defaultValue: true,
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

  /// Google OAuth button — default aus (Provider/SHA oft noch nicht fertig).
  static const enableGoogleOAuth = bool.fromEnvironment(
    'ENABLE_GOOGLE_OAUTH',
    defaultValue: false,
  );

  /// Apple OAuth button — default aus bis Provider/Entitlements stehen.
  static const enableAppleOAuth = bool.fromEnvironment(
    'ENABLE_APPLE_OAUTH',
    defaultValue: false,
  );

  /// Optional Sentry DSN — empty = crash reporting disabled.
  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Demo/seed UI is permanently off — market builds never show Freiburg seeds.
  static bool get allowDemoContent => false;

  /// Test-Account immer Pro.
  /// - Debug: standardmäßig an (`AETHER_FORCE_FREE=true` zum Abschalten)
  /// - Release: nur mit `--dart-define=AETHER_FORCE_PRO=true`
  static bool get forcePro {
    if (const bool.fromEnvironment('AETHER_FORCE_PRO', defaultValue: false)) {
      return true;
    }
    if (const bool.fromEnvironment('AETHER_FORCE_FREE', defaultValue: false)) {
      return false;
    }
    return kDebugMode;
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isCrashReportingConfigured => sentryDsn.trim().isNotEmpty;

  /// Legal pages on the API/web origin.
  static String get privacyPolicyUrl => '$apiBaseUrl/legal/datenschutz';
  static String get impressumUrl => '$apiBaseUrl/legal/impressum';
  static String get widerrufUrl => '$apiBaseUrl/legal/widerruf';

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
