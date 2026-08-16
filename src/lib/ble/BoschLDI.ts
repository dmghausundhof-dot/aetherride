/**
 * FlowLine – Bosch Live Data Interface (LDI) Client
 *
 * Contract + Web-Simulation. Im Browser: immer Simulator (kein BLE, keine
 * echte Hardware). Native BLE lebt in der Flutter-App.
 *
 * Datenpunkte laut Spec (Read-only): Speed, Battery SOC, Rider Power, Cadence,
 * Odometer, Light Status, Ambient Brightness, System Lock, …
 */

export interface BoschLiveData {
  speedKmh: number;
  batterySocPercent: number;
  riderPowerW: number;
  cadenceRpm: number;
  odometerKm: number;
  lightStatus: boolean;
  ambientBrightness: number; // 0–100
  systemLock: boolean;
  bikeNotDriving: boolean;
  chargerConnected: boolean;
  timestamp: number;
}

export interface BoschLDIClient {
  connect(): Promise<boolean>;
  disconnect(): Promise<void>;
  isConnected(): boolean;
  onData(callback: (data: BoschLiveData) => void): void;
  getLastData(): BoschLiveData | null;
}

/**
 * Offizielle Service/Characteristic UUIDs würden hier stehen
 * (aus der Bosch LDI Spec PDF – hier abstrahiert).
 * Die echte Implementierung mapped die BLE Notifications 1:1.
 */
export const BOSCH_LDI_SERVICE = "00000010-eaa2-11e9-81b4-2a2ae2dbcce4"; // Beispiel aus Community + Spec-Nähe

/**
 * Web-Simulator — kein echtes Bosch-BLE. Nur Demo-Werte für UI/Flow.
 * Native (Flutter) ersetzt dies durch echte GATT-Implementierung.
 * UI muss „Simulation“ kennzeichnen — nie als echte Hardware-Verbindung ausgeben.
 */
export class BoschLDIWebSimulator implements BoschLDIClient {
  private connected = false;
  private callback: ((data: BoschLiveData) => void) | null = null;
  private lastData: BoschLiveData | null = null;
  private timer: ReturnType<typeof setInterval> | null = null;
  private soc = 87;
  private odometer = 1247.4;

  async connect(): Promise<boolean> {
    // Simuliere Scan + Connect Delay
    await new Promise((r) => setTimeout(r, 600));
    this.connected = true;
    this.startStreaming();
    return true;
  }

  async disconnect(): Promise<void> {
    this.connected = false;
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  isConnected() {
    return this.connected;
  }

  onData(cb: (data: BoschLiveData) => void) {
    this.callback = cb;
  }

  getLastData() {
    return this.lastData;
  }

  private startStreaming() {
    this.timer = setInterval(() => {
      if (!this.connected) return;

      // Realistische Fahrt-Simulation
      const speed = 8 + Math.random() * 22;
      const cadence = speed > 3 ? 55 + Math.random() * 45 : 0;
      const riderPower = cadence > 0 ? 60 + Math.random() * 220 : 0;

      // SOC langsam sinken
      if (Math.random() > 0.96) this.soc = Math.max(5, this.soc - 1);
      this.odometer += speed / 3600; // km pro Sekunde

      const data: BoschLiveData = {
        speedKmh: Math.round(speed * 10) / 10,
        batterySocPercent: Math.round(this.soc),
        riderPowerW: Math.round(riderPower),
        cadenceRpm: Math.round(cadence),
        odometerKm: Math.round(this.odometer * 10) / 10,
        lightStatus: false,
        ambientBrightness: 40 + Math.random() * 40,
        systemLock: false,
        bikeNotDriving: speed < 1.5,
        chargerConnected: false,
        timestamp: Date.now(),
      };

      this.lastData = data;
      this.callback?.(data);
    }, 1000);
  }
}

/**
 * Factory — im Browser immer Web-Simulator (kein BLE).
 * Native Clients leben in der Flutter-App, nicht hier.
 */
export function createBoschLDIClient(): BoschLDIClient {
  return new BoschLDIWebSimulator();
}
