"use client";

import { useEffect, useMemo, useState } from "react";
import {
  Compass,
  Mountain,
  Route,
  Flame,
  Camera,
  AreaChart,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { suggestRoutes } from "@/lib/routing/suggestions";
import { estimateRange } from "@/lib/ebike/range";
import { buildHeatmap } from "@/lib/routing/heatmaps";
import { getTrailViewNear } from "@/lib/routing/trailView";
import { buildDemoElevationProfile } from "@/lib/routing/elevationProfile";
import {
  ROUTING_PROFILES,
  requestRoute,
  type RoutingProfile,
  type RouteResult,
} from "@/lib/routing/profiles";
import type { JurisdictionId } from "@/lib/routing/accessRights";
import { buildManeuvers, speakTbt } from "@/lib/routing/turnByTurn";
import { HIKING_GEAR_DEFAULT } from "@/lib/mode/hiking";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { MapView } from "@/components/MapView";
import { AccessRightsPanel } from "@/components/AccessRightsPanel";
import {
  OFFLINE_REGIONS_DEMO,
  canDownloadOfflineOnWeb,
  offlineRegionsSummary,
} from "@/lib/sync/offlineRegions";
import Link from "next/link";

type DiscoverTab = "routes" | "heatmap" | "trail" | "profile";

export default function DiscoverPage() {
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const boschLive = useAppStore((s) => s.boschLive);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const consents = useAppStore((s) => s.consents);
  const appMode = useAppStore((s) => s.appMode);
  const rangePro = canUseProFeature("range");
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [minutes, setMinutes] = useState(150);
  const [tab, setTab] = useState<DiscoverTab>("routes");
  const [photoIdx, setPhotoIdx] = useState(0);
  const [routingProfile, setRoutingProfile] = useState<RoutingProfile>(
    appMode === "hiking" ? "HIKING" : "MTB_TRAIL"
  );
  const [jurisdiction, setJurisdiction] = useState<JurisdictionId>("AT-7");
  const [routeResult, setRouteResult] = useState<RouteResult | null>(null);

  useEffect(() => {
    if (appMode === "hiking") setRoutingProfile("HIKING");
  }, [appMode]);

  useEffect(() => {
    let cancelled = false;
    requestRoute(
      routingProfile,
      [47.45, 12.15],
      [47.48, 12.22],
      jurisdiction
    ).then((r) => {
      if (!cancelled) setRouteResult(r);
    });
    return () => {
      cancelled = true;
    };
  }, [routingProfile, jurisdiction]);

  const heatmapConsent =
    consents.find((c) => c.purpose === "heatmap_contribution")?.granted ??
    false;

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

  const heatmap = useMemo(
    () => buildHeatmap({ consentHeatmap: heatmapConsent }),
    [heatmapConsent]
  );
  const trail = useMemo(() => getTrailViewNear(47.45, 12.15), []);
  const elev = useMemo(() => buildDemoElevationProfile(), []);
  const photo = trail.photos[photoIdx];

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Discover</h1>
        <p className="text-sm text-text-secondary">
          Routen · Heatmap · Trail View · Höhenprofil
        </p>
      </header>

      <div className="grid grid-cols-4 gap-1 rounded-xl bg-surface-elevated p-1 text-[10px]">
        {(
          [
            ["routes", "Routen"],
            ["heatmap", "Heat"],
            ["trail", "Trail"],
            ["profile", "Profil"],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => setTab(id)}
            className={`rounded-lg py-2 font-medium ${
              tab === id ? "bg-accent text-white" : "text-text-secondary"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {tab === "routes" && (
        <>
          <section className="rounded-2xl border border-border bg-surface p-4">
            <h3 className="mb-2 flex items-center gap-2 font-semibold">
              <Compass className="h-4 w-4 text-accent" /> Routing-Profil (F-NAV-001)
            </h3>
            <div className="mb-3 flex flex-wrap gap-1">
              {(Object.keys(ROUTING_PROFILES) as RoutingProfile[]).map((id) => (
                <button
                  key={id}
                  type="button"
                  onClick={() => setRoutingProfile(id)}
                  className={`rounded-lg px-2 py-1 text-[10px] font-medium ${
                    routingProfile === id
                      ? "bg-accent text-white"
                      : "bg-surface-elevated text-text-secondary"
                  }`}
                >
                  {ROUTING_PROFILES[id].label}
                </button>
              ))}
            </div>
            {routeResult && (
              <div className="space-y-2 text-sm">
                <p>
                  {(routeResult.distanceM / 1000).toFixed(1)} km ·{" "}
                  {routeResult.elevationGainM} hm ·{" "}
                  {Math.round(routeResult.durationS / 60)} min
                </p>
                <p className="text-xs text-text-secondary">
                  Unsichere Abschnitte: {routeResult.uncertainKm} km (
                  {Math.round(routeResult.uncertainShare * 100)} %) — nicht
                  optimistisch bewertet
                </p>
                <p className="text-[10px] text-text-secondary">
                  {routeResult.costingNote}
                </p>
                <button
                  type="button"
                  onClick={() => {
                    const man = buildManeuvers(routeResult);
                    const next = man.find((m) => m.type !== "start");
                    if (next) speakTbt(next.instructionDe, "de");
                  }}
                  className="rounded-xl bg-accent px-3 py-2 text-xs font-medium text-white"
                >
                  TbT-Ansage testen (F-NAV-003)
                </button>
              </div>
            )}
          </section>

          {routeResult && (
            <AccessRightsPanel
              jurisdiction={jurisdiction}
              onJurisdictionChange={setJurisdiction}
              findings={routeResult.accessFindings ?? []}
              blocked={routeResult.blocked || (routeResult.accessFindings ?? []).some((f) => f.severity === "block")}
            />
          )}

          {appMode === "hiking" && (
            <section className="rounded-2xl border border-border bg-surface p-4">
              <h3 className="mb-2 font-semibold">Ausrüstungsliste</h3>
              <ul className="space-y-1 text-sm">
                {HIKING_GEAR_DEFAULT.map((g) => (
                  <li key={g.id} className="flex justify-between">
                    <span>{g.label}</span>
                    <span className="text-xs text-text-secondary">
                      {g.essential ? "Pflicht" : "Optional"}
                    </span>
                  </li>
                ))}
              </ul>
            </section>
          )}

          {activeBike && appMode === "bike" && (
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
              </p>
            </div>
          )}

          <section className="rounded-xl border border-border bg-surface-elevated p-3 text-sm">
            <h3 className="font-medium">Offline mitnehmen (F-NAV-002 Demo)</h3>
            <p className="mt-1 text-xs text-text-secondary">
              {offlineRegionsSummary()}
            </p>
            <ul className="mt-2 space-y-1 text-xs text-text-secondary">
              {OFFLINE_REGIONS_DEMO.map((r) => (
                <li key={r.id} className="flex items-center justify-between gap-2">
                  <span>
                    {r.label} · ~{r.sizeMbEstimate} MB
                  </span>
                  <button
                    type="button"
                    disabled={!canDownloadOfflineOnWeb() || !canUseProFeature("offline")}
                    onClick={() =>
                      alert(
                        canUseProFeature("offline")
                          ? r.note
                          : "Offline-Regionen sind Pro (Spec 1.4) — Web-Demo ohne PMTiles."
                      )
                    }
                    className="rounded-lg border border-border px-2 py-1 text-[10px] disabled:opacity-50"
                  >
                    Download
                  </button>
                </li>
              ))}
            </ul>
          </section>

          {range && (
            <div className="rounded-xl border border-primary/30 bg-primary/10 p-3 text-sm">
              <div className="font-medium text-accent">
                Reichweite {range.kmLow}–{range.kmHigh} km
              </div>
              <p className="mt-1 text-xs text-text-secondary">
                {range.whPerKmLow}–{range.whPerKmHigh} Wh/km · {range.confidence}
              </p>
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
                      {r.distanceKm} km · {r.elevationM} hm · {r.durationMin} min
                      · {r.mtbScale}
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
          </div>
        </>
      )}

      {tab === "heatmap" && (
        <div className="flex flex-col gap-3">
          <div className="rounded-xl border border-border bg-surface p-3 text-sm">
            <div className="mb-1 flex items-center gap-2 font-medium">
              <Flame className="h-4 w-4 text-accent" /> Heatmap (F-NAV-005)
            </div>
            <p className="text-xs text-text-secondary">{heatmap.disclaimer}</p>
            {heatmap.coldStart && (
              <p className="mt-2 text-xs text-warning">
                Kaltstart: noch wenige Segmente mit k≥{heatmap.kThreshold} —
                offen kommuniziert (R-06 / Strava-Lehre).
              </p>
            )}
            {!heatmapConsent && (
              <p className="mt-2 text-xs">
                Beitrag Opt-in unter{" "}
                <Link href="/privacy" className="text-accent">
                  Privatsphäre
                </Link>
                .
              </p>
            )}
          </div>
          <MapView
            className="aspect-[4/3] w-full overflow-hidden rounded-2xl"
            center={[12.15, 47.45]}
            zoom={12}
            track={heatmap.segments
              .filter((s) => s.visible)
              .flatMap((s) =>
                s.coordinates.map(([lng, lat]) => ({ lat, lng }))
              )}
          />
          <ul className="space-y-2 text-xs">
            {heatmap.segments.map((s) => (
              <li
                key={s.id}
                className={`rounded-xl border px-3 py-2 ${
                  s.visible
                    ? "border-accent/30 bg-accent/5"
                    : "border-border bg-surface opacity-60"
                }`}
              >
                <span className="font-medium">{s.osmWayId}</span> · {s.uniqueUsers}{" "}
                Nutzer
                {!s.visible && s.hideReason ? ` — ${s.hideReason}` : ""}
                {s.visible
                  ? ` · Intensität ${(s.intensity * 100).toFixed(0)} %`
                  : ""}
              </li>
            ))}
          </ul>
          <p className="text-[10px] text-text-secondary">{heatmap.attribution}</p>
        </div>
      )}

      {tab === "trail" && photo && (
        <div className="flex flex-col gap-3">
          <div className="rounded-xl border border-border bg-surface p-3 text-sm">
            <div className="mb-1 flex items-center gap-2 font-medium">
              <Camera className="h-4 w-4 text-accent" /> Trail View (F-NAV-006)
            </div>
            <p className="text-xs text-text-secondary">{trail.disclaimer}</p>
          </div>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={photo.imageUrl}
            alt={photo.title}
            className="aspect-video w-full rounded-2xl object-cover"
          />
          <div className="text-sm">
            <div className="font-semibold">{photo.title}</div>
            <p className="text-xs text-text-secondary">
              {photo.source === "mapillary" ? "Mapillary" : "Nutzer"} · Blick{" "}
              {photo.headingDeg}° · {photo.lat.toFixed(4)}, {photo.lng.toFixed(4)}
            </p>
            <p className="mt-2 text-[11px] text-text-secondary">
              {photo.attributionHtml}
            </p>
          </div>
          <div className="flex gap-2">
            {trail.photos.map((p, i) => (
              <button
                key={p.id}
                type="button"
                onClick={() => setPhotoIdx(i)}
                className={`rounded-lg px-3 py-1 text-xs ${
                  i === photoIdx ? "bg-accent text-white" : "bg-surface-elevated"
                }`}
              >
                {i + 1}
              </button>
            ))}
          </div>
          <p className="text-[10px] text-text-secondary">
            {trail.attribution} ·{" "}
            <a
              href="https://www.mapillary.com/"
              target="_blank"
              rel="noreferrer"
              className="text-accent"
            >
              mapillary.com
            </a>
          </p>
        </div>
      )}

      {tab === "profile" && (
        <div className="flex flex-col gap-3">
          <div className="rounded-xl border border-border bg-surface p-3 text-sm">
            <div className="mb-1 flex items-center gap-2 font-medium">
              <AreaChart className="h-4 w-4 text-accent" /> Höhenprofil
              (F-NAV-007)
            </div>
            <p className="text-xs text-text-secondary">
              {elev.totalDistKm.toFixed(1)} km · {elev.totalClimbM} hm ·
              Datenlücke {elev.gapKm.toFixed(1)} km (nicht interpoliert)
            </p>
          </div>
          <svg viewBox="0 0 400 120" className="w-full rounded-xl bg-surface">
            {elev.points.map((p, i) => {
              if (p.elevM == null || i === 0) return null;
              const prev = elev.points[i - 1];
              if (prev.elevM == null) return null;
              const x1 = (prev.distKm / elev.totalDistKm) * 380 + 10;
              const x2 = (p.distKm / elev.totalDistKm) * 380 + 10;
              const y1 = 100 - ((prev.elevM - 700) / 400) * 80;
              const y2 = 100 - ((p.elevM - 700) / 400) * 80;
              const steep = (p.gradePct ?? 0) > 8;
              return (
                <line
                  key={i}
                  x1={x1}
                  y1={y1}
                  x2={x2}
                  y2={y2}
                  stroke={steep ? "#FF6B35" : "#1A5C45"}
                  strokeWidth="2"
                />
              );
            })}
            {/* Lücken markieren */}
            {elev.points
              .filter((p) => p.elevM == null)
              .map((p) => (
                <rect
                  key={`gap-${p.distKm}`}
                  x={(p.distKm / elev.totalDistKm) * 380 + 8}
                  y={20}
                  width={6}
                  height={80}
                  fill="#6B7280"
                  opacity="0.35"
                />
              ))}
          </svg>
          <div className="text-[11px] text-text-secondary">
            <p className="font-medium text-foreground">Oberfläche</p>
            {elev.surfaceBands.slice(0, 6).map((b) => (
              <span key={`${b.fromKm}-${b.surface}`} className="mr-2">
                {b.fromKm.toFixed(1)}–{b.toKm.toFixed(1)} km: {b.surface ?? "—"}
              </span>
            ))}
            <p className="mt-2 font-medium text-foreground">mtb:scale</p>
            {elev.scaleBands.slice(0, 6).map((b) => (
              <span key={`${b.fromKm}-s`} className="mr-2">
                {b.fromKm.toFixed(1)}: {b.scale ?? "—"}
              </span>
            ))}
          </div>
        </div>
      )}

      <p className="flex items-center justify-center gap-2 text-xs text-text-secondary">
        <Compass className="h-3.5 w-3.5" />
        OSM · Mapillary CC BY-SA · eigene Aggregate
      </p>
    </div>
  );
}
