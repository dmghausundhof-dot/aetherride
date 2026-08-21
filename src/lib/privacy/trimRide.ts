import type { Ride } from "@/types";
import { trimTrackForHeatmap } from "@/lib/routing/heatmaps";
import type { PrivacyZone } from "./consents";

/** Export/Strava: same end-cap + zone cut as heatmap. Empty stays empty.
 * Höhe, Zeit und Sensorfelder bleiben auf den behaltenen Punkten. */
export function rideWithTrimmedTrack(
  ride: Ride,
  zones: PrivacyZone[],
  trimEndsM = 200
): Ride {
  if (!ride.track || ride.track.length < 3) return ride;
  return {
    ...ride,
    track: trimTrackForHeatmap(ride.track, zones, trimEndsM),
  };
}
