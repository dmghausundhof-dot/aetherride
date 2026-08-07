import { readFile, access } from "fs/promises";
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
    // manifests/schwarzwald-nord.json
    const alt = await firstExisting([
      path.join(ROOT, "data", "routing", "manifests", `${id.replace(/[^a-zA-Z0-9_-]/g, "")}.json`),
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

export function listKnownPackIds(): string[] {
  // Demo catalog — extend when more region configs ship.
  return ["schwarzwald-nord"];
}
