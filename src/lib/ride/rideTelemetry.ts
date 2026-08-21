/**
 * Post-Ride-Telemetrie aus dem aufgezeichneten Track.
 *
 * GPS-Höhe ist rauschig — deshalb Fenster-Neigung, leichte Glättung,
 * Lücken bleiben Lücken. Kein DEM, kein Interpolieren als Messung.
 * Sensor-Kanäle (Puls, Cadenz, Leistung, Lean, g, Impact) nur wenn
 * sie wirklich auf Punkten stehen.
 */

export type GradeBand =
  | "steep_up"
  | "up"
  | "roll"
  | "down"
  | "steep_down"
  | "gap";

export const GRADE_COLORS: Record<GradeBand, string> = {
  steep_up: "#C2410C",
  up: "#FF6A00",
  roll: "#7A8B73",
  down: "#5B8C9A",
  steep_down: "#3D6B8A",
  gap: "#6B7280",
};

export type RideTrackInput = {
  lat?: number;
  latitude?: number;
  lng?: number;
  lon?: number;
  longitude?: number;
  elev?: number | null;
  ele?: number | null;
  altitude?: number | null;
  time?: number;
  timeMs?: number;
  hr?: number;
  heartRateBpm?: number;
  cad?: number;
  cadenceRpm?: number;
  power?: number;
  powerW?: number;
  lean?: number;
  leanDeg?: number;
  g?: number;
  gPeak?: number;
  impact?: number | boolean;
  spd?: number;
  speedKmh?: number;
};

export type RideSample = {
  distKm: number;
  lat: number;
  lng: number;
  elevM: number | null;
  gradePct: number | null;
  band: GradeBand;
  speedKmh: number | null;
  hr: number | null;
  cad: number | null;
  power: number | null;
  lean: number | null;
  gPeak: number | null;
  impact: boolean;
};

export type RideChannels = {
  elev: boolean;
  speed: boolean;
  hr: boolean;
  cad: boolean;
  power: boolean;
  lean: boolean;
  g: boolean;
  impact: boolean;
};

export type GradeLine = {
  id: string;
  coordinates: [number, number][];
  color: string;
  band: GradeBand;
};

export type RideTelemetry = {
  samples: RideSample[];
  chart: RideSample[];
  totalDistKm: number;
  climbM: number;
  descentM: number;
  gapKm: number;
  maxGradePct: number | null;
  minGradePct: number | null;
  maxSpeedKmh: number | null;
  avgSpeedKmh: number | null;
  avgHr: number | null;
  maxHr: number | null;
  avgCad: number | null;
  avgPower: number | null;
  impactCount: number;
  maxLean: number | null;
  maxG: number | null;
  channels: RideChannels;
  elevSource: "gps" | "none";
};

const R_EARTH_M = 6_371_000;
const GRADE_WINDOW_M = 35;
const GRADE_MIN_M = 18;
const SMOOTH_RADIUS_M = 40;
const CLIMB_STEP_M = 1.2;
const MAX_ABS_GRADE = 45;
const MAX_SPEED_KMH = 85;
const CHART_MAX = 240;
const MAP_MAX = 90;

export function haversineM(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R_EARTH_M * Math.asin(Math.min(1, Math.sqrt(a)));
}

function toRad(d: number): number {
  return (d * Math.PI) / 180;
}

function finiteNum(v: unknown): number | null {
  if (typeof v !== "number" || !Number.isFinite(v)) return null;
  return v;
}

function readLat(p: RideTrackInput): number | null {
  return finiteNum(p.lat) ?? finiteNum(p.latitude);
}

function readLng(p: RideTrackInput): number | null {
  return finiteNum(p.lng) ?? finiteNum(p.lon) ?? finiteNum(p.longitude);
}

function readElev(p: RideTrackInput): number | null {
  const raw =
    finiteNum(p.elev) ?? finiteNum(p.ele) ?? finiteNum(p.altitude);
  if (raw == null || raw < -50 || raw > 8900) return null;
  return raw;
}

