"use client";

import { useEffect, useMemo, useState } from "react";
import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import {
  formatDistanceElevation,
  sanitizeElevationM,
} from "@/lib/discover/elevationGuard";
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
import { MapView, type MapMarker, type MapRouteLayer } from "@/components/MapView";
import { mapPoiKindFromRaw, pinGlyphForCategory, poiPinSrc } from "@/lib/map/mapPinSvg";
import { MappeGlyph } from "@/components/tours/MappeGlyph";
import { placeTourPoiStops } from "@/lib/map/tourPoiStops";
import { ElevationChart } from "@/components/discover/ElevationChart";
import { EvidenceSheet } from "@/components/EvidenceSheet";
import { TourReviews } from "@/components/community/TourReviews";
import { TourCommunityChip } from "@/components/community/TourCommunityChip";
import { TourFunctionKit } from "@/components/tours/TourFunctionKit";
import { getPublicTour } from "@/lib/catalog/publicTours";
import type { RangeEstimate } from "@/lib/ebike/range";
import { useChromeLang } from "@/hooks/useChromeLang";
import { discoverStatus, discoverUi } from "@/lib/i18n/discoverUi";

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

function PoiTimelineIcon({ kind }: { kind: string }) {
  const src = poiPinSrc(mapPoiKindFromRaw(kind));
  return (
    <img
      src={src}
      alt=""
      width={16}
      height={20}
      className="h-5 w-4 object-contain"
      draggable={false}
    />
  );
}

