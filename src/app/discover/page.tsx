"use client";

import { useEffect, useMemo, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
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
import {
  getTrailViewNear,
  type TrailViewResult,
} from "@/lib/routing/trailView";
import {
  buildDemoElevationProfile,
  buildElevationFromTrack,
  type ElevationProfile,
} from "@/lib/routing/elevationProfile";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { MapView } from "@/components/MapView";
import Link from "next/link";
import {
  profileForBikeCategory,
  requestRoute,
  type ClientRouteResult,
} from "@/lib/routing/profiles";
import { EvidenceSheet } from "@/components/EvidenceSheet";

type DiscoverTab = "routes" | "heatmap" | "trail" | "profile";

function DiscoverPageInner() {
  const searchParams = useSearchParams();
  const highlightRouteId = searchParams.get("route");
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const privacyZones = useAppStore((s) => s.privacyZones);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const boschLive = useAppStore((s) => s.boschLive);
  const canUseProFeature = useAppStore((s) => s.canUseProFeature);
  const consents = useAppStore((s) => s.consents);
  const rangePro = canUseProFeature("range");
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];
  const [minutes, setMinutes] = useState(150);
  const [tab, setTab] = useState<DiscoverTab>("routes");
  const [photoIdx, setPhotoIdx] = useState(0);
  const [trail, setTrail] = useState<TrailViewResult>(() =>
    getTrailViewNear(47.45, 12.15)
  );
  const [elev, setElev] = useState<ElevationProfile>(() =>
    buildDemoElevationProfile()
  );
  const [engineRoute, setEngineRoute] = useState<ClientRouteResult | null>(
    null
  );
  const [routingBusy, setRoutingBusy] = useState(false);
  const [routingMsg, setRoutingMsg] = useState<string | null>(null);

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

  useEffect(() => {
    if (!highlightRouteId) return;
    setTab("routes");
    const el = document.getElementById(`route-${highlightRouteId}`);
    el?.scrollIntoView({ behavior: "smooth", block: "center" });
  }, [highlightRouteId, routes]);

  const heatmap = useMemo(
    () =>
      buildHeatmap({
        consentHeatmap: heatmapConsent,
        rides,
        privacyZones: privacyZones.map((z) => ({
          lat: z.lat,
          lng: z.lng,
          radiusM: z.radiusM,
        })),
        includeSeedFallback: true,
      }),
    [heatmapConsent, rides, privacyZones]
  );

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/trail?lat=47.45&lng=12.15")
      .then((r) => r.json())
      .then((data: TrailViewResult) => {
        if (!cancelled && data?.photos) setTrail(data);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const last = rides.find((r) => r.track && r.track.length > 2);
    if (!last?.track) {
      setElev(buildDemoElevationProfile());
      return;
    }
    let cancelled = false;
    const local = buildElevationFromTrack(last.track, "track");
    if (local.points.some((p) => p.elevM != null)) {
      setElev(local);
      return;
    }
    void fetch("/api/elevation", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ track: last.track }),
    })
      .then((r) => r.json())
      .then((data: ElevationProfile) => {
        if (!cancelled && data?.points) setElev(data);
      })
      .catch(() => {
        if (!cancelled) setElev(buildDemoElevationProfile());
      });
    return () => {
      cancelled = true;
    };
  }, [rides]);

  const photo = trail.photos[photoIdx];

  const runRouting = async () => {
    setRoutingBusy(true);
    setRoutingMsg(null);
    try {
      const profileId = profileForBikeCategory(
        activeBike?.category || "mtb_enduro"
      );
      const result = await requestRoute(
        profileId,
        [12.14, 47.448],
        [12.18, 47.462]
      );
      if (!result) {
        setRoutingMsg("Routing fehlgeschlagen");
        return;
      }
      setEngineRoute(result);
      setRoutingMsg(
        `${result.engine}: ${(result.distanceM / 1000).toFixed(1)} km · ${Math.round(result.durationS / 60)} min${
          result.warnings?.[0] ? ` — ${result.warnings[0]}` : ""
        }`
      );
    } finally {
      setRoutingBusy(false);
    }
  };

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

          <div className="rounded-xl border border-border bg-surface p-3">
            <button
              type="button"
              disabled={routingBusy}
              onClick={() => void runRouting()}
              className="w-full rounded-xl bg-accent py-2.5 text-sm font-semibold text-white disabled:opacity-40"
            >
              {routingBusy
                ? "Route wird berechnet…"
                : "Route berechnen (Valhalla/OSRM/Demo)"}
            </button>
            {routingMsg && (
              <p className="mt-2 text-xs text-text-secondary">{routingMsg}</p>
            )}
            <MapView
              className="mt-3 aspect-[4/3] w-full"
              center={[12.15, 47.45]}
              zoom={12}
              route={engineRoute?.geometry ?? null}
            />
          </div>

          {activeBike?.isEbike && !rangePro && (
            <div className="rounded-xl border border-warning/40 bg-warning/10 p-3 text-sm">
              <div className="font-medium">Reichweitenprognose · Pro</div>
              <p className="mt-1 text-xs text-text-secondary">
                Physik + Selbstkalibrierung (F-EBK-004) ist Pro laut Spec 1.4.
              </p>
            </div>
          )}

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
                id={`route-${r.id}`}
                key={r.id}
                className={`rounded-2xl border bg-surface p-4 ${
                  highlightRouteId === r.id
                    ? "border-accent ring-1 ring-accent/40"
                    : "border-border"
                }`}
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
                <EvidenceSheet title="Warum dieser Vorschlag?" className="mt-3">
                  <ol className="list-decimal space-y-1 pl-4">
                    {r.reasons.map((reason) => (
                      <li key={reason}>{reason}</li>
                    ))}
                  </ol>
                </EvidenceSheet>
                {r.rangeNote && (
                  <p className="mt-2 text-xs text-warning">{r.rangeNote}</p>
                )}
                <Link
                  href="/ride"
                  className="mt-3 inline-flex text-sm font-medium text-accent"
                >
                  Mit dieser Route Ride starten →
                </Link>
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
            {trail.usingDemo && (
              <p className="mt-1 text-[11px] text-warning">
                Demo-Modus — MAPILLARY_ACCESS_TOKEN setzen für Live-Bilder
              </p>
            )}
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
              Datenlücke {elev.gapKm.toFixed(1)} km · Quelle {elev.source}
              {elev.source === "demo" ? " (Fallback)" : ""} (nicht interpoliert)
            </p>
          </div>
          <svg viewBox="0 0 400 120" className="w-full rounded-xl bg-surface">
            {elev.points.map((p, i) => {
              if (p.elevM == null || i === 0 || elev.totalDistKm <= 0) return null;
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

export default function DiscoverPage() {
  return (
    <Suspense
      fallback={<div className="p-6 text-center">Discover wird geladen…</div>}
    >
      <DiscoverPageInner />
    </Suspense>
  );
}
