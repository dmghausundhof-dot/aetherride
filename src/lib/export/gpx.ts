/**
 * F-ACC-003 Datenexport — GPX je Ride + JSON-Vollexport (DSGVO Art. 20)
 */

import type { Bike, Ride, RiderProfile, Setup } from "@/types";
import { trackPointEpochMs } from "@/lib/geo/trackPointTime";
import { honestClimbM } from "@/lib/ride/rideTelemetry";

/** Enough GPS points for an honest track export / Strava upload. */
export function rideHasExportableTrack(ride: Ride): boolean {
  return Boolean(ride.track && ride.track.length >= 2);
}

/**
 * GPX for a ride. Empty track → valid GPX with empty `<trkseg>`
 * (no synthetic Berchtesgaden path).
 */
export function rideToGpx(ride: Ride, bikeName?: string): string {
  const name = `FlowLine ${new Date(ride.startTime).toISOString().slice(0, 10)}`;
  const pts = ride.track && ride.track.length > 0 ? ride.track : [];
  const startMs = new Date(ride.startTime).getTime();

  const trkpts = pts
    .map((p, i) => {
      if (
        !Number.isFinite(p.lat) ||
        !Number.isFinite(p.lng) ||
        (Math.abs(p.lat) < 1e-6 && Math.abs(p.lng) < 1e-6)
      ) {
        return null;
      }
      const t = new Date(
        trackPointEpochMs(p.time, startMs, i, ride.durationSec, pts.length)
      );
      return `      <trkpt lat="${p.lat}" lon="${p.lng}">${
        p.elev != null ? `\n        <ele>${p.elev}</ele>` : ""
      }\n        <time>${t.toISOString()}</time>${gpxPointExtensions(p)}\n      </trkpt>`;
    })
    .filter(Boolean)
    .join("\n");

  const emptyNote = pts.length === 0 ? " · kein GPS-Track" : "";

  return `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="FlowLine" xmlns="http://www.topografix.com/GPX/1/1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" xmlns:gpxpx="http://www.garmin.com/xmlschemas/PowerExtension/v1">
  <metadata>
    <name>${escapeXml(name)}</name>
    <desc>${escapeXml(bikeName || "Ride")} · ${ride.distanceM} m · ${honestClimbM(ride.track, ride.elevationGainM)} hm${emptyNote}</desc>
    <time>${ride.startTime}</time>
  </metadata>
  <trk>
    <name>${escapeXml(name)}</name>
    <type>${ride.sportType}</type>
    <trkseg>
${trkpts}
    </trkseg>
  </trk>
</gpx>`;
}

function liveHr(p: { hr?: number; heartRateBpm?: number }): number | null {
  const v = p.hr ?? p.heartRateBpm;
  if (typeof v !== "number" || v < 1 || v > 239) return null;
  return Math.round(v);
}

function liveCad(p: { cad?: number; cadenceRpm?: number }): number | null {
  const v = p.cad ?? p.cadenceRpm;
  if (typeof v !== "number" || v < 1 || v > 254) return null;
  return Math.round(v);
}

function livePower(p: { power?: number; powerW?: number }): number | null {
  const v = p.power ?? p.powerW;
  if (typeof v !== "number" || v < 1 || v > 2500) return null;
  return Math.round(v);
}

function gpxPointExtensions(p: {
  hr?: number;
  cad?: number;
  power?: number;
  heartRateBpm?: number;
  cadenceRpm?: number;
  powerW?: number;
}): string {
  const hr = liveHr(p);
  const cad = liveCad(p);
  const power = livePower(p);
  if (hr == null && cad == null && power == null) return "";
  let inner = "\n        <extensions>";
  if (hr != null || cad != null) {
    inner += "\n          <gpxtpx:TrackPointExtension>";
    if (hr != null) inner += `\n            <gpxtpx:hr>${hr}</gpxtpx:hr>`;
    if (cad != null) inner += `\n            <gpxtpx:cad>${cad}</gpxtpx:cad>`;
    inner += "\n          </gpxtpx:TrackPointExtension>";
  }
  if (power != null) {
    inner +=
      `\n          <gpxpx:PowerExtension>\n            <gpxpx:PowerInWatts>${power}</gpxpx:PowerInWatts>\n          </gpxpx:PowerExtension>`;
  }
  inner += "\n        </extensions>";
  return inner;
}

function escapeXml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function fullJsonExport(input: {
  bikes: Bike[];
  rides: Ride[];
  profile: RiderProfile;
  setups?: Setup[];
}): string {
  return JSON.stringify(
    {
      exportedAt: new Date().toISOString(),
      format: "aetherride-portable-v1",
      legal: "DSGVO Art. 20 Datenportabilität",
      riderProfile: input.profile,
      bikes: input.bikes,
      rides: input.rides.map((r) => ({
        ...r,
        elevationGainM: honestClimbM(r.track, r.elevationGainM),
        // privacy: track optional
      })),
    },
    null,
    2
  );
}

/** Strava-ähnlicher Activity-Payload (Export-Stub, kein OAuth) */
export function rideToStravaActivityStub(ride: Ride): object {
  return {
    name: `FlowLine ${new Date(ride.startTime).toLocaleDateString("de-DE")}`,
    type: "Ride",
    sport_type:
      ride.sportType === "enduro" || ride.sportType === "all_mountain"
        ? "MountainBikeRide"
        : "Ride",
    start_date_local: ride.startTime,
    elapsed_time: ride.durationSec,
    distance: ride.distanceM,
    total_elevation_gain: honestClimbM(ride.track, ride.elevationGainM),
    description:
      "Exportiert aus FlowLine — Strava API OAuth in Produktion (Spec 8.6 P1).",
    _note: "Demo-Stub ohne Netzwerkaufruf. Markenrichtlinien Strava beachten.",
  };
}

export function downloadText(filename: string, content: string, mime: string) {
  if (typeof window === "undefined") return;
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
