import type { Ride } from "@/types";
import { lastRideForBike } from "@/lib/maintenance/summary";
import { honestClimbM } from "@/lib/ride/rideTelemetry";

/** Hero-Zeile: nur echte Fahrten, keine erfundenen Kilometer. */
export function lastRideHeroLine(ride: Ride | undefined): string | null {
  if (!ride) return null;
  const km = ride.distanceM / 1000;
  if (Number.isFinite(km) && km >= 0.05) {
    const climb = honestClimbM(ride.track, ride.elevationGainM);
    const hm = climb >= 10 ? ` · ${climb} hm` : "";
    return `Zuletzt ${km.toFixed(1)} km${hm}`;
  }
  return "Zuletzt unterwegs — ohne GPS-Strecke";
}

export function lastRideHeroLineForBike(
  rides: Ride[],
  bikeId: string
): string | null {
  const ended = rides.filter((r) => Boolean(r.endTime));
  return lastRideHeroLine(lastRideForBike(ended, bikeId));
}
