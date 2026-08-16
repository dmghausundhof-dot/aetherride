import 'package:flutter/foundation.dart';
import '../data/routing/map_style_url.dart';
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

  /// Compile-time override. Empty → production host (Debug und Release).
  static const _apiBaseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Production Next.js origin — Default für alle Builds ohne Override.
  static const productionApiBaseUrl = 'https://aetherride.vercel.app';

  /// Android-Emulator → Host-Loopback für lokale Next.js-Entwicklung.
  /// Bewusst KEIN Debug-Default: auf physischen Geräten ist 10.0.2.2 nicht
  /// erreichbar (Katalog/Routen/Touren liefen dort in Timeouts). Für den
  /// Emulator explizit `--dart-define=API_BASE_URL=http://10.0.2.2:3001`
  /// setzen (siehe mobile/README.md „Start").
  static const emulatorApiBaseUrl = 'http://10.0.2.2:3001';

  /// Next.js API origin for sync / route / catalog.
  static String get apiBaseUrl {
    final fromEnv = _apiBaseUrlDefine.trim();
    if (fromEnv.isNotEmpty) return fromEnv;
    return productionApiBaseUrl;
  }

  /// Public DACH MapLibre style (JSON with pmtiles:// source). Not a secret.
  static const dachBasemapStyleUrl =
      'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/dach-z11-style.json';

  static const franceWestBasemapStyleUrl =
      'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/basemap/france-west-z11-style.json';

  static String get offlinePacksCdnRoot {
    final base = supabaseUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      return 'https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs';
    }
    return '$base/storage/v1/object/public/offline-packs';
  }

  /// Compile-time override. Empty or overview-only (DACH z11) is ignored
  /// for the live map — [mapStyleUrl] then uses Stadia / Liberty.
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

  /// Öffentliche Shopify-Storefront (Custom Tabs). Kein Secret.
  /// Override: `--dart-define=SHOPIFY_STOREFRONT_URL=https://…`
  static const shopifyStorefrontUrl = String.fromEnvironment(
    'SHOPIFY_STOREFRONT_URL',
    defaultValue: 'https://dmg-haus-und-hof-shop.myshopify.com',
  );

  static const shopifyPartsCollection = String.fromEnvironment(
    'SHOPIFY_PARTS_COLLECTION',
    defaultValue: 'featured-parts',
  );

  static const shopifyMerchCollection = String.fromEnvironment(
    'SHOPIFY_MERCH_COLLECTION',
    defaultValue: 'merchandise',
  );

  /// Online Store password wall. Default true until the shop is public.
  /// `--dart-define=SHOPIFY_ONLINE_STORE_LOCKED=false` after Admin unlock.
  static const shopifyOnlineStoreLocked = bool.fromEnvironment(
    'SHOPIFY_ONLINE_STORE_LOCKED',
    defaultValue: true,
  );

  /// Legal pages on the API/web origin.
  static String get privacyPolicyUrl => '$apiBaseUrl/legal/datenschutz';
  static String get impressumUrl => '$apiBaseUrl/legal/impressum';
  static String get widerrufUrl => '$apiBaseUrl/legal/widerruf';

  /// Live street map: dart-define street style → Stadia OSM Bright →
  /// OpenFreeMap Bright. DACH/FR z11 PMTiles is offline-only (no streets
  /// at HUD zoom). Outdoors/Liberty hide residential as white-on-beige.
  /// Native MapLibre braucht Style-JSON, kein rohes `.pmtiles`.
  static String get mapStyleUrl => liveMapStyleUrl(
        pmtilesOrStyleUrl: pmtilesUrl,
        stadiaApiKey: stadiaApiKey,
      );

  /// Prefs may point at a custom street-level style. Overview packs (CDN or
  /// local `dach-z11-style.json`) stay offline-only and do not replace this.
  static Future<String> resolveMapStyleUrl() async {
    try {
      final m = await OfflineMapsPrefs.read();
      final override = (m['pmtilesUrl'] as String?)?.trim() ?? '';
      if (override.isNotEmpty && isStreetLevelBasemap(override)) {
        return override;
      }
    } catch (_) {}
    return mapStyleUrl;
  }

  static bool get usingFreeBasemap => mapStyleUrl.contains('openfreemap.org');

  /// Public catalog of built region packs (Supabase Storage).
  static String get offlinePacksCatalogCdnUrl =>
      '$offlinePacksCdnRoot/catalog.json';

  static String offlinePackObjectUrl(String regionId, String file) =>
      '$offlinePacksCdnRoot/$regionId/$file';
}
