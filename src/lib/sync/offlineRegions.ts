/**
 * Offline-Regionen Stub (F-NAV-002 / NFR-08)
 * Web-Demo: keine PMTiles — Status ehrlich kommunizieren.
 * Optional: lokale Warteschlange (queued/downloaded-Meta) ohne Routing-Claim.
 */

export type OfflineRegionStatus =
  | "not_available_web_demo"
  | "queued"
  | "downloaded"
  | "error";

export interface OfflineRegionStub {
  id: string;
  label: string;
  areaKm2: number;
  /** Spec NFR-08: ≤ 350 MB für 10.000 km² */
  sizeMbEstimate: number;
  status: OfflineRegionStatus;
  note: string;
}

export const OFFLINE_REGIONS_DEMO: OfflineRegionStub[] = [
  {
    id: "reg-tirol-alpbach",
    label: "Tirol · Alpbachtal",
    areaKm2: 1200,
    sizeMbEstimate: 48,
    status: "not_available_web_demo",
    note: "PMTiles + Valhalla FFI erst nach G-0/G-0-Maps (Native).",
  },
  {
    id: "reg-bayern-tegernsee",
    label: "Bayern · Tegernsee",
    areaKm2: 900,
    sizeMbEstimate: 36,
    status: "not_available_web_demo",
    note: "Offline-Routing Demo nur als Kostenfunktion online.",
  },
];

const STORAGE_KEY = "aetherride-offline-region-queue";

type QueueEntry = {
  regionId: string;
  status: Extract<OfflineRegionStatus, "queued" | "downloaded" | "error">;
  updatedAt: string;
};

function readQueue(): QueueEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as QueueEntry[];
    return Array.isArray(parsed) ? parsed : [];
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

/**
 * Meta-Warteschlange: merkt Interesse / Demo-„Pack“ ohne Karten-Bytes.
 * Kein Routing, kein PMTiles — nur ehrlicher Status für UI.
 */
export function queueOfflineRegionInterest(regionId: string): OfflineRegionStub | null {
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

export function markOfflineRegionPackDemo(regionId: string): OfflineRegionStub | null {
  const base = OFFLINE_REGIONS_DEMO.find((r) => r.id === regionId);
  if (!base) return null;
  const q = readQueue().filter((e) => e.regionId !== regionId);
  q.push({
    regionId,
    status: "downloaded",
    updatedAt: new Date().toISOString(),
  });
  writeQueue(q);
  return {
    ...base,
    status: "downloaded",
    note: "Demo-Pack-Meta lokal — keine Offline-Karte, Routing weiter online/Demo.",
  };
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
          : hit.status === "downloaded"
            ? "Demo-Pack-Meta lokal — kein echtes Offline-Routing."
            : r.note,
    };
  });
}

export function offlineRegionsSummary(): string {
  return "Offline-Regionen: Web-Demo ohne PMTiles — echter Download nicht verfügbar; lokale Vormerkung möglich.";
}

/** Budget-Check Spec NFR-08 */
export function offlinePackWithinBudget(sizeMb: number, areaKm2: number): boolean {
  if (areaKm2 <= 0) return false;
  const limit = (350 / 10000) * areaKm2;
  return sizeMb <= limit * 1.05;
}
