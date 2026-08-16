import type { Ride } from "@/types";
import { HOF_COPY, type HofCopy } from "./hofCopy";

export type RideReturnKind = "neverOut" | "justBack" | "atHof";

export type RideReturn = {
  kind: RideReturnKind;
  rideId?: string;
  daysSince?: number;
  distanceKm?: number;
  movingTimeSec?: number;
  endedAt?: string;
  usedGps?: boolean;
};

function rideUsedGps(ride: Ride): boolean {
  return (ride.track?.length ?? 0) > 1;
}

export function rideReturnForBike(opts: {
  bikeId: string;
  rides: Ride[];
  now?: Date;
  justBackWindowMs?: number;
}): RideReturn {
  const now = opts.now ?? new Date();
  const windowMs = opts.justBackWindowMs ?? 4 * 60 * 60 * 1000;
  const mine = opts.rides
    .filter((r) => r.bikeId === opts.bikeId && r.endTime)
    .sort(
      (a, b) =>
        new Date(b.endTime ?? b.startTime).getTime() -
        new Date(a.endTime ?? a.startTime).getTime()
    );
  const last = mine[0];
  if (!last?.endTime) return { kind: "neverOut" };
  const end = new Date(last.endTime);
  if (Number.isNaN(end.getTime())) return { kind: "neverOut" };
  const usedGps = rideUsedGps(last);
  if (now.getTime() - end.getTime() <= windowMs) {
    return {
      kind: "justBack",
      rideId: last.id,
      distanceKm: last.distanceM / 1000,
      movingTimeSec: last.durationSec,
      endedAt: last.endTime,
      usedGps,
    };
  }
  const days = Math.max(
    1,
    Math.floor((now.getTime() - end.getTime()) / 86_400_000)
  );
  return {
    kind: "atHof",
    rideId: last.id,
    daysSince: days,
    endedAt: last.endTime,
    usedGps,
  };
}

export function formatMovingTime(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.round((sec % 3600) / 60);
  if (h <= 0) return `${m} min`;
  return `${h}:${String(m).padStart(2, "0")}`;
}

export function residentMeta(opts: {
  sport: string;
  ret: RideReturn;
  copy?: HofCopy;
}): string {
  const { sport, ret } = opts;
  const copy = opts.copy ?? HOF_COPY;
  if (ret.kind === "neverOut") {
    return `${sport} · ${copy.atHof} · ${copy.notYetOut}`;
  }
  let ago: string | null = null;
  let agoHours = false;
  if (ret.endedAt) {
    const ended = new Date(ret.endedAt);
    if (!Number.isNaN(ended.getTime())) {
      const m = Math.round((Date.now() - ended.getTime()) / 60_000);
      if (m < 60) {
        ago = copy.agoMinutes(Math.max(1, m));
      } else if (m < 24 * 60) {
        ago = copy.agoHours(Math.min(23, Math.max(1, Math.floor(m / 60))));
        agoHours = true;
      }
    }
  }
  if (ret.kind === "justBack") {
    const km = ret.distanceKm ?? 0;
    const hasDistance = Boolean(ret.usedGps) || km > 0.05;
    const fresh = !agoHours;
    const parts = [
      ...(fresh ? [copy.justBack] : []),
      ago,
    ].filter(Boolean) as string[];
    if (hasDistance) {
      parts.push(`${km.toFixed(1)} km`);
      if (ret.movingTimeSec != null) parts.push(formatMovingTime(ret.movingTimeSec));
    }
    if (!ret.usedGps) parts.push(copy.lastRideNoGps);
    return parts.join(" · ");
  }
  const since =
    agoHours && ago
      ? ago
      : ret.daysSince === 1
        ? copy.sinceOneDay
        : copy.sinceDays(ret.daysSince ?? 1);
  const base = `${sport} · ${copy.atHof} · ${since}`;
  return ret.usedGps ? base : `${base} · ${copy.lastRideNoGps}`;
}
