"use client";

import { useEffect, useMemo, useState } from "react";
import {
  ArrowLeft,
  Bookmark,
  BookmarkCheck,
  Camera,
  Flame,
  Mountain,
  Play,
  AreaChart,
} from "lucide-react";
import Link from "next/link";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import { buildElevationForSuggestion } from "@/lib/routing/suggestionElevation";
import { buildDemoGeometry, centerOfGeometry } from "@/lib/routing/demoGeometry";
import { buildHeatmap } from "@/lib/routing/heatmaps";
import {
  getTrailViewNear,
  type TrailViewResult,
} from "@/lib/routing/trailView";
import { MapView } from "@/components/MapView";
import { ElevationChart } from "@/components/discover/ElevationChart";
import { EvidenceSheet } from "@/components/EvidenceSheet";
import type { RangeEstimate } from "@/lib/ebike/range";

type DetailLayer = "overview" | "heat" | "trail" | "elevation";

export function RouteDetail({
  route,
  saved,
  range,
  rangePro,
  isEbike,
  heatmapConsent,
  rides,
  privacyZones,
  onBack,
  onStart,
  onToggleSave,
}: {
  route: RouteSuggestion;
  saved: boolean;
  range?: RangeEstimate;
  rangePro: boolean;
  isEbike: boolean;
  heatmapConsent: boolean;
  rides: { id: string; track?: { lat: number; lng: number }[] }[];
  privacyZones: { lat: number; lng: number; radiusM: number }[];
  onBack: () => void;
  onStart: () => void;
  onToggleSave: () => void;
}) {
  const [layer, setLayer] = useState<DetailLayer>("overview");
  const [photoIdx, setPhotoIdx] = useState(0);
  const [trail, setTrail] = useState<TrailViewResult | null>(null);

  const geometry = useMemo(
    () => buildDemoGeometry(route.id, route.distanceKm),
    [route.id, route.distanceKm]
  );
  const center = centerOfGeometry(geometry);
  const elev = useMemo(() => buildElevationForSuggestion(route), [route]);

  const heatmap = useMemo(
    () =>
      buildHeatmap({
        consentHeatmap: heatmapConsent,
        rides,
        privacyZones,
        includeSeedFallback: false,
      }),
    [heatmapConsent, rides, privacyZones]
  );

  useEffect(() => {
    let cancelled = false;
    const [lng, lat] = center;
    void fetch(`/api/trail?lat=${lat}&lng=${lng}`)
      .then((r) => r.json())
      .then((data: TrailViewResult) => {
        if (!cancelled && data?.photos) setTrail(data);
      })
      .catch(() => {
        if (!cancelled) setTrail(getTrailViewNear(lat, lng));
      });
    return () => {
      cancelled = true;
    };
  }, [center]);

  const photo = trail?.photos[photoIdx];
  const rangeTight =
    isEbike &&
    range &&
    route.distanceKm > range.kmHigh * 0.85;

  return (
    <div className="flex flex-col gap-4">
      <button
        type="button"
        onClick={onBack}
        className="inline-flex items-center gap-1 text-sm text-text-secondary"
      >
        <ArrowLeft className="h-4 w-4" /> Zurück
      </button>

      <header>
        <h2 className="text-xl font-bold">{route.name}</h2>
        <p className="mt-1 text-sm tabular-nums text-text-secondary">
          {route.distanceKm} km · {route.elevationM} hm · {route.durationMin} min
          {route.mtbScale !== "—" ? ` · ${route.mtbScale}` : ""} ·{" "}
          {route.loop ? "Rundkurs" : "A→B"}
        </p>
        <div className="mt-2 inline-flex rounded-full bg-accent/20 px-2.5 py-1 text-xs font-bold text-accent">
          {route.matchScore}% Match
        </div>
      </header>

      <div className="grid grid-cols-4 gap-1 rounded-xl bg-surface-elevated p-1 text-[10px]">
        {(
          [
            ["overview", "Überblick", Mountain],
            ["heat", "Beliebt", Flame],
            ["trail", "Fotos", Camera],
            ["elevation", "Höhe", AreaChart],
          ] as const
        ).map(([id, label, Icon]) => (
          <button
            key={id}
            type="button"
            onClick={() => setLayer(id)}
            className={`flex flex-col items-center gap-0.5 rounded-lg py-2 font-medium ${
              layer === id ? "bg-accent text-white" : "text-text-secondary"
            }`}
          >
            <Icon className="h-3.5 w-3.5" />
            {label}
          </button>
        ))}
      </div>

      {layer === "overview" && (
        <div className="flex flex-col gap-3">
          <MapView
            className="aspect-[4/3] w-full overflow-hidden rounded-2xl"
            center={center}
            zoom={12}
            route={geometry}
          />
          <EvidenceSheet title="Warum dieser Vorschlag?">
            <ol className="list-decimal space-y-1 pl-4 text-sm">
              {route.reasons.map((r) => (
                <li key={r}>{r}</li>
              ))}
            </ol>
          </EvidenceSheet>
          {isEbike && (
            <div
              className={`rounded-xl border p-3 text-sm ${
                rangeTight
                  ? "border-warning/40 bg-warning/10"
                  : "border-primary/30 bg-primary/10"
              }`}
            >
              {rangePro && range ? (
                <>
                  <div className="font-medium">
                    Reichweite {range.kmLow}–{range.kmHigh} km
                    {rangeTight ? " — eng für diese Tour" : " — passt"}
                  </div>
                  <p className="mt-1 text-xs text-text-secondary">
                    Tour {route.distanceKm} km · {range.confidence} Konfidenz
                  </p>
                </>
              ) : (
                <>
                  <div className="font-medium">Reichweitenprognose · Pro</div>
                  <p className="mt-1 text-xs text-text-secondary">
                    Zeigt die Spanne gegen die Touranforderung.
                  </p>
                </>
              )}
              {route.rangeNote && (
                <p className="mt-2 text-xs text-warning">{route.rangeNote}</p>
              )}
            </div>
          )}
          <p className="text-[11px] text-text-secondary">
            Offline-Paket ca.{" "}
            {Math.max(8, Math.round(route.distanceKm * 0.35))} MB (Schätzung)
          </p>
        </div>
      )}

      {layer === "heat" && (
        <div className="flex flex-col gap-3">
          <p className="text-xs text-text-secondary">{heatmap.disclaimer}</p>
          {heatmap.coldStart && (
            <p className="text-xs text-warning">
              Noch wenig Daten in der Region — Beliebtheit wird mit mehr Rides
              genauer.
            </p>
          )}
          {!heatmapConsent && (
            <p className="text-xs">
              Beitrag unter{" "}
              <Link href="/privacy" className="text-accent">
                Privatsphäre
              </Link>{" "}
              aktivieren.
            </p>
          )}
          <MapView
            className="aspect-[4/3] w-full overflow-hidden rounded-2xl"
            center={center}
            zoom={12}
            track={heatmap.segments
              .filter((s) => s.visible)
              .flatMap((s) =>
                s.coordinates.map(([lng, lat]) => ({ lat, lng }))
              )}
          />
          <ul className="space-y-2 text-xs">
            {heatmap.segments
              .filter((s) => s.visible)
              .slice(0, 6)
              .map((s) => (
                <li
                  key={s.id}
                  className="rounded-xl border border-accent/30 bg-accent/5 px-3 py-2"
                >
                  Beliebter Abschnitt · {s.uniqueUsers} Fahrer · Intensität{" "}
                  {(s.intensity * 100).toFixed(0)} %
                </li>
              ))}
          </ul>
        </div>
      )}

      {layer === "trail" && (
        <div className="flex flex-col gap-3">
          {photo ? (
            <>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={photo.imageUrl}
                alt={photo.title}
                className="aspect-video w-full rounded-2xl object-cover"
              />
              <div className="text-sm">
                <div className="font-semibold">{photo.title}</div>
                <p className="text-xs text-text-secondary">
                  Blickrichtung {photo.headingDeg}°
                </p>
              </div>
              <div className="flex gap-2">
                {(trail?.photos ?? []).map((p, i) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => setPhotoIdx(i)}
                    className={`rounded-lg px-3 py-1 text-xs ${
                      i === photoIdx
                        ? "bg-accent text-white"
                        : "bg-surface-elevated"
                    }`}
                  >
                    {i + 1}
                  </button>
                ))}
              </div>
              {trail?.usingDemo && (
                <p className="text-[11px] text-text-secondary">
                  Beispielbilder — Live-Trail-Fotos folgen mit Standortfreigabe.
                </p>
              )}
            </>
          ) : (
            <p className="text-sm text-text-secondary">
              Keine Trail-Fotos in der Nähe.
            </p>
          )}
        </div>
      )}

      {layer === "elevation" && <ElevationChart elev={elev} />}

      <div className="flex gap-2 pb-2">
        <button
          type="button"
          onClick={onToggleSave}
          className="inline-flex items-center justify-center gap-1.5 rounded-xl border border-border px-3 py-3 text-sm"
        >
          {saved ? (
            <BookmarkCheck className="h-4 w-4 text-accent" />
          ) : (
            <Bookmark className="h-4 w-4" />
          )}
          {saved ? "Gespeichert" : "Speichern"}
        </button>
        <button
          type="button"
          onClick={onStart}
          className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-white"
        >
          <Play className="h-4 w-4 fill-current" /> Losfahren
        </button>
      </div>
    </div>
  );
}
