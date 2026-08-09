/**
 * F-ACC-003 Datenexport — GPX je Ride + JSON-Vollexport (DSGVO Art. 20)
 */

import type { Bike, Ride, RiderProfile, Setup } from "@/types";

/** Enough GPS points for an honest track export / Strava upload. */
export function rideHasExportableTrack(ride: Ride): boolean {
  return Boolean(ride.track && ride.track.length >= 2);
}

/**
 * GPX for a ride. Empty track → valid GPX with empty `<trkseg>`
 * (no synthetic Berchtesgaden path).
 */
export function rideToGpx(ride: Ride, bikeName?: string): string {
  const name = `AetherRide ${new Date(ride.startTime).toISOString().slice(0, 10)}`;
  const pts = ride.track && ride.track.length > 0 ? ride.track : [];

  const trkpts = pts
    .map((p, i) => {
      if (
        !Number.isFinite(p.lat) ||
        !Number.isFinite(p.lng) ||
        (Math.abs(p.lat) < 1e-6 && Math.abs(p.lng) < 1e-6)
      ) {
        return null;
      }
      const t =
        typeof p.time === "number"
          ? new Date(new Date(ride.startTime).getTime() + p.time * 1000)
          : new Date(
              new Date(ride.startTime).getTime() +
                (i * ride.durationSec * 1000) / Math.max(1, pts.length - 1)
            );
      return `      <trkpt lat="${p.lat}" lon="${p.lng}">${
        p.elev != null ? `\n        <ele>${p.elev}</ele>` : ""
      }\n        <time>${t.toISOString()}</time>\n      </trkpt>`;
    })
    .filter(Boolean)
    .join("\n");

  const emptyNote = pts.length === 0 ? " · kein GPS-Track" : "";

  return `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="AetherRide" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata>
    <name>${escapeXml(name)}</name>
    <desc>${escapeXml(bikeName || "Ride")} · ${ride.distanceM} m · ${ride.elevationGainM} hm${emptyNote}</desc>
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