export function RouteDetail({
  route,
  saved,
  range,
  rangePro,
  isEbike,
  heatmapConsent,
  highlightPoiId,
  rides,
  privacyZones,
  onBack,
  onStart,
  onToggleSave,
  onAdoptIntoPlan,
  hideMiniMap = false,
  geometry = null,
  onSelectPoi,
}: {
  route: RouteSuggestion;
  saved: boolean;
  range?: RangeEstimate;
  rangePro: boolean;
  isEbike: boolean;
  heatmapConsent: boolean;
  highlightPoiId?: string | null;
  rides: { id: string; track?: { lat: number; lng: number }[] }[];
  privacyZones: { lat: number; lng: number; radiusM: number }[];
  onBack: () => void;
  onStart: () => void;
  onToggleSave: () => void;
  onAdoptIntoPlan?: () => void;
  hideMiniMap?: boolean;
  geometry?: GeoJSON.LineString | null;
  onSelectPoi?: (id: string) => void;
}) {
  const lang = useChromeLang();
  const d = discoverUi(lang);
  const catalogTour = getPublicTour(route.id);
  const [layer, setLayer] = useState<DetailLayer>("overview");
  const [photoIdx, setPhotoIdx] = useState(0);
  const [trail, setTrail] = useState<TrailViewResult | null>(null);
  const [community, setCommunity] = useState<HeatmapResult | null>(null);
  const [communityErr, setCommunityErr] = useState<string | null>(null);

  useEffect(() => {
    if (!highlightPoiId) return;
    setLayer("overview");
    let cancelled = false;
    const tryScroll = (attempt: number) => {
      if (cancelled) return;
      const el = document.querySelector(
        `[data-poi-id="${CSS.escape(highlightPoiId)}"]`
      );
      if (el) {
        el.scrollIntoView({ behavior: "smooth", block: "nearest" });
        return;
      }
      if (attempt >= 8) return;
      requestAnimationFrame(() => tryScroll(attempt + 1));
    };
    tryScroll(0);
    return () => {
      cancelled = true;
    };
  }, [highlightPoiId]);

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
        setCommunityErr(d.heatmapOffline);
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

  const tourLine = useMemo((): MapRouteLayer[] => {
    if (!geometry?.coordinates || geometry.coordinates.length < 2) return [];
    return [{ id: "detail-tour", geometry, role: "tour" }];
  }, [geometry]);

  const poiMarkers = useMemo((): MapMarker[] => {
    const pins = placeTourPoiStops({
      stops: route.poiStops,
      durationMin: route.durationMin,
      geometry,
      zoom: 13,
      selectedId: highlightPoiId,
    });
    const out: MapMarker[] = pins.map((p) => ({
      id: `poi-${p.id}`,
      lngLat: p.lngLat,
      kind: "poi" as const,
      poiKind: p.poiKind,
      selected: p.selected,
      label: p.label,
    }));
    if (!geometry) {
      out.unshift({
        id: "idea",
        lngLat: center,
        color: "#5C6B73",
        kind: "tour",
        glyph: pinGlyphForCategory(route.category),
        label: d.pinIdea,
      });
    }
    return out;
  }, [route, geometry, highlightPoiId, center, d.pinIdea]);

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

  // List↔panel parity: same sanitize as RouteCard (omit 0 / absurd).
  const ascentDisplay = sanitizeElevationM(route.elevationM, route.distanceKm);

  return (
    <div className="flex flex-col gap-4">
      <button
        type="button"
        onClick={onBack}
        className="inline-flex items-center gap-1 text-sm text-text-secondary"
      >
        <ArrowLeft className="h-4 w-4" /> {d.back}
      </button>

      <header>
        <div className="flex flex-wrap items-center gap-2">
          <h2 className="text-xl font-bold">{route.name}</h2>
          <TourCommunityChip tourId={route.id} />
        </div>
        <p className="mt-1 text-xs text-text-secondary">
          {d.tourIdeaLive}
        </p>
        <p className="mt-1 text-sm tabular-nums text-text-secondary">
          {formatDistanceElevation(route.distanceKm, ascentDisplay)} ·{" "}
          {route.durationMin} min
          {route.mtbScale !== "—" ? ` · ${route.mtbScale}` : ""} ·{" "}
          {route.loop ? d.loopRound : d.pointAb}
        </p>
        <div className="mt-2 inline-flex rounded-full bg-accent/20 px-2.5 py-1 text-xs font-bold text-accent">
          {route.matchScore}% {d.match}
        </div>
      </header>

      <div className="grid grid-cols-4 gap-1 rounded-xl bg-surface-elevated p-1 text-[10px]">
        {(
          [
            ["overview", d.overview, "karte"],
            ["heat", d.popular, "heat"],
            ["trail", d.photos, "photo"],
            ["elevation", d.elevation, "elevation"],
          ] as const
        ).map(([id, label, mark]) => (
          <button
            key={id}
            type="button"
            onClick={() => setLayer(id)}
            className={`flex flex-col items-center gap-0.5 rounded-lg py-2 font-medium ${
              layer === id ? "bg-accent text-on-accent" : "text-text-secondary"
            }`}
          >
            <ChromeGlyph name={mark} size={14} current />
            {label}
          </button>
        ))}
      </div>

      {layer === "overview" && (
        <div className="flex flex-col gap-3">
          {!hideMiniMap && (
            <>
              <MapView
                className="aspect-[4/3] w-full overflow-hidden rounded-2xl"
                center={center}
                zoom={12}
                routes={tourLine}
                markers={poiMarkers}
                onMarkerClick={(id) => {
                  if (id.startsWith("poi-")) onSelectPoi?.(id.slice("poi-".length));
                }}
              />
              {!geometry && (
                <p className="text-[11px] text-text-secondary">
                  {d.pinOnlyHint}
                </p>
              )}
            </>
          )}
          {route.poiStops && route.poiStops.length > 0 && (
            <ol className="ml-1">
              {route.poiStops
                .filter((p) => p.atMin > 0)
                .slice(0, 8)
                .map((p, i, list) => {
                  const on = highlightPoiId === p.id;
                  const last = i === list.length - 1;
                  return (
                    <li key={p.id} className="flex gap-3">
                      <div className="flex w-8 shrink-0 flex-col items-center">
                        <span
                          className={`flex h-8 w-8 items-center justify-center rounded-full border-2 bg-[#F4F1EC] text-[#1A120C] ${
                            on ? "border-accent" : "border-chrome/50"
                          }`}
                          aria-hidden
                        >
                          <PoiTimelineIcon kind={p.kind} />
                        </span>
                        {!last && (
                          <span className="mt-0.5 w-0.5 flex-1 min-h-4 bg-border" />
                        )}
                      </div>
                      <button
                        type="button"
                        data-poi-id={p.id}
                        onClick={() => onSelectPoi?.(p.id)}
                        className={`mb-3 min-w-0 flex-1 rounded-xl px-2 py-1.5 text-left ${
                          on ? "bg-accent/10" : ""
                        }`}
                      >
                        <span className="block text-[11px] font-bold text-text-secondary">
                          {i + 1} · {p.atMin} min
                        </span>
                        <span className="block text-sm font-semibold">
                          {p.title}
                        </span>
                        {p.whyGood ? (
                          <span className="mt-0.5 block text-xs font-normal text-text-secondary">
                            {p.whyGood}
                          </span>
                        ) : null}
                      </button>
                    </li>
                  );
                })}
            </ol>
          )}
          <EvidenceSheet title={d.whySuggestion}>
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
                    {d.rangeSpan(range.kmLow, range.kmHigh)}
                    {rangeTight ? d.rangeTight : d.rangeOk}
                  </div>
                  <p className="mt-1 text-xs text-text-secondary">
                    {d.rangeTour(route.distanceKm, range.confidence)}
                  </p>
                </>
              ) : (
                <>
                  <div className="font-medium">{d.rangeProTitle}</div>
                  <p className="mt-1 text-xs text-text-secondary">
                    {d.rangeProBody}
                  </p>
                  <Link
                    href="/profile"
                    className="mt-2 inline-block text-xs font-semibold text-chrome hover:underline"
                  >
                    {d.unlockPro}
                  </Link>
                </>
              )}
              {route.rangeNote && (
                <p className="mt-2 text-xs text-warning">{route.rangeNote}</p>
              )}
            </div>
          )}
          <p className="text-[11px] text-text-secondary">
            {d.offlineMapsHint}
            <Link href="/library" className="text-chrome hover:underline">
              {d.savedLink}
            </Link>
            {d.offlineMapsAfter}
          </p>
        </div>
      )}

      {layer === "heat" && (
        <div className="flex flex-col gap-3">
          <p className="text-xs text-text-secondary">
            {discoverStatus(mergedHeat.disclaimer, lang)}
          </p>
          {mergedHeat.coldStart && (
            <p className="text-xs text-warning">
              {d.heatCold(mergedHeat.kThreshold)}
            </p>
          )}
          {!heatmapConsent && (
            <p className="text-xs">
              {d.heatConsentBefore}
              <Link href="/privacy" className="text-accent">
                {d.privacyLink}
              </Link>
              {d.heatConsentAfter(mergedHeat.kThreshold)}
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
                    ? d.heatCell
                    : s.id.startsWith("ride-")
                      ? d.heatOwn
                      : d.heatSection}
                  {" · "}
                  {d.riders(s.uniqueUsers, (s.intensity * 100).toFixed(0))}
                </li>
              ))}
            {mergedHeat.segments.filter((s) => s.visible).length === 0 && (
              <li className="text-text-secondary">
                {d.noSegments}
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
                  {d.heading(photo.headingDeg)}
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
                        ? "bg-accent text-on-accent"
                        : "bg-surface-elevated"
                    }`}
                  >
                    {i + 1}
                  </button>
                ))}
              </div>
              {trail?.usingDemo && (
                <p className="text-[11px] text-text-secondary">
                  {d.demoPhotos}
                </p>
              )}
            </>
          ) : (
            <p className="text-sm text-text-secondary">
              {d.noPhotos}
            </p>
          )}
        </div>
      )}

      {layer === "elevation" &&
        (ascentDisplay != null ? (
          <ElevationChart elev={elev} />
        ) : (
          <p className="text-sm text-text-secondary">
            {d.elevMissing}
          </p>
        ))}

      <div className="flex flex-col gap-2 pb-2">
        {onAdoptIntoPlan && geometry ? (
          <button
            type="button"
            onClick={onAdoptIntoPlan}
            className="rounded-xl border border-border py-2.5 text-sm font-medium"
          >
            {d.intoPlan}
          </button>
        ) : null}
        <div className="flex gap-2">
          <button
            type="button"
            onClick={onToggleSave}
            className="inline-flex items-center justify-center gap-1.5 rounded-xl border border-border px-3 py-3 text-sm"
          >
            {saved ? (
              <ChromeGlyph name="merken" size={16} current className="text-accent" />
            ) : (
              <ChromeGlyph name="merken" size={16} current className="text-text-secondary" />
            )}
            {saved ? d.saved : d.save}
          </button>
          {geometry ? (
            <button
              type="button"
              onClick={onStart}
              className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-on-accent"
            >
              <MappeGlyph name="ride" size={16} /> {d.startInApp}
            </button>
          ) : onAdoptIntoPlan ? (
            <button
              type="button"
              onClick={onAdoptIntoPlan}
              className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-on-accent"
            >
              {d.setEndCta}
            </button>
          ) : null}
        </div>
        <div className="mt-2 flex flex-wrap gap-2">
          <Link
            href={`/tours/${route.id}`}
            className="text-xs font-medium text-accent hover:underline"
          >
            {d.publicTour}
          </Link>
          <Link
            href={`/discover?panel=plan&tour=${encodeURIComponent(route.id)}`}
            className="text-xs font-medium text-accent hover:underline"
          >
            {d.openPlanner}
          </Link>
        </div>
      </div>
      {catalogTour ? <TourFunctionKit tour={catalogTour} /> : null}
      <TourReviews tourId={route.id} />
    </div>
  );
}
