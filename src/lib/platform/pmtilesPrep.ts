/**
 * Native Offline-PMTiles Prep (F-NAV-002 / NFR-08)
 *
 * Contracts + Web-Meta-Queue. G-0 bleibt offen — kein Fake-Download,
 * kein MapLibre-pmtiles-Protocol auf Web.
 */

import { G0_MOBILE_STACK_CONFIRMED } from "@/lib/platform/g0TeamSetup";
import {
  NATIVE_CHANNELS,
  PMTILES_PROTOCOL_HOOK,
  type PmtilesProtocolHook,
} from "@/lib/platform/nativeContracts";

/** Spec: Packs älter als 90 Tage als veraltet markieren */
export const PMTILES_STALE_AFTER_DAYS = 90;

export interface OfflineRegionManifest {
  id: string;
  label: string;
  /** WGS84 bbox [west, south, east, north] */
  bbox: [number, number, number, number];
  areaKm2: number;
  sizeMbEstimate: number;
  version: string;
  generatedAt: string;
  staleAfterDays: typeof PMTILES_STALE_AFTER_DAYS;
  /** Nach G-0: CDN-/Object-Storage-URL zum .pmtiles */
  packUrlTemplate: string;
  maxZoom: number;
}

export interface NativePmtilesPrepReport {
  g0Confirmed: boolean;
  webCanDownload: false;
  channel: typeof NATIVE_CHANNELS.pmtiles;
  protocol: PmtilesProtocolHook;
  /** Darf MapLibre `addProtocol('pmtiles')` nur nach G-0 Native */
  mayRegisterMapProtocol: boolean;
  manifests: OfflineRegionManifest[];
  postG0StepsDe: string[];
  noteDe: string;
}

/** Demo-Regionen als Manifest-Shape (kein Byte-Download) */
export const OFFLINE_REGION_MANIFESTS: OfflineRegionManifest[] = [
  {
    id: "reg-tirol-alpbach",
    label: "Tirol · Alpbachtal",
    bbox: [11.8, 47.2, 12.1, 47.5],
    areaKm2: 1200,
    sizeMbEstimate: 48,
    version: "2026.08-demo",
    generatedAt: "2026-08-06T00:00:00.000Z",
    staleAfterDays: PMTILES_STALE_AFTER_DAYS,
    packUrlTemplate:
      "https://tiles.aetherride.demo/regions/{id}/v{version}.pmtiles",
    maxZoom: PMTILES_PROTOCOL_HOOK.maxZoom,
  },
  {
    id: "reg-bayern-tegernsee",
    label: "Bayern · Tegernsee",
    bbox: [11.6, 47.6, 11.9, 47.85],
    areaKm2: 900,
    sizeMbEstimate: 36,
    version: "2026.08-demo",
    generatedAt: "2026-08-06T00:00:00.000Z",
    staleAfterDays: PMTILES_STALE_AFTER_DAYS,
    packUrlTemplate:
      "https://tiles.aetherride.demo/regions/{id}/v{version}.pmtiles",
    maxZoom: PMTILES_PROTOCOL_HOOK.maxZoom,
  },
  {
    id: "reg-salzburg-flachgau",
    label: "Salzburg · Flachgau",
    bbox: [12.9, 47.7, 13.3, 48.05],
    areaKm2: 1500,
    sizeMbEstimate: 58,
    version: "2026.08-demo",
    generatedAt: "2026-08-06T00:00:00.000Z",
    staleAfterDays: PMTILES_STALE_AFTER_DAYS,
    packUrlTemplate:
      "https://tiles.aetherride.demo/regions/{id}/v{version}.pmtiles",
    maxZoom: PMTILES_PROTOCOL_HOOK.maxZoom,
  },
];

/**
 * Web darf das PMTiles-Protocol NIEMALS registrieren solange G-0 offen.
 * Nach G-0: nur Native (MapLibre Flutter / Mobile).
 */
export function mayRegisterPmtilesProtocol(): boolean {
  return G0_MOBILE_STACK_CONFIRMED === true;
}

export function isManifestStale(
  manifest: OfflineRegionManifest,
  now = new Date()
): boolean {
  const gen = Date.parse(manifest.generatedAt);
  if (!Number.isFinite(gen)) return true;
  const ageMs = now.getTime() - gen;
  return ageMs > manifest.staleAfterDays * 24 * 60 * 60 * 1000;
}

export function resolvePackUrl(manifest: OfflineRegionManifest): string {
  return manifest.packUrlTemplate
    .replace("{id}", manifest.id)
    .replace("{version}", manifest.version);
}

export function getNativePmtilesPrepReport(): NativePmtilesPrepReport {
  return {
    g0Confirmed: G0_MOBILE_STACK_CONFIRMED,
    webCanDownload: false,
    channel: NATIVE_CHANNELS.pmtiles,
    protocol: PMTILES_PROTOCOL_HOOK,
    mayRegisterMapProtocol: mayRegisterPmtilesProtocol(),
    manifests: OFFLINE_REGION_MANIFESTS,
    postG0StepsDe: [
      "Planetiler/Tippecanoe → regionale .pmtiles bauen",
      "Packs auf CDN legen (packUrlTemplate)",
      "MapLibre Native: Protocol pmtiles:// registrieren",
      "Valhalla FFI Offline-Routing an Region koppeln",
      "NFR-08 Budget + Stale>90d in UI erzwingen",
    ],
    noteDe: G0_MOBILE_STACK_CONFIRMED
      ? "G-0 bestätigt — Native PMTiles-Integration freigeschaltet."
      : "G-0 offen — nur Contracts + Meta-Queue; Web ohne PMTiles-Download.",
  };
}

export function nativePmtilesPrepSummaryDe(): string {
  const r = getNativePmtilesPrepReport();
  return `${r.noteDe} Channel ${r.channel} · ${r.manifests.length} Manifeste · Protocol ${r.mayRegisterMapProtocol ? "erlaubt" : "gesperrt"}.`;
}
