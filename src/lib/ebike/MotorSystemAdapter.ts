/**
 * Spec 8.x / F-EBK — MotorSystemAdapter
 *
 * capabilities() steuert die UI. Nicht gelieferte Felder ausblenden,
 * nie mit Null/Schätzung füllen. Keine Schreiboperationen (F-EBK-000).
 */

import {
  createBoschLDIClient,
  type BoschLDIClient,
  type BoschLiveData,
} from "@/lib/ble/BoschLDI";

export type MotorTier = 0 | 1 | 2;

export interface MotorCapabilities {
  tier: MotorTier;
  label: string;
  readSpeed: boolean;
  readSoc: boolean;
  readRiderPower: boolean;
  readCadence: boolean;
  readOdometer: boolean;
  readAssistMode: boolean;
  /** Immer false — Absicherung F-EBK-000 */
  writeAssistMode: false;
  systemGeneration?: string;
  vendor: "none" | "bosch_ldi" | "manual" | "standard_ble";
}

export interface MotorTelemetry {
  speedKmh?: number;
  batterySocPercent?: number;
  riderPowerW?: number;
  cadenceRpm?: number;
  odometerKm?: number;
  timestamp: number;
  source: MotorCapabilities["vendor"];
}

export interface MotorSystemAdapter {
  capabilities(): MotorCapabilities;
  connect(): Promise<boolean>;
  disconnect(): Promise<void>;
  isConnected(): boolean;
  onTelemetry(cb: (t: MotorTelemetry) => void): void;
  getLast(): MotorTelemetry | null;
}

const NO_WRITE = false as const;

export class ManualMotorAdapter implements MotorSystemAdapter {
  private connected = false;
  private last: MotorTelemetry | null = null;
  private cb: ((t: MotorTelemetry) => void) | null = null;
  private soc: number;
  private capacityWh: number;

  constructor(opts: { socPercent?: number; capacityWh?: number } = {}) {
    this.soc = opts.socPercent ?? 80;
    this.capacityWh = opts.capacityWh ?? 625;
  }

  capabilities(): MotorCapabilities {
    return {
      tier: 0,
      label: "Stufe 0 — Manuell (jeder Hersteller)",
      readSpeed: false,
      readSoc: true, // manuell gesetzt
      readRiderPower: false,
      readCadence: false,
      readOdometer: false,
      readAssistMode: false,
      writeAssistMode: NO_WRITE,
      vendor: "manual",
    };
  }

  async connect() {
    this.connected = true;
    this.last = {
      batterySocPercent: this.soc,
      timestamp: Date.now(),
      source: "manual",
    };
    this.cb?.(this.last);
    return true;
  }

  async disconnect() {
    this.connected = false;
  }

  isConnected() {
    return this.connected;
  }

  onTelemetry(cb: (t: MotorTelemetry) => void) {
    this.cb = cb;
  }

  getLast() {
    return this.last;
  }

  setManualSoc(pct: number) {
    this.soc = Math.max(0, Math.min(100, pct));
    this.last = {
      batterySocPercent: this.soc,
      timestamp: Date.now(),
      source: "manual",
    };
    this.cb?.(this.last);
  }

  getCapacityWh() {
    return this.capacityWh;
  }
}

export class BoschLdiAdapter implements MotorSystemAdapter {
  private client: BoschLDIClient;
  private cb: ((t: MotorTelemetry) => void) | null = null;
  private last: MotorTelemetry | null = null;
  private generationSupported: boolean;

  constructor(opts: { generationSupported?: boolean } = {}) {
    this.client = createBoschLDIClient();
    this.generationSupported = opts.generationSupported ?? true;
    this.client.onData((d: BoschLiveData) => {
      const t: MotorTelemetry = {
        speedKmh: d.speedKmh,
        batterySocPercent: d.batterySocPercent,
        riderPowerW: d.riderPowerW,
        cadenceRpm: d.cadenceRpm,
        odometerKm: d.odometerKm,
        timestamp: d.timestamp,
        source: "bosch_ldi",
      };
      this.last = t;
      this.cb?.(t);
    });
  }

  capabilities(): MotorCapabilities {
    if (!this.generationSupported) {
      return {
        tier: 0,
        label: "Bosch-Generation nicht unterstützt — Fallback Stufe 0",
        readSpeed: false,
        readSoc: false,
        readRiderPower: false,
        readCadence: false,
        readOdometer: false,
        readAssistMode: false,
        writeAssistMode: NO_WRITE,
        vendor: "manual",
        systemGeneration: "legacy",
      };
    }
    return {
      tier: 1,
      label: "Stufe 1 — Bosch LDI (read-only)",
      readSpeed: true,
      readSoc: true,
      readRiderPower: true,
      readCadence: true,
      readOdometer: true,
      readAssistMode: false, // nicht in freier LDI-Liste
      writeAssistMode: NO_WRITE,
      vendor: "bosch_ldi",
      systemGeneration: "smart_system",
    };
  }

  connect() {
    return this.client.connect();
  }

  disconnect() {
    return this.client.disconnect();
  }

  isConnected() {
    return this.client.isConnected();
  }

  onTelemetry(cb: (t: MotorTelemetry) => void) {
    this.cb = cb;
  }

  getLast() {
    return this.last;
  }
}

/** Factory: Bosch wenn E-Bike smart system, sonst manuell */
export function createMotorAdapter(input: {
  isEbike: boolean;
  preferBoschLdi?: boolean;
  boschSupported?: boolean;
}): MotorSystemAdapter {
  if (input.isEbike && input.preferBoschLdi !== false) {
    return new BoschLdiAdapter({
      generationSupported: input.boschSupported ?? true,
    });
  }
  return new ManualMotorAdapter();
}
