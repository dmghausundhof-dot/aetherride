"use client";

import { lastRideForBike } from "@/lib/maintenance/summary";
import { useAppStore } from "@/store/useAppStore";

export function BikeRideLog({ bikeId }: { bikeId: string }) {
  const rides = useAppStore((s) => s.rides);
  const onBike = rides.filter((r) => r.bikeId === bikeId).slice(0, 5);
  if (onBike.length === 0) return null;
  const last = lastRideForBike(rides, bikeId);
  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="text-sm font-semibold">Letzte Runden mit diesem Rad</h3>
      <p className="mt-0.5 text-xs text-text-secondary">
        Echte Fahrten — keine erfundenen Kilometer.
        {last
          ? ` Zuletzt ${(last.distanceM / 1000).toFixed(1)} km.`
          : ""}
      </p>
      <ul className="mt-3 space-y-2">
        {onBike.map((r) => (
          <li key={r.id} className="text-sm">
            <span className="tabular-nums">
              {(r.distanceM / 1000).toFixed(1)} km ·{" "}
              {(r.durationSec / 60).toFixed(0)} min
            </span>
            {r.notes ? (
              <span className="ml-2 text-text-secondary">{r.notes}</span>
            ) : null}
          </li>
        ))}
      </ul>
    </section>
  );
}
