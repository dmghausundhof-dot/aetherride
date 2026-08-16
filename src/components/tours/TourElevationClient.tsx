"use client";

import { useEffect, useMemo, useState } from "react";
import { ElevationChart } from "@/components/discover/ElevationChart";
import { buildElevationForSuggestion } from "@/lib/routing/suggestionElevation";
import type { ElevationProfile } from "@/lib/routing/elevationProfile";
import type { PublicTour } from "@/lib/catalog/publicTours";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";

/**
 * Höhenprofil: zuerst synthetisch aus Metadaten, optional API-Anreicherung
 * um den Tour-Pin (kein Fake-Track in Production).
 */
export function TourElevationClient({ tour }: { tour: PublicTour }) {
  const e = catalogCopy(useChromeLang()).elevation;
  const synthetic = useMemo(
    () =>
      buildElevationForSuggestion({
        id: tour.id,
        distanceKm: tour.distanceKm,
        elevationM: tour.elevationM,
        mtbScale: tour.difficulty,
        surface: tour.surface,
      }),
    [tour]
  );
  const [elev, setElev] = useState<ElevationProfile>(synthetic);
  const [source, setSource] = useState<"meta" | "api">("meta");

  useEffect(() => {
    setElev(synthetic);
    setSource("meta");
    // Optional: Punkt-Elevation am Zentrum (kein erfundenes LineString)
    const [lng, lat] = tour.center;
    const offsets = [
      { lat, lng },
      { lat: lat + 0.02, lng: lng + 0.01 },
      { lat: lat - 0.01, lng: lng + 0.025 },
      { lat: lat + 0.015, lng: lng - 0.02 },
      { lat, lng },
    ];
    let cancelled = false;
    void fetch("/api/elevation", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ locations: offsets }),
    })
      .then(async (r) => {
        if (!r.ok || cancelled) return;
        const j = await r.json();
        if (j?.points?.length >= 2 && !cancelled) {
          setElev(j as ElevationProfile);
          setSource("api");
        }
      })
      .catch(() => {
        /* keep synthetic */
      });
    return () => {
      cancelled = true;
    };
  }, [tour, synthetic]);

  return (
    <div className="rounded-2xl border border-border bg-surface p-4">
      <div className="mb-2 flex items-center justify-between gap-2">
        <h2 className="text-sm font-semibold">{e.title}</h2>
        <span className="text-[10px] text-text-secondary">
          {source === "api" ? e.apiSample : e.fromMeta}
        </span>
      </div>
      <ElevationChart elev={elev} />
      <p className="mt-2 text-[11px] text-text-secondary">
        {source === "api" ? e.noteApi : e.noteMeta}
      </p>
      <p className="mt-1 text-xs tabular-nums text-text-secondary">
        ~{tour.elevationM} hm · {tour.distanceKm} km
      </p>
    </div>
  );
}
