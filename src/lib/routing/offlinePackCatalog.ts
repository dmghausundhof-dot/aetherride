/**
 * Catalog types, CDN URLs, merge/parse — no Node fs.
 * Client/marketing pages must import from here, not offlinePacks.ts.
 *
 * Valhalla tile region for a map point: use `valhallaRegionForPoint` /
 * `publicValhallaTilesUrlForPoint` from `./valhallaRegions` (wired below) —
 * do not hardcode pack ids like schwarzwald-nord.
 */
import {
  valhallaRegionForPoint,
  valhallaTilesCdnPath,
} from "./valhallaRegions";

export type OfflinePackManifest = {
  id: string;
  name: string;
  bbox?: number[];
  builtAt?: string;
  engines?: {
    offline_graph?: boolean;
    valhalla_tiles?: boolean;
    bike_overlay?: boolean;
  };
  files?: Record<
    string,
    { bytes?: number; sha256?: string; sha256_16?: string; file_count?: number }
  >;
  cdn?: { baseUrl?: string; pack?: string; packGz?: string };
  overlay?: {
    layer?: string;
    pmtiles?: string | null;
    geojson?: string | null;
    sourceLayer?: string;
    property?: string;
  };
  shipped?: { note?: string };
};

export type OfflinePackStatus = "ready" | "stub";

export type OfflineCatalogPack = {
  id: string;
  name: string;
  bbox: number[] | null;
  builtAt: string | null;
  engines: OfflinePackManifest["engines"] | null;
  hasManifest: boolean;
  downloadable: boolean;
  status: OfflinePackStatus;
  bytes: number | null;
  cdn: OfflinePackManifest["cdn"] | null;
};

const SAFE_ID = /^[a-zA-Z0-9_-]+$/;

export function safePackId(id: string): string {
  return id.replace(/[^a-zA-Z0-9_-]/g, "");
}

export function isSafePackId(id: string): boolean {
  return SAFE_ID.test(id);
}

/** True when the manifest lists a real artifact (hash and/or bytes), not a catalog stub. */
export function manifestHasFileEntries(
  m: OfflinePackManifest | null | undefined
): boolean {
  if (!m?.files) return false;
  return Object.entries(m.files).some(([name, meta]) => {
    if (!meta || name.endsWith("/")) return false;
    if (typeof meta.sha256 === "string" && meta.sha256.length >= 16) return true;
    if (typeof meta.bytes === "number" && meta.bytes > 1024) return true;
    return false;
  });
}

/**
 * Dist build output wins over a stale public copy; empty catalog stubs last.
 */
export function pickPreferredManifest(opts: {
  dist: OfflinePackManifest | null;
  pub: OfflinePackManifest | null;
  stub: OfflinePackManifest | null;
}): OfflinePackManifest | null {
  const { dist, pub, stub } = opts;
  if (manifestHasFileEntries(dist)) return dist;
  if (manifestHasFileEntries(pub)) return pub;
  return dist ?? pub ?? stub;
}

export function catalogPackBytes(m: OfflinePackManifest): number | null {
  const files = m.files ?? {};
  const gzKey = Object.keys(files).find(
    (k) => k.endsWith(".tar.gz") || k.endsWith(".tgz")
  );
  if (gzKey && typeof files[gzKey]?.bytes === "number") {
    return files[gzKey]!.bytes!;
  }
  const graph = files["offline_graph.json"];
  if (typeof graph?.bytes === "number") return graph.bytes;
  return null;
}

const PACK_CDN_BUCKET = "offline-packs";

/** Public Storage root — not a secret. Fallback when Vercel env is missing. */
export const DEFAULT_PACK_CDN_ROOT =
  "https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs";

function looksLikeStorageRoot(url: string): boolean {
  return url.includes("/storage/v1/object/public/");
}

/** Object-storage root for packs (`…/object/public/offline-packs`). */
export function packCdnRoot(): string {
  const explicit = (process.env.ROUTING_CDN_BASE || "").replace(/\/$/, "");
  if (explicit) {
    if (looksLikeStorageRoot(explicit)) return explicit.replace(/\/$/, "");
    if (/supabase\.co$/i.test(explicit)) {
      return `${explicit}/storage/v1/object/public/${PACK_CDN_BUCKET}`;
    }
    // App URL or stray /api/offline/packs suffix is not a pack object root.
    if (
      explicit.includes("/api/offline/packs") ||
      explicit.includes("vercel.app")
    ) {
      return DEFAULT_PACK_CDN_ROOT;
    }
    return explicit;
  }
  const supabase = (
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.SUPABASE_URL ||
    ""
  ).replace(/\/$/, "");
  if (supabase && !supabase.includes("vercel.app")) {
    return `${supabase}/storage/v1/object/public/${PACK_CDN_BUCKET}`;
  }
  return DEFAULT_PACK_CDN_ROOT;
}

/** Public object URL for a pack file when Vercel has no local artifact. */
export function publicOfflinePackObjectUrl(
  id: string,
  file: string
): string | null {
  const root = packCdnRoot();
  const safeId = safePackId(id);
  const safeFile = file.replace(/\.\./g, "").replace(/^\/+/, "").split("/").pop();
  if (!root || !SAFE_ID.test(safeId) || !safeFile) return null;
  return `${root}/${safeId}/${safeFile}`;
}

/** CDN object URL for `valhalla_tiles.tar` of a known region id. */
export function publicValhallaTilesObjectUrl(regionId: string): string | null {
  return publicOfflinePackObjectUrl(regionId, valhallaTilesCdnPath(regionId));
}

