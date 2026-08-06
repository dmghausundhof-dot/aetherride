/**
 * Ride-Zusammenfassung zum Teilen (WhatsApp/Clipboard) — ohne Paywall.
 */

import type { Ride } from "@/types";
import { formatDistance, formatDuration } from "@/lib/utils";

export function renderRideShareText(
  ride: Ride,
  bikeName?: string
): string {
  const lines = [
    `AetherRide · ${ride.plannedRouteName ?? "Ride"}`,
    bikeName ? `Bike: ${bikeName}` : null,
    `${formatDistance(ride.distanceM)} · ${formatDuration(ride.durationSec)} · ${ride.elevationGainM} hm`,
    `Flow ${ride.summaryMetrics.flowScore}`,
    ride.track && ride.track.length >= 2
      ? `Track: ${ride.track.length} Punkte (GPX in der App exportieren)`
      : "Kein GPS-Track",
    new Date(ride.startTime).toLocaleString("de-DE"),
  ].filter(Boolean);
  return lines.join("\n");
}

export async function copyRideShareText(
  ride: Ride,
  bikeName?: string
): Promise<boolean> {
  const text = renderRideShareText(ride, bikeName);
  try {
    if (typeof navigator !== "undefined" && navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch {
    /* fall through */
  }
  return false;
}