function readHr(p: RideTrackInput): number | null {
  const v = finiteNum(p.hr) ?? finiteNum(p.heartRateBpm);
  if (v == null || v < 1 || v > 239) return null;
  return Math.round(v);
}

function readCad(p: RideTrackInput): number | null {
  const v = finiteNum(p.cad) ?? finiteNum(p.cadenceRpm);
  if (v == null || v < 1 || v > 254) return null;
  return Math.round(v);
}

function readPower(p: RideTrackInput): number | null {
  const v = finiteNum(p.power) ?? finiteNum(p.powerW);
  if (v == null || v < 1 || v > 2500) return null;
  return Math.round(v);
}

function readLean(p: RideTrackInput): number | null {
  const v = finiteNum(p.lean) ?? finiteNum(p.leanDeg);
  if (v == null || Math.abs(v) > 80) return null;
  return Math.round(v * 10) / 10;
}

function readG(p: RideTrackInput): number | null {
  const v = finiteNum(p.g) ?? finiteNum(p.gPeak);
  if (v == null || v <= 0 || v > 20) return null;
  return Math.round(v * 100) / 100;
}

function readImpact(p: RideTrackInput): boolean {
  if (p.impact === true) return true;
  const v = finiteNum(p.impact as number);
  return v != null && v > 0;
}

function readStampedSpeed(p: RideTrackInput): number | null {
  const v = finiteNum(p.spd) ?? finiteNum(p.speedKmh);
  if (v == null || v < 0.4 || v > MAX_SPEED_KMH) return null;
  return Math.round(v * 10) / 10;
}

function readTimeMs(p: RideTrackInput): number | null {
  const raw = finiteNum(p.time) ?? finiteNum(p.timeMs);
  if (raw == null) return null;
  if (raw >= 1e12) return raw;
  if (raw >= 1e9) return raw * 1000;
  return raw;
}

export function gradeBand(gradePct: number | null): GradeBand {
  if (gradePct == null || !Number.isFinite(gradePct)) return "gap";
  if (gradePct > 8) return "steep_up";
  if (gradePct > 3) return "up";
  if (gradePct >= -3) return "roll";
  if (gradePct >= -8) return "down";
  return "steep_down";
}

function mean(values: number[]): number | null {
  if (values.length === 0) return null;
  return values.reduce((a, b) => a + b, 0) / values.length;
}

function maxOf(values: number[]): number | null {
  if (values.length === 0) return null;
  return Math.max(...values);
}

function minOf(values: number[]): number | null {
  if (values.length === 0) return null;
  return Math.min(...values);
}

function lookBackIndex(distM: number[], i: number, windowM: number): number {
  let j = i;
  while (j > 0 && distM[i] - distM[j] < windowM) j -= 1;
  return j;
}

function downsample<T>(
  items: T[],
  max: number,
  keep?: (item: T) => boolean
): T[] {
  if (items.length <= max) return items;
  const taken = new Set<number>();
  const step = (items.length - 1) / (max - 1);
  for (let i = 0; i < max; i++) {
    taken.add(Math.round(i * step));
  }
  if (keep) {
    for (let i = 0; i < items.length; i++) {
      if (keep(items[i])) taken.add(i);
    }
  }
  return [...taken].sort((a, b) => a - b).map((i) => items[i]);
}

function emptyTelemetry(): RideTelemetry {
  return {
    samples: [],
    chart: [],
    totalDistKm: 0,
    climbM: 0,
    descentM: 0,
    gapKm: 0,
    maxGradePct: null,
    minGradePct: null,
    maxSpeedKmh: null,
    avgSpeedKmh: null,
    avgHr: null,
    maxHr: null,
    avgCad: null,
    avgPower: null,
    impactCount: 0,
    maxLean: null,
    maxG: null,
    channels: {
      elev: false,
      speed: false,
      hr: false,
      cad: false,
      power: false,
      lean: false,
      g: false,
      impact: false,
    },
    elevSource: "none",
  };
}

