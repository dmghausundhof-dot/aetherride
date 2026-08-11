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
import { demoCenterLngLat } from "@/lib/routing/demoGeometry";
import {
  buildHeatmap,
  type HeatmapResult,
} from "@/lib/routing/heatmaps";
import {
  bboxAround,
  fetchCommunityHeatmap,
} from "@/lib/heatmap/client";
import {
  getTrailViewNear,
  type TrailViewResult,
} from "@/lib/routing/trailView";
import { MapView, type MapRouteLayer } from "@/components/MapView";
import { ElevationChart } from "@/components/discover/ElevationChart";
import { EvidenceSheet } from "@/components/EvidenceSheet";
import type { RangeEstimate } from "@/lib/ebike/range";

type DetailLayer = "overview" | "heat" | "trail" | "elevation";

function heatSegmentsToRoutes(
  segments: HeatmapResult["segments"]
): MapRouteLayer[] {
  return segments
    .filter((s) => s.visible && s.coordinates.length >= 2)
    .map((s) => ({
      id: s.id,
      role: "trail" as const,
      geometry: {
        type: "LineString" as const,
        coordinates: s.coordinates,
      },
      color: s.id.startsWith("cell-") ? "#E65100" : "#FF7043",
      width: 4 + s.intensity * 6,
      opacity: 0.35 + s.intensity * 0.4,
    }));
}

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
  onAdoptIntoPlan,
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
  onAdoptIntoPlan?: () => void;
}) {
  const [layer, setLayer] = useState<DetailLayer>("overview");
  const [photoIdx, setPhotoIdx] = useState(0);
  const [trail, setTrail] = useState<TrailViewResult | null>(null);
  const [community, setCommunity] = useState<HeatmapResult | null>(null);
  const [communityErr, setCommunityErr] = useState<string | null>(null);

  const center = useMemo(() => demoCenterLngLat(route.id), [route.id]);
  const elev = useMemo(() => buildElevationForSuggestion(route), [route]);

  const localHeat = useMemo(
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
    if (layer !== "heat") return;
    let cancelled = false;
    const [lng, lat] = center;
    setCommunityErr(null);
    void fetchCommunityHeatmap(bboxAround(lng, lat)).then((r) => {
      if (cancelled) return;
      if (r == null) {
        setCommunity(null);
        setCommunityErr("Community-Heatmap offline");
        return;
      }
      setCommunity(r);
    });
    return () => {
      cancelled = true;
    };
  }, [layer, center]);

  const mergedHeat = useMemo((): HeatmapResult => {
    const localVisible = localHeat.segments.filter((s) => s.visible);
    const communityVisible = community?.segments.filter((s) => s.visible) ?? [];
    const segments = [...localVisible, ...communityVisible];
    return {
      segments,
      coldStart:
        segments.length === 0 ||
        (localHeat.coldStart && (community?.coldStart ?? true)),
      kThreshold: community?.kThreshold ?? localHeat.kThreshold,
      attribution: [localHeat.attribution, community?.attribution]
        .filter(Boolean)
        .join(" · "),
      disclaimer: [
        localHeat.disclaimer,
        community?.disclaimer,
        communityErr,
      ]
        .filter(Boolean)
        .join(" · "),
    };
  }, [localHeat, community, communityErr]);

  const heatRoutes = useMemo(
    () => heatSegmentsToRoutes(mergedHeat.segments),
    [mergedHeat.segments]
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
        <p className="mt-1 text-xs text-text-secondary">
          Tour-Idee — Strecke beim Planen oder Starten live berechnen
        </p>
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
            markers={[
              {
                id: "idea",
                lngLat: center,
                color: "#78909C",
                label: "Idee",
              },
            ]}
          />
          <p className="text-[11px] text-text-secondary">
            Nur Ortspunkt — kein gespeicherter Track. Live-Routing, Planen oder
            GPX für eine echte Linie.
          </p>
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
            Offline-Pakete gibt es derzeit nur in der Mobile-App (API vorhanden,
            Web-Download noch nicht).
          </p>
        </div>
      )}

      {layer === "heat" && (
        <div className="flex flex-col gap-3">
          <p className="text-xs text-text-secondary">{mergedHeat.disclaimer}</p>
          {mergedHeat.coldStart && (
            <p className="text-xs text-warning">
              Noch wenig Community-Daten (k≥{mergedHeat.kThreshold}) — eigene
              Rides und mehr Fahrer füllen die Karte.
            </p>
          )}
          {!heatmapConsent && (
            <p className="text-xs">
              Eigene Beiträge unter{" "}
              <Link href="/privacy" className="text-accent">
                Privatsphäre
              </Link>{" "}
              aktivieren. Community-Segmente (k≥{mergedHeat.kThreshold}) sind
              trotzdem sichtbar, sobald genug Fahrer da sind.
            </p>
          )}
          <MapView
            className="aspect-[4/3] w-full overflow-hidden rounded-2xl"
            center={center}
            zoom={12}
            routes={heatRoutes}
            fitRoute={heatRoutes.length > 0}
          />
          <ul className="space-y-2 text-xs">
            {mergedHeat.segments
              .filter((s) => s.visible)
              .slice(0, 8)
              .map((s) => (
                <li
                  key={s.id}
                  className="rounded-xl border border-accent/30 bg-accent/5 px-3 py-2"
                >
                  {s.id.startsWith("cell-")
                    ? "Community"
                    : s.id.startsWith("ride-")
                      ? "Eigene Ride"
                      : "Abschnitt"}
                  {" · "}
                  {s.uniqueUsers} Fahrer · Intensität{" "}
                  {(s.intensity * 100).toFixed(0)} %
                </li>
              ))}
            {mergedHeat.segments.filter((s) => s.visible).length === 0 && (
              <li className="text-text-secondary">
                Keine sichtbaren Segmente in diesem Ausschnitt.
              </li>
            )}
          </ul>
          {mergedHeat.attribution ? (
            <p className="text-[10px] text-text-secondary">
              {mergedHeat.attribution}
            </p>
          ) : null}
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
                  Beispielbilder — Live-Fotos brauchen Mapillary-Zugang (Ops).
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

      <div className="flex flex-col gap-2 pb-2">
        {onAdoptIntoPlan && (
          <button
            type="button"
            onClick={onAdoptIntoPlan}
            className="rounded-xl border border-border py-2.5 text-sm font-medium"
          >
            In Planen
          </button>
        )}
        <div className="flex gap-2">
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
            <Play className="h-4 w-4 fill-current" /> In App starten
          </button>
        </div>
        <div className="mt-2 flex flex-wrap gap-2">
          <Link
            href={`/tours/${route.id}`}
            className="text-xs font-medium text-accent hover:underline"
          >
            Öffentliche Tour-Seite →
          </Link>
          <Link
            href={`/planner?tour=${encodeURIComponent(route.id)}`}
            className="text-xs font-medium text-accent hover:underline"
          >
            Im Planer öffnen →
          </Link>
        </div>
      </div>
    </div>
  );
}
