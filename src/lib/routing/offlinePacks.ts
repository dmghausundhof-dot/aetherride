import { readFile, access, readdir } from "fs/promises";
import path from "path";
import { constants } from "fs";

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

const ROOT = process.cwd();
const SAFE_ID = /^[a-zA-Z0-9_-]+$/;

function safePackId(id: string): string {
  return id.replace(/[^a-zA-Z0-9_-]/g, "");
}

/**
 * Dist (build output) before public/. Stale public/offline copies of
 * manifest.json used to win and fail SHA checks against the real tarball.
 */
function candidates(id: string, file?: string): string[] {
  const safeId = safePackId(id);
  const safeFile = file
    ? file.replace(/\.\./g, "").replace(/^\/+/, "")
    : "manifest.json";
  const paths = [
    path.join(ROOT, "data", "routing", "dist", safeId, safeFile),
    path.join(ROOT, "public", "offline", safeId, safeFile),
  ];
  if (safeFile === "manifest.json") {
    paths.push(path.join(ROOT, "data", "routing", "manifests", `${safeId}.json`));
  }
  return paths;
}

async function firstExisting(paths: string[]): Promise<string | null> {
  for (const p of paths) {
    try {
      await access(p, constants.R_OK);
      return p;
    } catch {
      /* try next */
    }
  }
  return null;
}

async function readJsonIfExists(
  p: string
): Promise<OfflinePackManifest | null> {
  try {
    await access(p, constants.R_OK);
    const raw = await readFile(/* turbopackIgnore: true */ p, "utf8");
    return JSON.parse(raw) as OfflinePackManifest;
  } catch {
    return null;
  }
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
  const safeId = safePackId(id);
  if (!root || !SAFE_ID.test(safeId)) return null;
  try {
    const res = await fetch(`${root}/${safeId}/manifest.json`, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(8000),
      cache: "no-store",
    });
    if (!res.ok) return null;
    const m = (await res.json()) as OfflinePackManifest;
    if (!m || typeof m !== "object") return null;
    return applyPackCdn(safeId, { ...m, id: m.id || safeId });
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

export async function packArtifactExists(
  id: string,
  m: OfflinePackManifest
): Promise<boolean> {
  const files = m.files ?? {};
  const names = Object.keys(files).filter(
    (n) =>
      n.endsWith(".tar.gz") ||
      n.endsWith(".tgz") ||
      n === "offline_graph.json" ||
      n === "valhalla_tiles.tar"
  );
  for (const n of names) {
    if (await firstExisting(candidates(id, n))) return true;
  }
  return false;
}

export async function toCatalogRow(
  id: string,
  m: OfflinePackManifest | null
): Promise<OfflineCatalogPack> {
  const withCdn = m ? applyPackCdn(id, m) : null;
  const onDisk = withCdn ? await packArtifactExists(id, withCdn) : false;
  const status = catalogStatus(withCdn, onDisk);
  return {
    id,
    name: withCdn?.name ?? id,
    bbox: withCdn?.bbox ?? null,
    builtAt: withCdn?.builtAt ?? null,
    engines: withCdn?.engines ?? null,
    hasManifest: Boolean(withCdn),
    downloadable: status === "ready",
    status,
    bytes: withCdn ? catalogPackBytes(withCdn) : null,
    cdn: withCdn?.cdn ?? null,
  };
}

export function sortCatalogPacks(
  packs: OfflineCatalogPack[]
): OfflineCatalogPack[] {
  return [...packs].sort((a, b) => {
    if (a.downloadable !== b.downloadable) return a.downloadable ? -1 : 1;
    return a.name.localeCompare(b.name, "de");
  });
}

export async function readOfflineManifest(
  id: string
): Promise<OfflinePackManifest | null> {
  const safeId = safePackId(id);
  if (!SAFE_ID.test(safeId)) return null;
  const dist = await readJsonIfExists(
    path.join(ROOT, "data", "routing", "dist", safeId, "manifest.json")
  );
  const pub = await readJsonIfExists(
    path.join(ROOT, "public", "offline", safeId, "manifest.json")
  );
  const stub = await readJsonIfExists(
    path.join(ROOT, "data", "routing", "manifests", `${safeId}.json`)
  );
  return pickPreferredManifest({ dist, pub, stub });
}

export async function readOfflinePackFile(
  id: string,
  file: string
): Promise<{ bytes: Buffer; contentType: string } | null> {
  const p = await firstExisting(candidates(id, file));
  if (!p) return null;
  const bytes = await readFile(/* turbopackIgnore: true */ p);
  const lower = file.toLowerCase();
  let contentType = "application/octet-stream";
  if (lower.endsWith(".json") || lower.endsWith(".geojson"))
    contentType = "application/json";
  else if (lower.endsWith(".pmtiles")) contentType = "application/vnd.pmtiles";
  else if (lower.endsWith(".tar.gz") || lower.endsWith(".tgz"))
    contentType = "application/gzip";
  else if (lower.endsWith(".tar.zst")) contentType = "application/zstd";
  return { bytes, contentType };
}

async function dirNames(dir: string): Promise<string[]> {
  try {
    const entries = await readdir(dir, { withFileTypes: true });
    return entries
      .filter((e) => e.isDirectory() && SAFE_ID.test(e.name))
      .map((e) => e.name);
  } catch {
    return [];
  }
}

async function manifestBasenames(dir: string): Promise<string[]> {
  try {
    const entries = await readdir(dir);
    return entries
      .filter((n) => n.endsWith(".json"))
      .map((n) => n.replace(/\.json$/i, ""))
      .filter((id) => SAFE_ID.test(id));
  } catch {
    return [];
  }
}

/**
 * Scans dist, public/offline and manifests/. Dist is preferred for artifacts
 * (local/dev); serverless deploys typically only have catalog stubs.
 */
export async function listKnownPackIds(): Promise<string[]> {
  const skip = new Set(["valhalla-build", "_geofabrik"]);
  const found = new Set<string>();
  for (const id of await dirNames(path.join(ROOT, "data", "routing", "dist"))) {
    if (!skip.has(id)) found.add(id);
  }
  for (const id of await dirNames(path.join(ROOT, "public", "offline"))) {
    if (!skip.has(id)) found.add(id);
  }
  for (const id of await manifestBasenames(
    path.join(ROOT, "data", "routing", "manifests")
  )) {
    if (!skip.has(id)) found.add(id);
  }
  const ids: string[] = [];
  for (const id of found) {
    const m = await readOfflineManifest(id);
    if (m) ids.push(id);
  }
  return ids.sort();
}