export function buildRideTelemetry(
  track: RideTrackInput[] | undefined | null
): RideTelemetry {
  if (!track || track.length < 2) return emptyTelemetry();

  const raw: {
    lat: number;
    lng: number;
    elev: number | null;
    timeMs: number | null;
    hr: number | null;
    cad: number | null;
    power: number | null;
    lean: number | null;
    gPeak: number | null;
    impact: boolean;
    spd: number | null;
  }[] = [];

  for (const p of track) {
    const lat = readLat(p);
    const lng = readLng(p);
    if (lat == null || lng == null) continue;
    if (Math.abs(lat) < 1e-6 && Math.abs(lng) < 1e-6) continue;
    raw.push({
      lat,
      lng,
      elev: readElev(p),
      timeMs: readTimeMs(p),
      hr: readHr(p),
      cad: readCad(p),
      power: readPower(p),
      lean: readLean(p),
      gPeak: readG(p),
      impact: readImpact(p),
      spd: readStampedSpeed(p),
    });
  }

  if (raw.length < 2) return emptyTelemetry();

  const distM = new Array<number>(raw.length);
  distM[0] = 0;
  for (let i = 1; i < raw.length; i++) {
    distM[i] =
      distM[i - 1] +
      haversineM(raw[i - 1].lat, raw[i - 1].lng, raw[i].lat, raw[i].lng);
  }

  const smoothed = raw.map((p, i) => {
    if (p.elev == null) return null;
    const lo = distM[i] - SMOOTH_RADIUS_M;
    const hi = distM[i] + SMOOTH_RADIUS_M;
    const win: number[] = [];
    for (let j = 0; j < raw.length; j++) {
      const e = raw[j].elev;
      if (e == null) continue;
      if (distM[j] < lo) continue;
      if (distM[j] > hi) break;
      win.push(e);
    }
    if (win.length === 0) return p.elev;
    return win.reduce((a, b) => a + b, 0) / win.length;
  });

  let climbM = 0;
  let descentM = 0;
  let gapKm = 0;
  let prevElev: number | null = smoothed[0];
  let prevDist = 0;
  for (let i = 1; i < raw.length; i++) {
    const e = smoothed[i];
    const dKm = (distM[i] - prevDist) / 1000;
    if (e == null) {
      gapKm += dKm;
      prevDist = distM[i];
      continue;
    }
    if (prevElev != null) {
      const d = e - prevElev;
      if (d > CLIMB_STEP_M) climbM += d;
      else if (d < -CLIMB_STEP_M) descentM += -d;
    }
    prevElev = e;
    prevDist = distM[i];
  }

  const samples: RideSample[] = raw.map((p, i) => {
    let gradePct: number | null = null;
    if (smoothed[i] != null && i > 0) {
      const j = lookBackIndex(distM, i, GRADE_WINDOW_M);
      const span = distM[i] - distM[j];
      const a = smoothed[j];
      const b = smoothed[i];
      if (a != null && b != null && span >= GRADE_MIN_M) {
        const g = ((b - a) / span) * 100;
        if (Number.isFinite(g)) {
          gradePct = Math.round(Math.max(-MAX_ABS_GRADE, Math.min(MAX_ABS_GRADE, g)) * 10) / 10;
        }
      }
    }

    let speedKmh = p.spd;
    if (speedKmh == null && i > 0 && p.timeMs != null && raw[i - 1].timeMs != null) {
      const dt = (p.timeMs - raw[i - 1].timeMs!) / 1000;
      const hop = distM[i] - distM[i - 1];
      const maxDt = hop >= 15 ? 900 : 30;
      if (dt >= 0.4 && dt <= maxDt && hop >= 0) {
        const v = (hop / dt) * 3.6;
        if (v >= 0.4 && v <= MAX_SPEED_KMH) {
          speedKmh = Math.round(v * 10) / 10;
        }
      }
    }

    return {
      distKm: Math.round((distM[i] / 1000) * 1000) / 1000,
      lat: p.lat,
      lng: p.lng,
      elevM: smoothed[i] != null ? Math.round(smoothed[i]! * 10) / 10 : null,
      gradePct,
      band: gradeBand(gradePct),
      speedKmh,
      hr: p.hr,
      cad: p.cad,
      power: p.power,
      lean: p.lean,
      gPeak: p.gPeak,
      impact: p.impact,
    };
  });

  const elevs = samples.map((s) => s.elevM).filter((e): e is number => e != null);
  const grades = samples
    .map((s) => s.gradePct)
    .filter((g): g is number => g != null);
  const speeds = samples
    .map((s) => s.speedKmh)
    .filter((v): v is number => v != null);
  const hrs = samples.map((s) => s.hr).filter((v): v is number => v != null);
  const cads = samples.map((s) => s.cad).filter((v): v is number => v != null);
  const powers = samples
    .map((s) => s.power)
    .filter((v): v is number => v != null);
  const leans = samples.map((s) => s.lean).filter((v): v is number => v != null);
  const gs = samples.map((s) => s.gPeak).filter((v): v is number => v != null);
  const impactCount = samples.filter((s) => s.impact).length;

  const channels: RideChannels = {
    elev: elevs.length >= 2,
    speed: speeds.length >= 2,
    hr: hrs.length >= 2,
    cad: cads.length >= 2,
    power: powers.length >= 2,
    lean: leans.length >= 2,
    g: gs.length >= 2,
    impact: impactCount > 0,
  };

  const totalDistKm = Math.round((distM[distM.length - 1] / 1000) * 100) / 100;
  const chart = downsample(samples, CHART_MAX, (s) => s.impact);

  return {
    samples,
    chart,
    totalDistKm,
    climbM: Math.round(climbM),
    descentM: Math.round(descentM),
    gapKm: Math.round(gapKm * 100) / 100,
    maxGradePct: maxOf(grades),
    minGradePct: minOf(grades),
    maxSpeedKmh: maxOf(speeds),
    avgSpeedKmh: mean(speeds) != null ? Math.round(mean(speeds)! * 10) / 10 : null,
    avgHr: mean(hrs) != null ? Math.round(mean(hrs)!) : null,
    maxHr: maxOf(hrs),
    avgCad: mean(cads) != null ? Math.round(mean(cads)!) : null,
    avgPower: mean(powers) != null ? Math.round(mean(powers)!) : null,
    impactCount,
    maxLean: maxOf(leans.map(Math.abs)),
    maxG: maxOf(gs),
    channels,
    elevSource: channels.elev ? "gps" : "none",
  };
}

