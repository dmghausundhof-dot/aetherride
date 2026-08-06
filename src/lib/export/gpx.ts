/**
 * F-ACC-003 Datenexport — GPX je Ride + JSON-Vollexport (DSGVO Art. 20)
 */

import type { Bike, Ride, RiderProfile, Setup } from "@/types";

export function rideToGpx(ride: Ride, bikeName?: string): string {
  const name = `AetherRide ${new Date(ride.startTime).toISOString().slice(0, 10)}`;
  const pts =
    ride.track && ride.track.length > 0
      ? ride.track
      : synthesizeTrack(ride);

  const trkpts = pts
    .map(
      (p) =>
        `      <trkpt lat="${p.lat}" lon="${p.lng}">${
          p.elev != null ? `\n        <ele>${p.elev}</ele>` : ""
        }\n        <time>${new Date(
          typeof p.time === "number"
            ? ride.startTime
            : ride.startTime
        ).toISOString()}</time>\n      </trkpt>`
    )
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="AetherRide" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata>
    <name>${escapeXml(name)}</name>
    <desc>${escapeXml(bikeName || "Ride")} · ${ride.distanceM} m · ${ride.elevationGainM} hm</desc>
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

function synthesizeTrack(ride: Ride): { lat: number; lng: number; elev?: number; time: number }[] {
  const n = Math.max(10, Math.min(200, Math.round(ride.durationSec / 30)));
  const out = [];
  for (let i = 0; i < n; i++) {
    out.push({
      lat: 47.45 + Math.sin(i / 8) * 0.01,
      lng: 12.15 + i * 0.0002,
      elev: 800 + (ride.elevationGainM * i) / n,
      time: i,
    });
  }
  return out;
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
    name: `AetherRide ${new Date(ride.startTime).toLocaleDateString("de-DE")}`,
    type: "Ride",
    sport_type:
      ride.sportType === "enduro" || ride.sportType === "all_mountain"
        ? "MountainBikeRide"
        : "Ride",
    start_date_local: ride.startTime,
    elapsed_time: ride.durationSec,
    distance: ride.distanceM,
    total_elevation_gain: ride.elevationGainM,
    description:
      "Exportiert aus AetherRide — Strava API OAuth in Produktion (Spec 8.6 P1).",
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
