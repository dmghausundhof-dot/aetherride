"use client";

import { useCallback, useEffect, useMemo, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Bookmark,
  Compass,
  Map as MapIcon,
  Mountain,
  Play,
  Route,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import {
  getSuggestionById,
  suggestRoutes,
  type RouteSuggestion,
} from "@/lib/routing/suggestions";
import { estimateRange } from "@/lib/ebike/range";
import { bikeCategoryLabel } from "@/lib/catalog/slots";
import { MapView } from "@/components/MapView";
import {
  profileForBikeCategory,
  requestRoute,
  type ClientRouteResult,
} from "@/lib/routing/profiles";
import {
  activeRouteFromEngine,
  activeRouteFromSuggestion,
} from "@/lib/routing/activeRoute";
import {
  DEFAULT_ROUTE_FILTERS,
  filterRouteSuggestions,
  type RouteFilterState,
} from "@/lib/routing/routeFilters";
import { buildDemoGeometry, centerOfGeometry } from "@/lib/routing/demoGeometry";
import { RouteCard } from "@/components/discover/RouteCard";
import { FilterChips } from "@/components/discover/FilterChips";
import { RouteDetail } from "@/components/discover/RouteDetail";
import type { SavedRoute } from "@/types/route";
import type { OutdooractiveTour } from "@/lib/geo/outdooractive";
import type { TrailforksPin } from "@/lib/geo/trailCondition";

type DiscoverTab = "suggestions" | "map" | "saved" | "explore";

const FALLBACK_CENTER: [number, number] = [8.2, 48.0];

function DiscoverPageInner() {
  const router = useRouter();
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
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const unsaveRoute = useAppStore((s) => s.unsaveRoute);
  const isRouteSaved = useAppStore((s) => s.isRouteSaved);

  const rangePro = canUseProFeature("range");
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  const [tab, setTab] = useState<DiscoverTab>("suggestions");
  const [minutes, setMinutes] = useState(
    profile.fitnessIndicators.avgRideDurationMin || 150
  );
  const [filters, setFilters] = useState<RouteFilterState>(DEFAULT_ROUTE_FILTERS);
  const [detailId, setDetailId] = useState<string | null>(highlightRouteId);
  const [mapCenter, setMapCenter] =
    useState<[number, number]>(FALLBACK_CENTER);
  const [engineRoute, setEngineRoute] = useState<ClientRouteResult | null>(
    null
  );
  const [routingBusy, setRoutingBusy] = useState(false);
  const [routingMsg, setRoutingMsg] = useState<string | null>(null);
  const [plannerOpen, setPlannerOpen] = useState(false);
  const [enrichmentNote, setEnrichmentNote] = useState<string | null>(null);
  const [oaTours, setOaTours] = useState<OutdooractiveTour[]>([]);
  const [oaAttr, setOaAttr] = useState<string | null>(null);
  const [oaWarning, setOaWarning] = useState<string | null>(null);
  const [tfPins, setTfPins] = useState<TrailforksPin[]>([]);
  const [tfDisclaimer, setTfDisclaimer] = useState<string | null>(null);

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

  const filtered = useMemo(
    () => filterRouteSuggestions(routes, filters),
    [routes, filters]
  );

  const detailRoute = useMemo(() => {
    if (!detailId || !activeBike) return null;
    return (
      getSuggestionById(detailId, {
        bike: activeBike,
        profile,
        availableMinutes: minutes,
        rangeKmHigh: range?.kmHigh,
      }) ??
      routes.find((r) => r.id === detailId) ??
      null
    );
  }, [detailId, activeBike, profile, minutes, range, routes]);

  useEffect(() => {
    if (highlightRouteId) {
      setDetailId(highlightRouteId);
      setTab("suggestions");
    }
  }, [highlightRouteId]);

  useEffect(() => {
    let cancelled = false;
    if (typeof navigator !== "undefined" && navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          if (!cancelled) {
            setMapCenter([pos.coords.longitude, pos.coords.latitude]);
          }
        },
        () => undefined,
        { timeout: 8000, maximumAge: 30 * 60 * 1000 }
      );
    }
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/outdooractive?type=tour")
      .then(async (r) => {
        if (cancelled || !r.ok) return;
        const data = await r.json();
        if (data?.provider === "outdooractive") {
          setOaTours(Array.isArray(data.tours) ? data.tours : []);
          setOaAttr(data.attribution ?? null);
          setOaWarning(data.warning ?? null);
          setEnrichmentNote(
            data.configured
              ? "Outdooractive Enrichment aktiv"
              : "Outdooractive Demo-Enrichment"
          );
        }
      })
      .catch(() => undefined);

    void fetch("/api/trailforks")
      .then(async (r) => {
        if (cancelled || !r.ok) return;
        const data = await r.json();
        setTfPins(Array.isArray(data.pins) ? data.pins : []);
        setTfDisclaimer(data.disclaimer ?? null);
      })
      .catch(() => undefined);

    return () => {
      cancelled = true;
    };
  }, []);

  const openDetail = useCallback(
    (id: string) => {
      setDetailId(id);
      router.replace(`/discover?route=${id}`, { scroll: false });
    },
    [router]
  );

  const closeDetail = useCallback(() => {
    setDetailId(null);
    router.replace("/discover", { scroll: false });
  }, [router]);

  const startWithSuggestion = useCallback(
    (r: RouteSuggestion) => {
      setActiveRoute(activeRouteFromSuggestion(r));
      router.push("/ride");
    },
    [setActiveRoute, router]
  );

  const startWithEngineRoute = useCallback(() => {
    if (!engineRoute) return;
    setActiveRoute(activeRouteFromEngine("Geplante Route", engineRoute));
    router.push("/ride");
  }, [engineRoute, setActiveRoute, router]);

  const toggleSave = useCallback(
    (r: RouteSuggestion | SavedRoute) => {
      if (isRouteSaved(r.id)) unsaveRoute(r.id);
      else saveRoute(r);
    },
    [isRouteSaved, saveRoute, unsaveRoute]
  );

  const runRouting = async () => {
    setRoutingBusy(true);
    setRoutingMsg(null);
    try {
      const profileId = profileForBikeCategory(
        activeBike?.category || "mtb_enduro"
      );
      const [lng, lat] = mapCenter;
      const result = await requestRoute(
        profileId,
        [lng, lat],
        [lng + 0.04, lat + 0.014]
      );
      if (!result) {
        setRoutingMsg("Route konnte nicht berechnet werden");
        return;
      }
      setEngineRoute(result);
      setRoutingMsg(
        `${(result.distanceM / 1000).toFixed(1)} km · ${Math.round(result.durationS / 60)} min`
      );
    } finally {
      setRoutingBusy(false);
    }
  };

  if (detailRoute) {
    return (
      <div className="flex flex-col gap-4 p-4 pt-6">
        <RouteDetail
          route={detailRoute}
          saved={isRouteSaved(detailRoute.id)}
          range={range}
          rangePro={rangePro}
          isEbike={!!activeBike?.isEbike}
          heatmapConsent={heatmapConsent}
          rides={rides}
          privacyZones={privacyZones.map((z) => ({
            lat: z.lat,
            lng: z.lng,
            radiusM: z.radiusM,
          }))}
          onBack={closeDetail}
          onStart={() => startWithSuggestion(detailRoute)}
          onToggleSave={() => toggleSave(detailRoute)}
        />
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Discover</h1>
        <p className="text-sm text-text-secondary">
          Touren für dein Bike · Filter · Gespeichert
        </p>
      </header>

      <div className="grid grid-cols-4 gap-1 rounded-xl bg-surface-elevated p-1 text-[10px]">
        {(
          [
            ["suggestions", "Vorschläge", Route],
            ["map", "Karte", MapIcon],
            ["explore", "DACH", Mountain],
            ["saved", "Gespeichert", Bookmark],
          ] as const
        ).map(([id, label, Icon]) => (
          <button
            key={id}
            type="button"
            onClick={() => setTab(id)}
            className={`flex items-center justify-center gap-1 rounded-lg py-2.5 font-medium ${
              tab === id ? "bg-accent text-white" : "text-text-secondary"
            }`}
          >
            <Icon className="h-3.5 w-3.5" />
            {label}
          </button>
        ))}
      </div>

      {activeBike && tab === "suggestions" && (
        <div className="rounded-xl bg-primary/20 px-3 py-2 text-sm">
          <span className="text-text-secondary">Für </span>
          <span className="font-medium">{activeBike.name}</span>
          <span className="text-text-secondary">
            {" "}
            · {bikeCategoryLabel(activeBike.category)}
          </span>
        </div>
      )}

      {tab === "suggestions" && (
        <>
          <FilterChips
            minutes={minutes}
            onMinutes={setMinutes}
            filters={filters}
            onChange={setFilters}
          />

          {enrichmentNote && (
            <p className="text-[11px] text-text-secondary">{enrichmentNote}</p>
          )}

          {activeBike?.isEbike && range && (
            <div className="rounded-xl border border-primary/30 bg-primary/10 px-3 py-2 text-sm">
              Reichweite {range.kmLow}–{range.kmHigh} km · Touren werden dagegen
              geprüft
            </div>
          )}

          <div className="flex flex-col gap-3">
            {filtered.length === 0 ? (
              <div className="rounded-2xl border border-border bg-surface p-6 text-center">
                <p className="text-sm text-text-secondary">
                  Keine Touren mit diesen Filtern — Filter lockern oder Zeitfenster
                  anpassen.
                </p>
              </div>
            ) : (
              filtered.map((r) => (
                <RouteCard
                  key={r.id}
                  route={r}
                  highlighted={highlightRouteId === r.id}
                  saved={isRouteSaved(r.id)}
                  onOpen={() => openDetail(r.id)}
                  onStart={() => startWithSuggestion(r)}
                  onToggleSave={() => toggleSave(r)}
                />
              ))
            )}
          </div>

          <button
            type="button"
            onClick={() => {
              setTab("map");
              setPlannerOpen(true);
            }}
            className="rounded-xl border border-border py-3 text-sm font-medium text-text-secondary"
          >
            Eigene Route planen
          </button>
        </>
      )}

      {tab === "map" && (
        <div className="flex flex-col gap-3">
          <MapView
            className="aspect-[4/3] w-full overflow-hidden rounded-2xl"
            center={mapCenter}
            zoom={11}
            route={
              engineRoute?.geometry ??
              (filtered[0]
                ? buildDemoGeometry(filtered[0].id, filtered[0].distanceKm)
                : null)
            }
          />
          <p className="text-xs text-text-secondary">
            Karte um deinen Standort
            {filtered[0] ? ` · Vorschau: ${filtered[0].name}` : ""}
          </p>

          <button
            type="button"
            onClick={() => setPlannerOpen((o) => !o)}
            className="rounded-xl border border-border py-2.5 text-sm font-medium"
          >
            {plannerOpen ? "Planer schließen" : "Route planen"}
          </button>

          {plannerOpen && (
            <div className="rounded-xl border border-border bg-surface p-3">
              <p className="mb-2 text-xs text-text-secondary">
                Kurze Demo-Route ab aktuellem Kartenmittelpunkt.
              </p>
              <button
                type="button"
                disabled={routingBusy}
                onClick={() => void runRouting()}
                className="w-full rounded-xl bg-accent py-2.5 text-sm font-semibold text-white disabled:opacity-40"
              >
                {routingBusy ? "Wird berechnet…" : "Route berechnen"}
              </button>
              {routingMsg && (
                <p className="mt-2 text-xs text-text-secondary">{routingMsg}</p>
              )}
              {engineRoute && (
                <button
                  type="button"
                  onClick={startWithEngineRoute}
                  className="mt-3 flex w-full items-center justify-center gap-2 rounded-xl border border-accent/40 bg-accent/10 py-2.5 text-sm font-semibold text-accent"
                >
                  <Play className="h-4 w-4 fill-current" />
                  Diese Route losfahren
                </button>
              )}
            </div>
          )}

          {filtered.slice(0, 3).map((r) => {
            const c = centerOfGeometry(
              buildDemoGeometry(r.id, r.distanceKm)
            );
            return (
              <button
                key={r.id}
                type="button"
                onClick={() => openDetail(r.id)}
                className="rounded-xl border border-border bg-surface px-3 py-2.5 text-left text-sm"
              >
                <span className="font-medium">{r.name}</span>
                <span className="block text-xs text-text-secondary">
                  {r.distanceKm} km · nahe {c[1].toFixed(2)}, {c[0].toFixed(2)}
                </span>
              </button>
            );
          })}
        </div>
      )}

      {tab === "explore" && (
        <div className="flex flex-col gap-4">
          <section className="rounded-2xl border border-border bg-surface p-4">
            <div className="mb-2 flex items-center gap-2">
              <Compass className="h-4 w-4 text-accent" />
              <h2 className="font-semibold">Outdooractive (DACH)</h2>
            </div>
            <p className="mb-3 text-xs text-text-secondary">
              Enrichment — keine Routing-Wahrheit. Touren aus der Community /
              Demo, wenn kein API-Key.
            </p>
            {oaWarning && (
              <p className="mb-2 text-[11px] text-warning">{oaWarning}</p>
            )}
            <div className="flex flex-col gap-2">
              {oaTours.map((t) => (
                <article
                  key={t.id}
                  className="rounded-xl border border-border bg-surface-elevated p-3"
                >
                  <div className="font-medium text-sm">{t.title}</div>
                  <p className="text-xs text-text-secondary">
                    {[
                      t.difficulty,
                      t.lengthKm != null ? `${t.lengthKm} km` : null,
                      t.elevationM != null ? `${t.elevationM} hm` : null,
                      t.source === "demo" ? "Demo" : null,
                    ]
                      .filter(Boolean)
                      .join(" · ")}
                  </p>
                  {t.summary && (
                    <p className="mt-1 text-[11px] text-text-secondary">
                      {t.summary}
                    </p>
                  )}
                  {t.url && (
                    <a
                      href={t.url}
                      target="_blank"
                      rel="noreferrer"
                      className="mt-2 inline-block text-xs font-medium text-accent"
                    >
                      Bei Outdooractive öffnen →
                    </a>
                  )}
                </article>
              ))}
            </div>
            {oaAttr && (
              <p className="mt-3 text-[10px] text-text-secondary">{oaAttr}</p>
            )}
          </section>

          <section className="rounded-2xl border border-border bg-surface p-4">
            <div className="mb-2 flex items-center gap-2">
              <Mountain className="h-4 w-4 text-accent" />
              <h2 className="font-semibold">Trailforks Status</h2>
            </div>
            <p className="mb-3 text-xs text-text-secondary">
              {tfDisclaimer ??
                "Attribution + Deep-Links — kein Geometrie-Mirror."}
            </p>
            <MapView
              className="mb-3 aspect-[16/9] w-full overflow-hidden rounded-xl"
              center={tfPins[0]?.center ?? mapCenter}
              zoom={8}
              track={tfPins.map((p) => ({
                lat: p.center[1],
                lng: p.center[0],
              }))}
            />
            <ul className="flex flex-col gap-2">
              {tfPins.map((p) => (
                <li
                  key={p.id}
                  className="rounded-xl border border-border bg-surface-elevated px-3 py-2"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <div className="text-sm font-medium">{p.name}</div>
                      <div className="text-xs text-text-secondary">
                        {p.difficulty ?? "—"} · {p.conditionLabel}
                      </div>
                    </div>
                    <a
                      href={p.openUrl}
                      target="_blank"
                      rel="noreferrer"
                      className="shrink-0 text-xs font-medium text-accent"
                    >
                      Trailforks →
                    </a>
                  </div>
                </li>
              ))}
            </ul>
            {tfPins[0] && (
              <p className="mt-3 text-[10px] text-text-secondary">
                {tfPins[0].attribution}
              </p>
            )}
          </section>
        </div>
      )}

      {tab === "saved" && (
        <div className="flex flex-col gap-3">
          {savedRoutes.length === 0 ? (
            <div className="rounded-2xl border border-border bg-surface p-6 text-center">
              <p className="text-sm text-text-secondary">
                Noch keine gespeicherten Touren. Speichere Vorschläge mit dem
                Lesezeichen.
              </p>
            </div>
          ) : (
            savedRoutes.map((r) => (
              <article
                key={r.id}
                className="rounded-2xl border border-border bg-surface p-4"
              >
                <h3 className="font-semibold">{r.name}</h3>
                <p className="text-xs text-text-secondary">
                  {r.distanceKm} km · {r.elevationM} hm · {r.durationMin} min
                  {r.mtbScale && r.mtbScale !== "—" ? ` · ${r.mtbScale}` : ""}
                </p>
                <div className="mt-3 flex gap-2">
                  <button
                    type="button"
                    onClick={() => unsaveRoute(r.id)}
                    className="rounded-xl border border-border px-3 py-2 text-sm"
                  >
                    Entfernen
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      const suggestion = activeBike
                        ? getSuggestionById(r.id, {
                            bike: activeBike,
                            profile,
                            availableMinutes: minutes,
                            rangeKmHigh: range?.kmHigh,
                          })
                        : null;
                      if (suggestion) {
                        startWithSuggestion(suggestion);
                        return;
                      }
                      setActiveRoute({
                        id: r.id,
                        name: r.name,
                        distanceKm: r.distanceKm,
                        elevationM: r.elevationM,
                        durationMin: r.durationMin,
                        mtbScale: r.mtbScale,
                        surface: r.surface,
                        reasons: r.reasons,
                        geometry: buildDemoGeometry(r.id, r.distanceKm),
                        source: "suggestion",
                        setAt: new Date().toISOString(),
                      });
                      router.push("/ride");
                    }}
                    className="flex flex-1 items-center justify-center gap-2 rounded-xl bg-accent py-2.5 text-sm font-semibold text-white"
                  >
                    <Play className="h-4 w-4 fill-current" /> Losfahren
                  </button>
                </div>
              </article>
            ))
          )}
        </div>
      )}

      <p className="flex items-center justify-center gap-2 text-xs text-text-secondary">
        <Compass className="h-3.5 w-3.5" />
        Karten · Trail-Fotos · eigene Aggregate
      </p>
    </div>
  );
}

export default function DiscoverPage() {
  return (
    <Suspense
      fallback={
        <div className="p-6 text-center text-sm text-text-secondary">
          Discover wird geladen…
        </div>
      }
    >
      <DiscoverPageInner />
    </Suspense>
  );
}