export function gradeMapLayers(telemetry: RideTelemetry): GradeLine[] {
  const pts = downsample(telemetry.samples, MAP_MAX);
  if (pts.length < 2) return [];
  const lines: GradeLine[] = [];
  let start = 0;
  let band = pts[0].band;
  let n = 0;
  const flush = (end: number) => {
    const slice = pts.slice(start, end + 1);
    if (slice.length < 2) return;
    lines.push({
      id: `grade-${n++}`,
      coordinates: slice.map((p) => [p.lng, p.lat]),
      color: GRADE_COLORS[band],
      band,
    });
  };
  for (let i = 1; i < pts.length; i++) {
    if (pts[i].band !== band) {
      flush(i);
      start = i;
      band = pts[i].band;
    }
  }
  flush(pts.length - 1);
  return lines;
}

/** Persistierte Höhenmeter: Telemetrie-Anstieg, sonst gespeicherter Wert. */
export function honestClimbM(
  track: RideTrackInput[] | undefined | null,
  storedM = 0
): number {
  const tel = buildRideTelemetry(track);
  if (tel.channels.elev) return tel.climbM;
  return typeof storedM === "number" && Number.isFinite(storedM) && storedM > 0
    ? Math.round(storedM)
    : 0;
}

export function nearestSample(
  telemetry: RideTelemetry,
  distKm: number
): RideSample | null {
  const pts = telemetry.chart.length > 0 ? telemetry.chart : telemetry.samples;
  if (pts.length === 0) return null;
  let best = pts[0];
  let bestD = Math.abs(best.distKm - distKm);
  for (let i = 1; i < pts.length; i++) {
    const d = Math.abs(pts[i].distKm - distKm);
    if (d < bestD) {
      best = pts[i];
      bestD = d;
    }
  }
  return best;
}
