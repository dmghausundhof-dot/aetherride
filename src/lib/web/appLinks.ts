/**
 * Store-Links und Deep Links (Custom Scheme + Universal / App Links).
 *
 * Env (Vercel):
 * - NEXT_PUBLIC_APP_STORE_URL
 * - NEXT_PUBLIC_PLAY_STORE_URL
 * - NEXT_PUBLIC_APP_URL / NEXT_PUBLIC_SITE_URL (https://…)
 * - NEXT_PUBLIC_IOS_TEAM_ID (Apple Team ID)
 * - NEXT_PUBLIC_IOS_BUNDLE_ID (default io.aetherride.app)
 * - NEXT_PUBLIC_ANDROID_PACKAGE (default com.aetherride.aetherride_mobile)
 * - NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS (comma-separated SHA-256)
 */

export const APP_STORE_URL =
  process.env.NEXT_PUBLIC_APP_STORE_URL?.trim() || "#";

export const PLAY_STORE_URL =
  process.env.NEXT_PUBLIC_PLAY_STORE_URL?.trim() || "#";

/** Custom scheme — muss mit Android/iOS Intent/URL Types matchen */
export const APP_SCHEME = "aetherride";

/** Legacy / OAuth scheme der Mobile-App */
export const APP_SCHEME_LEGACY = "io.aetherride.app";

export const ANDROID_PACKAGE =
  process.env.NEXT_PUBLIC_ANDROID_PACKAGE?.trim() ||
  "com.aetherride.aetherride_mobile";

export const IOS_BUNDLE_ID =
  process.env.NEXT_PUBLIC_IOS_BUNDLE_ID?.trim() || "io.aetherride.app";

export const IOS_TEAM_ID = process.env.NEXT_PUBLIC_IOS_TEAM_ID?.trim() || "";

export function siteOrigin(): string {
  const raw =
    process.env.NEXT_PUBLIC_APP_URL?.trim() ||
    process.env.NEXT_PUBLIC_SITE_URL?.trim() ||
    "";
  return raw.replace(/\/$/, "");
}

export function appDeepLink(path: string): string {
  const clean = path.startsWith("/") ? path.slice(1) : path;
  return `${APP_SCHEME}://${clean}`;
}

/** HTTPS Universal Link / App Link (wenn Domain verifiziert) */
export function httpsAppLink(path: string): string {
  const origin = siteOrigin();
  const clean = path.startsWith("/") ? path : `/${path}`;
  if (!origin) return appDeepLink(path);
  return `${origin}/open${clean.startsWith("/") ? clean : `/${clean}`}`;
}

export function hasStoreLinks(): boolean {
  return APP_STORE_URL !== "#" || PLAY_STORE_URL !== "#";
}

/**
 * Primary „App entdecken“ target for marketing surfaces.
 * Store URLs when configured (platform-aware); else documented web entry `/download`.
 * Never returns a placeholder hash.
 */
export function appDiscoverHref(userAgent?: string): string {
  const hasApp = APP_STORE_URL !== "#";
  const hasPlay = PLAY_STORE_URL !== "#";
  if (!hasApp && !hasPlay) return "/download";

  const ua = (userAgent ?? "").toLowerCase();
  const isIos = /iphone|ipad|ipod/.test(ua);
  const isAndroid = /android/.test(ua);

  if (isIos && hasApp) return APP_STORE_URL;
  if (isAndroid && hasPlay) return PLAY_STORE_URL;
  if (hasPlay) return PLAY_STORE_URL;
  return APP_STORE_URL;
}

/** True when the discover href is an external store URL. */
export function isExternalAppDiscoverHref(href: string): boolean {
  return href.startsWith("http://") || href.startsWith("https://");
}

export function androidSha256Fingerprints(): string[] {
  const raw =
    process.env.NEXT_PUBLIC_ANDROID_SHA256_FINGERPRINTS?.trim() ||
    process.env.ANDROID_SHA256_FINGERPRINTS?.trim() ||
    "";
  return raw
    .split(/[,;\s]+/)
    .map((s) => s.trim().toUpperCase().replace(/:/g, ""))
    .filter(Boolean)
    .map((hex) =>
      hex.includes(":")
        ? hex
        : hex.replace(/(.{2})(?=.)/g, "$1:")
    );
}

export function rideOpenPath(routeId?: string | null): string {
  if (routeId) return `ride?route=${encodeURIComponent(routeId)}`;
  return "ride";
}
