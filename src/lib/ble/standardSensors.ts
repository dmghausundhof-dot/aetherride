/**
 * F-EBK-003 — Standard-BLE-Sensorik (P0)
 * CSCS (Cycling Speed and Cadence), CPS (Cycling Power), HRS (Heart Rate)
 *
 * Web: Simulator. Produktion: flutter_blue_plus / CoreBluetooth / GATT.
 * UUIDs: Bluetooth SIG Assigned Numbers.
 */

export const BLE_UUID = {
  cscsService: "00001816-0000-1000-8000-00805f9b34fb",
  cscMeasurement: "00002a5b-0000-1000-8000-00805f9b34fb",
  cpsService: "00001818-0000-1000-8000-00805f9b34fb",
  cyclingPowerMeasurement: "00002a63-0000-1000-8000-00805f9b34fb",
  hrsService: "0000180d-0000-1000-8000-00805f9b34fb",
  heartRateMeasurement: "00002a37-0000-1000-8000-00805f9b34fb",
} as const;

export interface CscsSample {
  speedKmh: number | null;
  cadenceRpm: number | null;
  wheelRevs?: number;
  crankRevs?: number;
  timestamp: number;
}

export interface CpsSample {
  powerW: number;
  timestamp: number;
}

export interface HrsSample {
  bpm: number;
  timestamp: number;
}

export interface StandardBleBundle {
  cscs: CscsSample | null;
  cps: CpsSample | null;
  hrs: HrsSample | null;
}

export interface StandardBleClient {
  connect(): Promise<boolean>;
  disconnect(): Promise<void>;
  isConnected(): boolean;
  onData(cb: (b: StandardBleBundle) => void): void;
  getLast(): StandardBleBundle;
  capabilities(): {
    cscs: boolean;
    cps: boolean;
    hrs: boolean;
  };
}

/** Web-Simulator für CSCS/CPS/HRS */
export class StandardBleWebSimulator implements StandardBleClient {
  private connected = false;
  private timer: ReturnType<typeof setInterval> | null = null;
  private cb: ((b: StandardBleBundle) => void) | null = null;
  private last: StandardBleBundle = { cscs: null, cps: null, hrs: null };
  private wheelRevs = 0;
  private crankRevs = 0;

  async connect() {
    await new Promise((r) => setTimeout(r, 400));
    this.connected = true;
    this.timer = setInterval(() => {
      if (!this.connected) return;
      const speed = 10 + Math.random() * 18;
      const cadence = speed > 2 ? 60 + Math.random() * 40 : 0;
      const power = cadence > 0 ? 80 + Math.random() * 200 : 0;
      this.wheelRevs += Math.round(speed / 7);
      this.crankRevs += Math.round(cadence / 60);
      this.last = {
        cscs: {
          speedKmh: Math.round(speed * 10) / 10,
          cadenceRpm: Math.round(cadence),
          wheelRevs: this.wheelRevs,
          crankRevs: this.crankRevs,
          timestamp: Date.now(),
        },
        cps: { powerW: Math.round(power), timestamp: Date.now() },
        hrs: {
          bpm: Math.round(120 + Math.random() * 40),
          timestamp: Date.now(),
        },
      };
      this.cb?.(this.last);
    }, 1000);
    return true;
  }

  async disconnect() {
    this.connected = false;
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  isConnected() {
    return this.connected;
  }

  onData(cb: (b: StandardBleBundle) => void) {
    this.cb = cb;
  }

  getLast() {
    return this.last;
  }

  capabilities() {
    return { cscs: true, cps: true, hrs: true };
  }
}

export function createStandardBleClient(): StandardBleClient {
  return new StandardBleWebSimulator();
}
