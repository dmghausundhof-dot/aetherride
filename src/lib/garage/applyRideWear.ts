/**
 * Echte Ride-Distanz/Dauer aufs Rad. Keine erfundenen km.
 * Komponenten-Verschleiß bleibt Snapshot-Differenz (odo − Einbau).
 */

import type { Bike, BikeComponent } from "@/types/garage";

export function honestRideDistanceM(input: {
  recordedM?: number | null;
  trackM?: number | null;
}): number {
  const recorded =
    typeof input.recordedM === "number" && Number.isFinite(input.recordedM)
      ? Math.max(0, input.recordedM)
      : 0;
  const track =
    typeof input.trackM === "number" && Number.isFinite(input.trackM)
      ? Math.max(0, input.trackM)
      : 0;
  return Math.round(Math.max(recorded, track));
}

export function honestRideHours(durationSec: number | null | undefined): number {
  if (typeof durationSec !== "number" || !Number.isFinite(durationSec)) return 0;
  return Math.max(0, durationSec) / 3600;
}

/** Nur zuordnen wenn ein echtes Rad und messbare Distanz oder Dauer da ist. */
export function shouldAssignRideWear(input: {
  bikeId?: string | null;
  distanceM: number;
  durationSec: number;
}): boolean {
  const id = input.bikeId?.trim();
  if (!id || id === "unknown") return false;
  return input.distanceM > 0 || input.durationSec > 0;
}

export function applyRideWearToBike(
  bike: Bike,
  ride: { distanceM: number; durationSec: number }
): Bike {
  if (!shouldAssignRideWear({ bikeId: bike.id, ...ride })) return bike;
  const km = Math.max(0, ride.distanceM / 1000);
  const hours = honestRideHours(ride.durationSec);
  if (km <= 0 && hours <= 0) return bike;
  return {
    ...bike,
    totalOdometerKm: bike.totalOdometerKm + km,
    totalHours: bike.totalHours + hours,
    updatedAt: new Date().toISOString(),
  };
}

export function componentWearSinceInstall(
  bike: Bike,
  comp: BikeComponent
): { km: number; hours: number } {
  return {
    km: Math.max(0, bike.totalOdometerKm - (comp.odometerKmAtInstall ?? 0)),
    hours: Math.max(0, bike.totalHours - (comp.hoursAtInstall ?? 0)),
  };
}
