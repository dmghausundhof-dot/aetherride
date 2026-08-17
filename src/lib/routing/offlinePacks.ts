/**
 * Local pack files (dist/, public/offline, manifests/).
 * Node fs — import only from API routes and Node scripts, never from
 * Client Components or marketing pages (those use offlinePackCatalog.ts).
 */
import { readFile, access, readdir } from "node:fs/promises";
import path from "node:path";
import { constants } from "node:fs";
import {
  applyPackCdn,
  catalogPackBytes,
  catalogStatus,
  fetchPublishedCatalog,
  isSafePackId,
  mergeCatalogPreferReady,
  pickPreferredManifest,
  safePackId,
  sortCatalogPacks,
  type OfflineCatalogPack,
  type OfflinePackManifest,
} from "./offlinePackCatalog";

export type {
  OfflineCatalogPack,
  OfflinePackManifest,
  OfflinePackStatus,
} from "./offlinePackCatalog";
export {
  DEFAULT_PACK_CDN_ROOT,
  applyPackCdn,
  catalogPackBytes,
  catalogStatus,
  fetchPublishedCatalog,
  fetchPublishedManifest,
  manifestHasFileEntries,
  mergeCatalogPreferReady,
  packCdnRoot,
  parsePublishedCatalog,
  pickPreferredManifest,
  publicOfflinePackObjectUrl,
  publicValhallaTilesObjectUrl,
  publicValhallaTilesUrlForPoint,
  sortCatalogPacks,
  summarizeOfflinePacks,
} from "./offlinePackCatalog";

const ROOT = process.cwd();

/**
 * Dist (build output) before public/. Stale public/offline copies of
 * manifest.json used to win and fail SHA checks against the real tarball.
 */
function candidates(id: string, file?: string): string[] {
  const idSafe = safePackId(id);
  const safeFile = file
    ? file.replace(/\.\./g, "").replace(/^\/+/, "")
    : "manifest.json";
  const paths = [
    path.join(ROOT, "data", "routing", "dist", idSafe, safeFile),
    path.join(ROOT, "public", "offline", idSafe, safeFile),
  ];
  if (safeFile === "manifest.json") {
    paths.push(path.join(ROOT, "data", "routing", "manifests", `${idSafe}.json`));
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
  // Status before applyPackCdn: synthesizing a Storage baseUrl must not turn
  // empty catalog stubs into downloadable "ready" rows.
  const onDisk = m ? await packArtifactExists(id, m) : false;
  const status = catalogStatus(m, onDisk);
  const withCdn = m ? applyPackCdn(id, m) : null;
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
    cdn: status === "ready" ? withCdn?.cdn ?? null : m?.cdn ?? null,
  };
}

export async function readOfflineManifest(
  id: string
): Promise<OfflinePackManifest | null> {
  const idSafe = safePackId(id);
  if (!isSafePackId(idSafe)) return null;
  const dist = await readJsonIfExists(
    path.join(ROOT, "data", "routing", "dist", idSafe, "manifest.json")
  );
  const pub = await readJsonIfExists(
    path.join(ROOT, "public", "offline", idSafe, "manifest.json")
  );
  const stub = await readJsonIfExists(
    path.join(ROOT, "data", "routing", "manifests", `${idSafe}.json`)
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
      .filter((e) => e.isDirectory() && isSafePackId(e.name))
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
      .filter((id) => isSafePackId(id));
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

export async function listMergedOfflineCatalog(): Promise<OfflineCatalogPack[]> {
  const ids = await listKnownPackIds();
  const local: OfflineCatalogPack[] = [];
  for (const id of ids) {
    const m = await readOfflineManifest(id);
    local.push(await toCatalogRow(id, m));
  }
  const published = await fetchPublishedCatalog();
  return sortCatalogPacks(mergeCatalogPreferReady(local, published));
}