/**
 * Resolve Valhalla tile CDN URL for a map point (Discover / offline pack API).
 * No separate web tile picker yet — call sites use this instead of hardcoding.
 */
export function publicValhallaTilesUrlForPoint(
  lng: number,
  lat: number
): string | null {
  const region = valhallaRegionForPoint(lng, lat);
  if (!region) return null;
  return publicValhallaTilesObjectUrl(region.id);
}

export function applyPackCdn(
  id: string,
  m: OfflinePackManifest
): OfflinePackManifest {
  const root = packCdnRoot();
  const existing = (m.cdn?.baseUrl || "").trim();
  const existingIsApi =
    !existing ||
    existing.includes("/api/offline/packs") ||
    existing.includes("/offline/");
  if (!existingIsApi) return m;
  if (!root) return m;
  return {
    ...m,
    cdn: {
      ...(m.cdn || {}),
      baseUrl: `${root}/${id}`,
      packGz: m.cdn?.packGz || `${id}.tar.gz`,
      pack: m.cdn?.pack || `${id}.tar.gz`,
    },
  };
}

function isReadyCatalogRow(p: OfflineCatalogPack): boolean {
  return p.downloadable === true || p.status === "ready";
}

/** Merge Storage catalog.json over local stubs (production has no dist/). */
export function mergeCatalogPreferReady(
  local: OfflineCatalogPack[],
  published: OfflineCatalogPack[] | null | undefined
): OfflineCatalogPack[] {
  if (!published?.length) return local;
  const byId = new Map(local.map((p) => [p.id, p]));
  for (const p of published) {
    if (!p?.id || !SAFE_ID.test(p.id)) continue;
    const existing = byId.get(p.id);
    if (!existing || isReadyCatalogRow(p)) {
      byId.set(p.id, p);
    }
  }
  return [...byId.values()];
}

export function parsePublishedCatalog(raw: unknown): OfflineCatalogPack[] {
  if (!raw || typeof raw !== "object") return [];
  const packs = (raw as { packs?: unknown }).packs;
  if (!Array.isArray(packs)) return [];
  const out: OfflineCatalogPack[] = [];
  for (const row of packs) {
    if (!row || typeof row !== "object") continue;
    const p = row as Record<string, unknown>;
    const id = typeof p.id === "string" ? p.id : "";
    if (!SAFE_ID.test(id)) continue;
    const status: OfflinePackStatus =
      p.status === "ready" || p.downloadable === true ? "ready" : "stub";
    out.push({
      id,
      name: typeof p.name === "string" && p.name ? p.name : id,
      bbox: Array.isArray(p.bbox)
        ? p.bbox.filter((n): n is number => typeof n === "number").slice(0, 4)
        : null,
      builtAt: typeof p.builtAt === "string" ? p.builtAt : null,
      engines: (p.engines as OfflinePackManifest["engines"]) ?? null,
      hasManifest: p.hasManifest !== false,
      downloadable: status === "ready",
      status,
      bytes: typeof p.bytes === "number" ? p.bytes : null,
      cdn: (p.cdn as OfflinePackManifest["cdn"]) ?? null,
    });
  }
  return out;
}

/** Public Storage catalog — source of truth when Vercel has no dist artifacts. */
export async function fetchPublishedCatalog(): Promise<OfflineCatalogPack[] | null> {
  const root = packCdnRoot();
  if (!root) return null;
  try {
    const res = await fetch(`${root}/catalog.json`, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(8000),
      cache: "no-store",
    });
    if (!res.ok) return null;
    const packs = parsePublishedCatalog(await res.json());
    return packs.some(isReadyCatalogRow) ? packs : null;
  } catch {
    return null;
  }
}

export async function fetchPublishedManifest(
  id: string
): Promise<OfflinePackManifest | null> {
  const root = packCdnRoot();
  const idSafe = safePackId(id);
  if (!root || !SAFE_ID.test(idSafe)) return null;
  try {
    const res = await fetch(`${root}/${idSafe}/manifest.json`, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(8000),
      cache: "no-store",
    });
    if (!res.ok) return null;
    const m = (await res.json()) as OfflinePackManifest;
    if (!m || typeof m !== "object") return null;
    return applyPackCdn(idSafe, { ...m, id: m.id || idSafe });
  } catch {
    return null;
  }
}

export function catalogStatus(
  m: OfflinePackManifest | null,
  onDisk: boolean
): OfflinePackStatus {
  if (!m) return "stub";
  const cdn = (m.cdn?.baseUrl || "").trim();
  const cdnReady = looksLikeStorageRoot(cdn);
  if (onDisk || cdnReady) return "ready";
  if (m.shipped && !manifestHasFileEntries(m)) return "stub";
  if (!manifestHasFileEntries(m)) return "stub";
  return "stub";
}

export function sortCatalogPacks(
  packs: OfflineCatalogPack[]
): OfflineCatalogPack[] {
  return [...packs].sort((a, b) => {
    if (a.downloadable !== b.downloadable) return a.downloadable ? -1 : 1;
    return a.name.localeCompare(b.name, "de");
  });
}

export function summarizeOfflinePacks(packs: OfflineCatalogPack[]): {
  ready: number;
  stub: number;
  total: number;
} {
  let ready = 0;
  let stub = 0;
  for (const p of packs) {
    if (p.downloadable || p.status === "ready") ready += 1;
    else stub += 1;
  }
  return { ready, stub, total: packs.length };
}
