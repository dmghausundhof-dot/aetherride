import type { CompatibilityVerdict } from "@/types";

export function readinessLabel(
  status: "ready" | "attention" | "blocked"
): string {
  if (status === "ready") return "Bereit";
  if (status === "blocked") return "Gesperrt";
  return "Wartung";
}

export function readinessTone(
  status: "ready" | "attention" | "blocked"
): "success" | "warning" | "error" {
  if (status === "ready") return "success";
  if (status === "blocked") return "error";
  return "warning";
}

export function verdictSummaryDe(v: CompatibilityVerdict): string {
  switch (v) {
    case "COMPATIBLE":
      return "Kompatibel";
    case "CONDITIONAL":
      return "Bedingt kompatibel";
    case "INCOMPATIBLE":
      return "Inkompatibel";
    default:
      return "Daten fehlen";
  }
}

/** Wochen-km aus Ride-Liste (letzte 7 Tage) */
export function weeklyRideKm(
  rides: { startTime: string; distanceM: number; bikeId?: string }[],
  bikeId?: string
): number {
  const since = Date.now() - 7 * 24 * 60 * 60 * 1000;
  return rides
    .filter((r) => {
      if (bikeId && r.bikeId && r.bikeId !== bikeId) return false;
      return new Date(r.startTime).getTime() >= since;
    })
    .reduce((s, r) => s + r.distanceM / 1000, 0);
}
