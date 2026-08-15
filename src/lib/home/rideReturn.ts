import type { Ride } from "@/types";
import { HOF_COPY } from "./hofCopy";

export type RideReturnKind = "neverOut" | "justBack" | "atHof";

export type RideReturn = {
  kind: RideReturnKind;
  daysSince?: number;
  distanceKm?: number;
  movingTimeSec?: number;
  endedAt?: string;
};

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
  if (now.getTime() - end.getTime() <= windowMs) {
    return {
      kind: "justBack",
      distanceKm: last.distanceM / 1000,
      movingTimeSec: last.durationSec,
      endedAt: last.endTime,
    };
  }
  const days = Math.max(
    1,
    Math.floor((now.getTime() - end.getTime()) / 86_400_000)
  );
  return { kind: "atHof", daysSince: days, endedAt: last.endTime };
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
}): string {
  const { sport, ret } = opts;
  if (ret.kind === "neverOut") {
    return `${sport} · ${HOF_COPY.atHof} · ${HOF_COPY.notYetOut}`;
  }
  if (ret.kind === "justBack") {
    const km =
      ret.distanceKm != null ? `${ret.distanceKm.toFixed(1)} km` : null;
    const time =
      ret.movingTimeSec != null ? formatMovingTime(ret.movingTimeSec) : null;
    return [HOF_COPY.justBack, km, time].filter(Boolean).join(" · ");
  }
  const since =
    ret.daysSince === 1
      ? HOF_COPY.sinceOneDay
      : HOF_COPY.sinceDays(ret.daysSince ?? 1);
  return `${sport} · ${HOF_COPY.atHof} · ${since}`;
}
