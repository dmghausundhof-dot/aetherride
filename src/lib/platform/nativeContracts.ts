/**
 * G-0 / Kap. 5 — Native Platform-Channel-Contracts
 *
 * Zielplattform Spec: Flutter + native dsp_core / routing_core — erst nach G-0.
 * Diese Web-App ist die Spec-treue Demo-Schicht; Channels dokumentieren
 * die Produktions-Schnittstelle. Kein Fake-Flutter.
 */

import { g0StatusShort, isG0Closed } from "./g0TeamSetup";

export const NATIVE_CHANNELS = {
  sensorBatch: "aetherride/sensor_batch",
  location: "aetherride/location",
  bleBosch: "aetherride/ble_bosch_ldi",
  bleStandard: "aetherride/ble_standard",
  routing: "aetherride/routing_valhalla",
  tts: "aetherride/tts",
  pmtiles: "aetherride/pmtiles",
  dspFfi: "aetherride/dsp_ffi",
} as const;

/** Spec-Invariante: keine MethodChannel-Calls pro Sample */
export const SENSOR_BATCH_INVARIANTS = {
  sampleRateHz: 200 as const,
  transferBlockSec: 1,
  productionEncoding: "int16_deltas",
  demoEncoding: "float64",
  noPerSampleMethodChannel: true,
} as const;

export interface SensorBatchMessage {
  /** Spec: 1-s-Blöcke, int16-Deltas — hier float64 Demo */
  sampleRateHz: 200;
  samples: {
    tMs: number;
    ax: number;
    ay: number;
    az: number;
    gx: number;
    gy: number;
    gz: number;
  }[];
  speedMs: number;
  headingDeg?: number;
}

export interface LocationSampleMessage {
  tMs: number;
  lat: number;
  lng: number;
  altitudeM?: number;
  accuracyM?: number;
  speedMs?: number;
}

export interface RoutingRequestMessage {
  profile:
    | "MTB_TRAIL"
    | "MTB_ENDURO"
    | "GRAVEL"
    | "ROAD"
    | "EBIKE_TOUR"
    | "EMTB"
    | "HIKING";
  from: { lat: number; lng: number };
  to: { lat: number; lng: number };
  offlineRegionId?: string;
  jurisdiction: string;
}

export interface PlatformCapabilityReport {
  flutter: boolean;
  coreMotionOrSensorManager: boolean;
  valhallaFfi: boolean;
  pmtiles: boolean;
  boschLdi: boolean;
  /** Web-Demo Status */
  webDemoOnly: true;
  g0Closed: boolean;
  notes: string[];
}

export function webDemoCapabilities(): PlatformCapabilityReport {
  return {
    flutter: false,
    coreMotionOrSensorManager: false,
    valhallaFfi: false,
    pmtiles: false,
    boschLdi: false,
    webDemoOnly: true,
    g0Closed: isG0Closed(),
    notes: [
      g0StatusShort(),
      "Sensorik: WebSensorSimulator 200 Hz Batches (nicht CoreMotion).",
      "Routing: Demo-Kostenfunktion; Valhalla FFI ausstehend.",
      "FNI/Durchschlag/Setup-Rec: Engine vorhanden, Gate G-2 steuert Live.",
      "Wegerecht: Demo-Regeln Tirol/Bayern — Gate G-5 Legal ausstehend.",
      "A-08 Setup-Haftung: redaktioneller Entwurf, Legal ausstehend.",
      "G-1 Bosch LDI: Outreach-Paket bereit, Zugang/AGB ausstehend (Simulator ≠ Production).",
    ],
  };
}
