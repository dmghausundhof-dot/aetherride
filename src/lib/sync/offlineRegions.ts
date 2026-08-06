/**
 * Offline-Regionen Stub (F-NAV-002 / NFR-08)
 * Web-Demo: keine PMTiles — Status ehrlich kommunizieren.
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

export function canDownloadOfflineOnWeb(): boolean {
  return false;
}

export function offlineRegionsSummary(): string {
  return "Offline-Regionen: Web-Demo ohne PMTiles — Download nicht verfügbar.";
}
