/**
 * F-ACC-003 — FIT-Export (Garmin FIT SDK)
 * Activity: FileId → Record* → Lap → Session → Activity
 */

import { Encoder, Profile } from "@garmin/fitsdk";
import type { Ride } from "@/types";
import type { PrivacyZone } from "@/lib/privacy/consents";

function synthesizeTrack(ride: Ride) {
  const n = Math.max(10, Math.min(200, Math.round(ride.durationSec / 30)));
  const out: { lat: number; lng: number; elev?: number; time: number }[] = [];
  for (let i = 0; i < n; i++) {
    out.push({
      lat: 47.45 + Math.sin(i / 8) * 0.01,
      lng: 12.15 + i * 0.0002,
      elev: 800 + (ride.elevationGainM * i) / n,
      time: i * Math.max(1, Math.round(ride.durationSec / n)),
    });
  }
  return out;
}

function haversineM(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number }
) {
  const R = 6371000;
  const toR = (d: number) => (d * Math.PI) / 180;
  const dLat = toR(b.lat - a.lat);
  const dLon = toR(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toR(a.lat)) * Math.cos(toR(b.lat)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Privatsphärenzonen: Start/Ende und Radius kappen (F-ACC-005) */
export function trimTrackForPrivacy(
  track: { lat: number; lng: number; elev?: number; time: number }[],
  zones: PrivacyZone[]
) {
  if (!zones.length) return track;
  return track.filter((p) => {
    for (const z of zones) {
      if (haversineM(p, { lat: z.lat, lng: z.lng }) < z.radiusM) return false;
    }
    return true;
  });
}

type FitMesg = Record<string, unknown>;

export function rideToFit(
  ride: Ride,
  opts: { privacyZones?: PrivacyZone[] } = {}
): Uint8Array {
  const encoder = new Encoder();
  const start = new Date(ride.startTime);
  const end = ride.endTime
    ? new Date(ride.endTime)
    : new Date(start.getTime() + ride.durationSec * 1000);

  encoder.onMesg(Profile.MesgNum.FILE_ID, {
    manufacturer: "development",
    product: 1,
    timeCreated: start,
    type: "activity",
  } as FitMesg);

  let pts =
    ride.track && ride.track.length > 0 ? [...ride.track] : synthesizeTrack(ride);
  pts = trimTrackForPrivacy(pts, opts.privacyZones ?? []);

  let distance = 0;
  for (let i = 0; i < pts.length; i++) {
    const p = pts[i];
    if (i > 0) distance += haversineM(pts[i - 1], p);
    const ts = new Date(start.getTime() + (p.time || i) * 1000);
    encoder.onMesg(Profile.MesgNum.RECORD, {
      timestamp: ts,
      positionLat: Math.round(p.lat * (2 ** 31 / 180)),
      positionLong: Math.round(p.lng * (2 ** 31 / 180)),
      distance: Math.round(distance * 100) / 100,
      altitude: p.elev,
      speed:
        i > 0
          ? haversineM(pts[i - 1], p) /
            Math.max(1, (p.time || i) - (pts[i - 1].time || i - 1))
          : 0,
    } as FitMesg);
  }

  encoder.onMesg(Profile.MesgNum.LAP, {
    event: "lap",
    eventType: "stop",
    startTime: start,
    timestamp: end,
    totalElapsedTime: ride.durationSec,
    totalTimerTime: ride.durationSec,
    totalDistance: ride.distanceM,
    totalAscent: ride.elevationGainM,
  } as FitMesg);

  encoder.onMesg(Profile.MesgNum.SESSION, {
    event: "session",
    eventType: "stop",
    startTime: start,
    timestamp: end,
    sport: "cycling",
    subSport:
      ride.sportType === "enduro" || ride.sportType === "all_mountain"
        ? "mountain"
        : "generic",
    totalElapsedTime: ride.durationSec,
    totalTimerTime: ride.durationSec,
    totalDistance: ride.distanceM,
    totalAscent: ride.elevationGainM,
  } as FitMesg);

  encoder.onMesg(Profile.MesgNum.ACTIVITY, {
    timestamp: end,
    totalTimerTime: ride.durationSec,
    numSessions: 1,
    type: "manual",
    event: "activity",
    eventType: "stop",
  } as FitMesg);

  return encoder.close();
}

export function downloadFit(filename: string, bytes: Uint8Array) {
  if (typeof window === "undefined") return;
  const copy = new Uint8Array(bytes);
  const blob = new Blob([copy], { type: "application/octet-stream" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
