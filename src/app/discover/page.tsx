"use client";

import { useMemo, useState } from "react";
import { Compass, Mountain, Route } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { suggestRoutes } from "@/lib/routing/suggestions";
import { estimateRange } from "@/lib/ebike/range";
import { bikeCategoryLabel } from "@/lib/catalog/slots";

export default function DiscoverPage() {
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const boschLive = useAppStore((s) => s.boschLive);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const rangePro = canUseProFeature("range");
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [minutes, setMinutes] = useState(150);

  const range = useMemo(() => {
    if (!activeBike?.isEbike || !rangePro) return undefined;
    return estimateRange({
      bike: activeBike,
      profile,
      calibration: calibration ?? undefined,
      socPercent: boschLive?.soc ?? 87,
    });
  }, [activeBike, profile, calibration, boschLive, rangePro]);

  const routes = useMemo(() => {
    if (!activeBike) return [];
    return suggestRoutes({
      bike: activeBike,
      profile,
      availableMinutes: minutes,
      rangeKmHigh: range?.kmHigh,
    });
  }, [activeBike, profile, minutes, range]);

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Discover</h1>
        <p className="text-sm text-text-secondary">
          Routenvorschläge mit 3 Begründungsfaktoren (F-NAV-004)
        </p>
      </header>

      {activeBike && (
        <div className="rounded-xl bg-primary/20 px-3 py-2 text-sm">
          <span className="text-text-secondary">Aktuelles Bike: </span>
          <span className="font-medium">{activeBike.name}</span>
          <span className="text-text-secondary">
            {" "}
            · {bikeCategoryLabel(activeBike.category)}
          </span>
        </div>
      )}

      <label className="text-sm">
        Verfügbare Zeit: {minutes} min
        <input
          type="range"
          min={45}
          max={300}
          step={15}
          value={minutes}
          onChange={(e) => setMinutes(Number(e.target.value))}
          className="mt-1 w-full"
        />
      </label>

      {activeBike?.isEbike && !rangePro && (
        <div className="rounded-xl border border-warning/40 bg-warning/10 p-3 text-sm">
          <div className="font-medium">Reichweitenprognose · Pro</div>
          <p className="mt-1 text-xs text-text-secondary">
            Physik + Selbstkalibrierung (F-EBK-004) ist Pro laut Spec 1.4.
            Unter Profil freischalten.
          </p>
        </div>
      )}

      {range && (
        <div className="rounded-xl border border-primary/30 bg-primary/10 p-3 text-sm">
          <div className="font-medium text-accent">
            Reichweite {range.kmLow}–{range.kmHigh} km
          </div>
          <p className="mt-1 text-xs text-text-secondary">
            {range.whPerKmLow}–{range.whPerKmHigh} Wh/km · Konfidenz{" "}
            {range.confidence}
            {range.calibrated ? " · kalibriert" : " · Basismodell"}
          </p>
          <ul className="mt-1 list-disc pl-4 text-[11px] text-text-secondary">
            {range.factors.map((f) => (
              <li key={f}>{f}</li>
            ))}
          </ul>
        </div>
      )}

      <div className="flex flex-col gap-3">
        {routes.map((r) => (
          <article
            key={r.id}
            className="rounded-2xl border border-border bg-surface p-4"
          >
            <div className="flex items-start justify-between gap-2">
              <div>
                <h3 className="font-semibold">{r.name}</h3>
                <p className="text-xs text-text-secondary">
                  {r.distanceKm} km · {r.elevationM} hm · {r.durationMin} min ·{" "}
                  {r.mtbScale}
                </p>
              </div>
              <div className="rounded-full bg-accent/20 px-2 py-1 text-xs font-bold text-accent">
                {r.matchScore}%
              </div>
            </div>
            <div className="mt-2 flex flex-wrap gap-2 text-[11px]">
              <span className="inline-flex items-center gap-1 rounded-md bg-surface-elevated px-2 py-0.5">
                <Route className="h-3 w-3" />
                {r.loop ? "Rundkurs" : "A→B"}
              </span>
              <span className="inline-flex items-center gap-1 rounded-md bg-surface-elevated px-2 py-0.5">
                <Mountain className="h-3 w-3" />
                {r.surface}
              </span>
              <span className="rounded-md bg-surface-elevated px-2 py-0.5">
                Unsicher {r.uncertainKmPct}%
              </span>
            </div>
            <ol className="mt-3 list-decimal space-y-1 pl-4 text-xs text-text-secondary">
              {r.reasons.map((reason) => (
                <li key={reason}>{reason}</li>
              ))}
            </ol>
            {r.rangeNote && (
              <p className="mt-2 text-xs text-warning">{r.rangeNote}</p>
            )}
          </article>
        ))}
        {!activeBike && (
          <p className="text-center text-sm text-text-secondary">
            Bitte zuerst ein Bike in der Garage anlegen.
          </p>
        )}
      </div>

      <p className="flex items-center justify-center gap-2 text-xs text-text-secondary">
        <Compass className="h-3.5 w-3.5" />
        OSM-Unsicherheit ausgewiesen · kein optimistisches Routing
      </p>
    </div>
  );
}
