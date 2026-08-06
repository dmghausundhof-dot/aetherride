/**
 * Offline-Regionen (F-NAV-002 / NFR-08)
 * Web-Demo: keine PMTiles — Meta-Warteschlange ehrlich.
 * Native Download erst nach G-0 (siehe pmtilesPrep.ts).
 */

import {
  OFFLINE_REGION_MANIFESTS,
  type OfflineRegionManifest,
} from "@/lib/platform/pmtilesPrep";

export type OfflineRegionStatus =
  | "not_available_web_demo"
  | "queued"
  | "demo_meta"
  | "error";

/** @deprecated Alias — UI/Tests: früher "downloaded" = nur Meta */
export type OfflineRegionStatusLegacy = OfflineRegionStatus | "downloaded";

export interface OfflineRegionStub {
  id: string;
  label: string;
  areaKm2: number;
  /** Spec NFR-08: ≤ 350 MB für 10.000 km² */
  sizeMbEstimate: number;
  status: OfflineRegionStatus;
  note: string;
  bbox?: OfflineRegionManifest["bbox"];
  version?: string;
}

function stubFromManifest(m: OfflineRegionManifest): OfflineRegionStub {
  return {
    id: m.id,
    label: m.label,
    areaKm2: m.areaKm2,
    sizeMbEstimate: m.sizeMbEstimate,
    status: "not_available_web_demo",
    note: "PMTiles + Valhalla FFI erst nach G-0 Native.",
    bbox: m.bbox,
    version: m.version,
  };
}

export const OFFLINE_REGIONS_DEMO: OfflineRegionStub[] =
  OFFLINE_REGION_MANIFESTS.map(stubFromManifest);

const STORAGE_KEY = "aetherride-offline-region-queue";

type QueueEntry = {
  regionId: string;
  status: "queued" | "demo_meta" | "error";
  updatedAt: string;
};

function normalizeStatus(
  s: string
): QueueEntry["status"] {
  if (s === "downloaded") return "demo_meta"; // Legacy-Migration
  if (s === "queued" || s === "demo_meta" || s === "error") return s;
  return "queued";
}

function readQueue(): QueueEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as { regionId: string; status: string; updatedAt: string }[];
    if (!Array.isArray(parsed)) return [];
    return parsed.map((e) => ({
      regionId: e.regionId,
      status: normalizeStatus(e.status),
      updatedAt: e.updatedAt,
    }));
  } catch {
    return [];
  }
}

function writeQueue(entries: QueueEntry[]) {
  if (typeof window === "undefined") return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
}

/** Echt: PMTiles-Download — auf Web immer false */
export function canDownloadOfflineOnWeb(): boolean {
  return false;
}

export function queueOfflineRegionInterest(
  regionId: string
): OfflineRegionStub | null {
  const base = OFFLINE_REGIONS_DEMO.find((r) => r.id === regionId);
  if (!base) return null;
  const q = readQueue().filter((e) => e.regionId !== regionId);
  q.push({
    regionId,
    status: "queued",
    updatedAt: new Date().toISOString(),
  });
  writeQueue(q);
  return {
    ...base,
    status: "queued",
    note: "Vormerkung lokal gespeichert — kein PMTiles-Download (Web-Demo / G-0 offen).",
  };
}

/** Nur Meta — keine Karten-Bytes */
export function markOfflineRegionPackDemo(
  regionId: string
): OfflineRegionStub | null {
  const base = OFFLINE_REGIONS_DEMO.find((r) => r.id === regionId);
  if (!base) return null;
  const q = readQueue().filter((e) => e.regionId !== regionId);
  q.push({
    regionId,
    status: "demo_meta",
    updatedAt: new Date().toISOString(),
  });
  writeQueue(q);
  return {
    ...base,
    status: "demo_meta",
    note: "Demo-Pack-Meta lokal — keine Offline-Karte, Routing weiter online/Demo.",
  };
}

export function dequeueOfflineRegionInterest(regionId: string): boolean {
  const before = readQueue();
  const next = before.filter((e) => e.regionId !== regionId);
  writeQueue(next);
  return next.length < before.length;
}

export function clearOfflineRegionQueue(): void {
  writeQueue([]);
}

export function listOfflineRegionsWithQueue(): OfflineRegionStub[] {
  const q = readQueue();
  return OFFLINE_REGIONS_DEMO.map((r) => {
    const hit = q.find((e) => e.regionId === r.id);
    if (!hit) return r;
    return {
      ...r,
      status: hit.status,
      note:
        hit.status === "queued"
          ? "Vormerkung lokal — PMTiles erst nach G-0 Native."
          : hit.status === "demo_meta"
            ? "Demo-Pack-Meta lokal — kein echtes Offline-Routing / keine Tiles."
            : r.note,
    };
  });
}

export function queuedOfflineBudgetMb(): {
  sizeMb: number;
  areaKm2: number;
  withinBudget: boolean;
} {
  const active = listOfflineRegionsWithQueue().filter(
    (r) => r.status === "queued" || r.status === "demo_meta"
  );
  const sizeMb = active.reduce((s, r) => s + r.sizeMbEstimate, 0);
  const areaKm2 = active.reduce((s, r) => s + r.areaKm2, 0);
  return {
    sizeMb,
    areaKm2,
    withinBudget: areaKm2 <= 0 ? true : offlinePackWithinBudget(sizeMb, areaKm2),
  };
}

export function offlineRegionsSummary(): string {
  return "Offline-Regionen: Web-Demo ohne PMTiles — echter Download nicht verfügbar; lokale Vormerkung/Meta möglich (G-0 offen).";
}

/** Budget-Check Spec NFR-08 */
export function offlinePackWithinBudget(
  sizeMb: number,
  areaKm2: number
): boolean {
  if (areaKm2 <= 0) return false;
  const limit = (350 / 10000) * areaKm2;
  return sizeMb <= limit * 1.05;
}
