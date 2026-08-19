/**
 * Collection-Share ohne Backend: Payload in URL (base64url).
 * Sammlung: nur Metadaten + Tour-IDs — keine Tracks/GPS.
 * Einzel-Tour: Track nur wenn includeTrack (opt-in, ehrlich).
 */

import type { SharedCollectionPayload } from "@/lib/community/types";
import type { SharedTourPayload } from "@/lib/community/shareTypes";
import type { SavedRoute } from "@/types/route";
import { getPublicTour } from "@/lib/catalog/publicTours";

export const SHARE_DEMO_TOKEN = "demo";

export function isShareDemoToken(token: string): boolean {
  return token.trim().toLowerCase() === SHARE_DEMO_TOKEN;
}

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
  return Buffer.from(full, "utf8").toString("utf8");
}

export function encodeSharePayload(payload: SharedCollectionPayload): string {
  return toBase64Url(JSON.stringify(payload));
}

export function decodeSharePayload(
  token: string,
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

export function shareTourPath(token: string): string {
  return `/share/t/${token}`;
}

const MAX_TRACK_POINTS = 80;
const MAX_TOKEN_CHARS = 1800;

function downsampleTrack(
  coords: [number, number][],
  max = MAX_TRACK_POINTS,
): [number, number][] {
  if (coords.length <= max) return coords;
  const step = (coords.length - 1) / (max - 1);
  const out: [number, number][] = [];
  for (let i = 0; i < max; i++) {
    const p = coords[Math.round(i * step)];
    if (p) out.push([Number(p[0]), Number(p[1])]);
  }
  return out;
}

function catalogTourIdOf(route: Pick<SavedRoute, "id"> & { catalogTourId?: string }): string | undefined {
  const explicit = route.catalogTourId?.trim();
  if (explicit && getPublicTour(explicit)) return explicit;
  if (getPublicTour(route.id)) return route.id;
  return undefined;
}

export function encodeTourSharePayload(payload: SharedTourPayload): string {
  return toBase64Url(JSON.stringify(payload));
}

export function parseTourShareMap(raw: unknown): SharedTourPayload | null {
  if (!raw || typeof raw !== "object") return null;
  const data = raw as SharedTourPayload;
  if (data.v !== 1 || data.kind !== "tour" || !data.id || !data.name) {
    return null;
  }
  return data;
}

export function decodeTourSharePayload(token: string): SharedTourPayload | null {
  try {
    return parseTourShareMap(JSON.parse(fromBase64Url(token)));
  } catch {
    return null;
  }
}

/** Mitglieds-Kopie. keepId bleibt die Host-Id — Losfahren matcht. */
export function savedRouteFromTourShare(
  tour: SharedTourPayload,
  keepId: string
): SavedRoute | null {
  if (!parseTourShareMap(tour)) return null;
  const track = (tour.track ?? []).filter(
    (p): p is [number, number] =>
      Array.isArray(p) &&
      p.length >= 2 &&
      Number.isFinite(p[0]) &&
      Number.isFinite(p[1])
  );
  if (track.length < 2) return null;
  const name = String(tour.name || "").trim();
  return {
    id: keepId,
    name: name || keepId,
    distanceKm: Number(tour.distanceKm) || 0,
    elevationM: Number(tour.elevationM) || 0,
    durationMin: Math.round(Number(tour.durationMin) || 0),
    savedAt: new Date().toISOString(),
    source: tour.source === "engine" ? "engine" : "import",
    geometry: { type: "LineString", coordinates: track },
    waypoints: [
      { role: "start", lngLat: track[0] },
      { role: "end", lngLat: track[track.length - 1] },
    ],
  };
}

/** Baut den Share-Payload. Track nur bei eigener Geometrie, gedownsampled. */
export function buildTourSharePayload(
  route: SavedRoute,
  authorLabel = "FlowLine-Fahrer:in",
): SharedTourPayload {
  const coords = (route.geometry?.coordinates ?? []) as [number, number][];
  const usable = coords.filter(
    (p) =>
      Array.isArray(p) &&
      p.length >= 2 &&
      Number.isFinite(p[0]) &&
      Number.isFinite(p[1]),
  ) as [number, number][];
  const catalog = catalogTourIdOf(route);
  const includeTrack = usable.length >= 2;
  return {
    v: 1,
    kind: "tour",
    id: route.id,
    name: route.name,
    distanceKm: route.distanceKm,
    elevationM: route.elevationM,
    durationMin: route.durationMin,
    source: route.source,
    catalogTourId: catalog,
    includeTrack,
    track: includeTrack ? downsampleTrack(usable) : undefined,
    authorLabel,
    createdAt: new Date().toISOString(),
  };
}

export function encodeTourShareToken(
  route: SavedRoute,
  authorLabel?: string,
): {
  token: string;
  includeTrack: boolean;
  droppedTrack: boolean;
} {
  const full = buildTourSharePayload(route, authorLabel);
  let token = encodeTourSharePayload(full);
  if (token.length <= MAX_TOKEN_CHARS) {
    return { token, includeTrack: full.includeTrack, droppedTrack: false };
  }
  const slim: SharedTourPayload = {
    ...full,
    includeTrack: false,
    track: undefined,
  };
  token = encodeTourSharePayload(slim);
  return { token, includeTrack: false, droppedTrack: full.includeTrack };
}

const DEMO_COLLECTION_IDS = [
  "r-hamburg-alster",
  "r-heidelberg-city",
  "r-bodensee-road",
] as const;

export function demoCollectionPayload(): SharedCollectionPayload {
  return {
    v: 1,
    name: "Beispiel-Mappe · FlowLine",
    routeIds: [...DEMO_COLLECTION_IDS],
    routeNames: DEMO_COLLECTION_IDS.map(
      (id) => getPublicTour(id)?.name ?? id,
    ),
    authorLabel: "FlowLine Editorial",
    createdAt: "2026-08-15T00:00:00.000Z",
  };
}

export function demoTourPayload(): SharedTourPayload {
  const t = getPublicTour("r-hamburg-alster");
  return {
    v: 1,
    kind: "tour",
    id: t?.id ?? "r-hamburg-alster",
    name: t?.name ?? "Hamburg Alster-Runde",
    distanceKm: t?.distanceKm ?? 18,
    elevationM: t?.elevationM ?? 35,
    durationMin: t?.durationMin ?? 55,
    source: "suggestion",
    catalogTourId: t?.id ?? "r-hamburg-alster",
    includeTrack: false,
    authorLabel: "FlowLine Editorial",
    createdAt: "2026-08-15T00:00:00.000Z",
  };
}
