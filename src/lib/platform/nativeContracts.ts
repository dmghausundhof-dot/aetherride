/**
 * G-0 / Kap. 5 — Native Platform-Channel-Contracts
 *
 * Zielplattform Spec: Flutter + native dsp_core / routing_core.
 * Diese Web-App ist die Spec-treue Demo-Schicht; Channels dokumentieren
 * die Produktions-Schnittstelle.
 */

export const NATIVE_CHANNELS = {
  sensorBatch: "aetherride/sensor_batch",
  bleBosch: "aetherride/ble_bosch_ldi",
  bleStandard: "aetherride/ble_standard",
  routing: "aetherride/routing_valhalla",
  tts: "aetherride/tts",
  pmtiles: "aetherride/pmtiles",
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
    notes: [
      "G-0 offen: Kein Flutter — Next.js Web-Demo mit Spec-Contracts.",
      "Sensorik: WebSensorSimulator 200 Hz Batches (nicht CoreMotion).",
      "Routing: Demo-Kostenfunktion; Valhalla FFI ausstehend.",
      "FNI/Durchschlag/Setup-Rec: Engine vorhanden, Gate G-2 steuert Live.",
      "Wegerecht: Demo-Regeln, Gate G-5 Legal ausstehend.",
    ],
  };
}
