/**
 * Collection-Share ohne Backend: Payload in URL (base64url).
 * Nur Metadaten + Tour-IDs — keine Tracks/GPS.
 */

import type { SharedCollectionPayload } from "@/lib/community/types";

function toBase64Url(json: string): string {
  if (typeof btoa === "function") {
    const b64 = btoa(unescape(encodeURIComponent(json)));
    return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }
  return Buffer.from(json, "utf8")
    .toString("base64")
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

function fromBase64Url(token: string): string {
  const b64 = token.replace(/-/g, "+").replace(/_/g, "/");
  const pad = b64.length % 4 === 0 ? "" : "=".repeat(4 - (b64.length % 4));
  const full = b64 + pad;
  if (typeof atob === "function") {
    return decodeURIComponent(escape(atob(full)));
  }
  return Buffer.from(full, "base64").toString("utf8");
}

export function encodeSharePayload(payload: SharedCollectionPayload): string {
  return toBase64Url(JSON.stringify(payload));
}

export function decodeSharePayload(
  token: string
): SharedCollectionPayload | null {
  try {
    const raw = fromBase64Url(token);
    const data = JSON.parse(raw) as SharedCollectionPayload;
    if (data?.v !== 1 || !data.name || !Array.isArray(data.routeIds)) {
      return null;
    }
    return data;
  } catch {
    return null;
  }
}

export function shareCollectionPath(token: string): string {
  return `/share/c/${token}`;
}
