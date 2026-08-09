import { readFile, access, readdir } from "fs/promises";
import path from "path";
import { constants } from "fs";

export type OfflinePackManifest = {
  id: string;
  name: string;
  bbox?: number[];
  builtAt?: string;
  engines?: { offline_graph?: boolean; valhalla_tiles?: boolean };
  files?: Record<
    string,
    { bytes?: number; sha256?: string; sha256_16?: string; file_count?: number }
  >;
  cdn?: { baseUrl?: string; pack?: string; packGz?: string };
};

const ROOT = process.cwd();
const SAFE_ID = /^[a-zA-Z0-9_-]+$/;

function candidates(id: string, file?: string): string[] {
  const safeId = id.replace(/[^a-zA-Z0-9_-]/g, "");
  const safeFile = file
    ? file.replace(/\.\./g, "").replace(/^\/+/, "")
    : "manifest.json";
  return [
    path.join(ROOT, "public", "offline", safeId, safeFile),
    path.join(ROOT, "data", "routing", "dist", safeId, safeFile),
    path.join(ROOT, "data", "routing", "manifests", `${safeId}.json`),
  ];
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

export async function readOfflineManifest(
  id: string
): Promise<OfflinePackManifest | null> {
  const p = await firstExisting(candidates(id, "manifest.json"));
  if (!p) {
    const alt = await firstExisting([
      path.join(
        ROOT,
        "data",
        "routing",
        "manifests",
        `${id.replace(/[^a-zA-Z0-9_-]/g, "")}.json`
      ),
    ]);
    if (!alt) return null;
    const raw = await readFile(alt, "utf8");
    return JSON.parse(raw) as OfflinePackManifest;
  }
  const raw = await readFile(p, "utf8");
  return JSON.parse(raw) as OfflinePackManifest;
}

export async function readOfflinePackFile(
  id: string,
  file: string
): Promise<{ bytes: Buffer; contentType: string } | null> {
  const p = await firstExisting(candidates(id, file));
  if (!p) return null;
  const bytes = await readFile(p);
  const lower = file.toLowerCase();
  let contentType = "application/octet-stream";
  if (lower.endsWith(".json")) contentType = "application/json";
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
 * Scans public/offline, data/routing/dist and manifests/.
 * Only IDs with a readable manifest are listed (no empty 404 traps).
 */
export async function listKnownPackIds(): Promise<string[]> {
  const skip = new Set(["valhalla-build"]);
  const candidates = new Set<string>(["schwarzwald-nord"]);
  for (const id of await dirNames(path.join(ROOT, "public", "offline"))) {
    if (!skip.has(id)) candidates.add(id);
  }
  for (const id of await dirNames(path.join(ROOT, "data", "routing", "dist"))) {
    if (!skip.has(id)) candidates.add(id);
  }
  for (const id of await manifestBasenames(
    path.join(ROOT, "data", "routing", "manifests")
  )) {
    if (!skip.has(id)) candidates.add(id);
  }
  const ids: string[] = [];
  for (const id of candidates) {
    const m = await readOfflineManifest(id);
    if (m) ids.push(id);
  }
  return ids.sort();
}
