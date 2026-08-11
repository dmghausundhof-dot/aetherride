/**
 * Store-Links und Deep-Link-Hinweise für Web → native App.
 * Env optional: NEXT_PUBLIC_APP_STORE_URL, NEXT_PUBLIC_PLAY_STORE_URL
 */

export const APP_STORE_URL =
  process.env.NEXT_PUBLIC_APP_STORE_URL?.trim() || "#";

export const PLAY_STORE_URL =
  process.env.NEXT_PUBLIC_PLAY_STORE_URL?.trim() || "#";

/** Universeller Intent-Hinweis (Placeholder bis Universal Links live) */
export const APP_SCHEME = "aetherride";

export function appDeepLink(path: string): string {
  const clean = path.startsWith("/") ? path.slice(1) : path;
  return `${APP_SCHEME}://${clean}`;
}

export function hasStoreLinks(): boolean {
  return APP_STORE_URL !== "#" || PLAY_STORE_URL !== "#";
}
