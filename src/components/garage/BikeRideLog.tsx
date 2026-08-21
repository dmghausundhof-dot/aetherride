"use client";

import Link from "next/link";
import { lastRideForBike } from "@/lib/maintenance/summary";
import { MappeGlyph } from "@/components/tours/MappeGlyph";
import { useAppStore } from "@/store/useAppStore";
import { buildRideTelemetry } from "@/lib/ride/rideTelemetry";
import { RideTerrainPeek } from "@/components/ride/ActivitySparkline";
import { terrainCaption } from "@/lib/ride/terrainCaption";
import { rideTelemetryCopy } from "@/lib/i18n/rideTelemetryCopy";
import { useChromeLang } from "@/hooks/useChromeLang";

export function BikeRideLog({
  bikeId,
  omitLatestPeek = false,
}: {
  bikeId: string;
  /** Die Box zeigt die letzte Fahrt schon als Peek — nicht nochmal. */
  omitLatestPeek?: boolean;
}) {
  const telCopy = rideTelemetryCopy(useChromeLang());
  const rides = useAppStore((s) => s.rides);
  const ended = rides
    .filter((r) => r.bikeId === bikeId && Boolean(r.endTime))
    .sort(
      (a, b) =>
        new Date(b.startTime).getTime() - new Date(a.startTime).getTime()
    );
  const skipFirst =
    omitLatestPeek &&
    ended[0] &&
    buildRideTelemetry(ended[0].track).channels.elev;
  const onBike = ended.slice(skipFirst ? 1 : 0, skipFirst ? 6 : 5);
  if (onBike.length === 0) return null;
  const last = lastRideForBike(ended, bikeId);
  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="mb-0.5 flex items-center gap-2 text-sm font-semibold tracking-wide">
        <MappeGlyph name="ride" size={16} />
        {telCopy.lastRounds}
      </h3>
      <p className="mt-0.5 text-xs text-text-secondary">
        {telCopy.lastRoundsHint}
        {last
          ? ` ${telCopy.lastAgo} ${(last.distanceM / 1000).toFixed(1)} ${telCopy.km}.`
          : ""}
      </p>
      <ul className="mt-3 space-y-3">
        {onBike.map((r) => {
          const tel = buildRideTelemetry(r.track);
          return (
            <li key={r.id}>
              <Link
                href={`/activities/${r.id}`}
                className="block rounded-xl border border-border/60 px-3 py-2 hover:border-chrome/40"
              >
                <div className="flex items-baseline justify-between gap-2 text-sm">
                  <span className="tabular-nums">
                    {(r.distanceM / 1000).toFixed(1)} {telCopy.km} ·{" "}
                    {(r.durationSec / 60).toFixed(0)} {telCopy.min}
                    {tel.channels.elev ? ` · ${tel.climbM} ${telCopy.hm}` : ""}
                  </span>
                  {r.notes ? (
                    <span className="truncate text-xs text-text-secondary">
                      {r.notes}
                    </span>
                  ) : null}
                </div>
                <RideTerrainPeek
                  telemetry={tel}
                  caption={terrainCaption(tel, telCopy.hm)}
                  className="mt-2"
                />
              </Link>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
