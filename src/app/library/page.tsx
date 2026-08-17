"use client";

/**
 * Platz: Mappe, Stimmen, Zusammen raus. Dieselben savedRoutes wie auf der Karte.
 */
import { useEffect, useRef, useState } from "react";
import { Bookmark } from "lucide-react";
import { useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { parseGpx } from "@/lib/import/gpx";
import { ShareCollectionButton } from "@/components/community/ShareCollectionButton";
import { VISIBILITY_FILTER_OPTIONS } from "@/lib/routing/routeFilters";
import { AddRouteForm } from "@/components/library/AddRouteForm";
import { resolveAddRouteStart } from "@/lib/library/addRouteStart";
import { readDiscoverViewport } from "@/lib/library/discoverViewport";
import { TourAkte } from "@/components/tours/TourAkte";
import {
  filterSavedByVisibility,
  stimmenTourIdOf,
  visibilityOf,
  type VisibilityScope,
} from "@/lib/tours/routeVisibility";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { chromeLangFrom } from "@/lib/i18n/chromeLang";
import { formatPlatzGroupWhen, platzCopy, platzNote } from "@/lib/i18n/platzCopy";
import { resolveAkteSavedRoute } from "@/lib/tours/tourAkte";
import { useCommunityStore } from "@/store/useCommunityStore";
import { RideGroupsPanel } from "@/components/community/RideGroupsPanel";
import { groupInviteScheme } from "@/lib/community/rideGroupInvite";
import { nextActiveMeeting } from "@/lib/community/rideGroup";
import { LOCAL_ONLY_NOTE, listedRideGroups, useRideGroupStore } from "@/store/useRideGroupStore";
import type { SavedRoute } from "@/types/route";
import {
  filterMappeQuery,
  mappeCardStats,
  savedRouteHasTrack,
  sortMappe,
  type MappeSort,
} from "@/lib/tours/mappeList";
import { activeRouteFromSaved } from "@/lib/routing/activeRoute";

export default function LibraryPage() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const g = platzCopy(lang);
  const router = useRouter();

  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const routeCollections = useAppStore((s) => s.routeCollections);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const myReviews = useCommunityStore((s) => s.myReviews);
  const markInboxSeen = useRideGroupStore((s) => s.markInboxSeen);
  const groups = useRideGroupStore((s) => s.groups);

  const [msg, setMsg] = useState<string | null>(null);
  const [appJoinHref, setAppJoinHref] = useState<string | null>(null);
  const [openAkte, setOpenAkte] = useState<string | null>(null);
  const [visScope, setVisScope] = useState<VisibilityScope>("all_mine");
  const [query, setQuery] = useState("");
  const [sort, setSort] = useState<MappeSort>("recent");
  const [colName, setColName] = useState("");
  const [addStart, setAddStart] = useState<[number, number] | null>(null);
  const [addStartSource, setAddStartSource] = useState<"gps" | "map" | null>(
    null,
  );
  const visibleRoutes = sortMappe(
    filterMappeQuery(filterSavedByVisibility(savedRoutes, visScope), query),
    sort,
  );
  const meet = nextActiveMeeting(listedRideGroups(groups));
  const akteRoute = resolveAkteSavedRoute(openAkte, savedRoutes);
  const stimmenInbox = myReviews.filter((r) =>
    savedRoutes.some((s) => stimmenTourIdOf(s) === r.tourId)
  );

  useEffect(() => {
    const akte = new URLSearchParams(window.location.search).get("akte")?.trim();
    if (akte) setOpenAkte(akte);
  }, []);
  useEffect(() => {
    let cancelled = false;
    const map = readDiscoverViewport()?.lngLat ?? null;
    const apply = (gps: [number, number] | null) => {
      if (cancelled) return;
      const hit = resolveAddRouteStart({ gps, map });
      setAddStart(hit?.lngLat ?? null);
      setAddStartSource(hit?.source ?? null);
    };
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      apply(null);
      return () => {
        cancelled = true;
      };
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => apply([pos.coords.longitude, pos.coords.latitude]),
      () => apply(null),
      { timeout: 4000, maximumAge: 120000 },
    );
    return () => {
      cancelled = true;
    };
  }, []);
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const group = params.get("group")?.trim();
    const token = params.get("g")?.trim();
    if (!group) return;
    const scheme = groupInviteScheme(group, token);
    setAppJoinHref(scheme);
    const openTimer = window.setTimeout(() => {
      window.location.assign(scheme);
    }, 80);
    const run = () => {
      void useRideGroupStore
        .getState()
        .joinFromInviteAsync(group, token)
        .then((out) => {
          const note = useRideGroupStore.getState().lastNote;
          const joinLang = chromeLangFrom(
            typeof navigator !== "undefined" ? navigator.language : "de",
          );
          const join = platzCopy(joinLang);
          if ("error" in out) {
            setMsg(platzNote(out.error, joinLang));
            return;
          }
          if (!out.onServer) {
            setMsg(
              join.joinNotOnServer(platzNote(note ?? LOCAL_ONLY_NOTE, joinLang)),
            );
            return;
          }
          setMsg(
            join.joinOk(out.title, note ? platzNote(note, joinLang) : null),
          );
        });
    };
    if (useRideGroupStore.persist.hasHydrated()) {
      run();
      return () => window.clearTimeout(openTimer);
    }
    const unsub = useRideGroupStore.persist.onFinishHydration(run);
    return () => {
      window.clearTimeout(openTimer);
      unsub?.();
    };
  }, []);
  useEffect(() => {
    markInboxSeen(stimmenInbox.length);
  }, [markInboxSeen, stimmenInbox.length]);
  const gpxRef = useRef<HTMLInputElement | null>(null);

  const importGpx = async (file: File | null) => {
    if (!file) return;
    try {
      const text = await file.text();
      const parsed = parseGpx(text, file.name.replace(/\.gpx$/i, ""));
      if (!parsed?.coordinates?.length) {
        setMsg(g.gpxNoTrack);
        return;
      }
      const entry: SavedRoute = {
        id: `gpx-${Date.now()}`,
        name: parsed.name || "GPX Import",
        distanceKm: Math.round(parsed.distanceKm * 10) / 10,
        elevationM: Math.round(parsed.elevationM),
        durationMin: parsed.durationMin,
        surface: "import",
        loop: false,
        savedAt: new Date().toISOString(),
        source: "import",
        geometry: {
          type: "LineString",
          coordinates: parsed.coordinates,
        },
      };
      saveRoute(entry);
      setMsg(g.gpxImported(entry.name));
    } catch {
      setMsg(g.gpxUnreadable);
    }
  };

  return (
    <div className="mx-auto max-w-4xl px-4 py-8 sm:px-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{copy.libraryTitle}</h1>
        <p className="mt-1 text-sm text-text-secondary">
          {copy.libraryHint}
        </p>
      </div>

      {msg && (
        <p className="mt-4 rounded-lg border border-border bg-surface px-3 py-2 text-xs text-text-secondary">
          {msg}
        </p>
      )}

      {meet ? (
        <div className="mt-6 flex items-center justify-between gap-3 rounded-xl bg-surface-elevated px-3 py-2.5">
          <p className="min-w-0 truncate text-sm font-semibold">
            {meet.title} ·{" "}
            {formatPlatzGroupWhen(
              meet.startWindowStart,
              meet.startWindowEnd,
              lang,
            )}
          </p>
          <button
            type="button"
            className="shrink-0 text-xs font-semibold text-accent"
            onClick={() => {
              const hit = savedRoutes.find((s) => s.id === meet.savedRouteId);
              if (!hit) return;
              const route = activeRouteFromSaved(hit);
              if (!route) return;
              setActiveRoute(route);
              router.push("/ride");
            }}
          >
            {g.goRide}
          </button>
        </div>
      ) : null}

      <section className="mt-8">
        <h2 className="mb-3 text-sm font-semibold tracking-wide text-text-secondary">
          {g.mappeKicker}
          {savedRoutes.length > 0 ? ` · ${visibleRoutes.length}` : ""}
        </h2>
        <div className="mb-3 flex flex-wrap items-center gap-2">
          <AddRouteForm
            compact
            defaultStart={addStart}
            startSource={addStartSource}
            onPickGpx={() => gpxRef.current?.click()}
          />
          <input
            ref={gpxRef}
            type="file"
            accept=".gpx,application/gpx+xml,text/xml"
            className="hidden"
            onChange={(e) => {
              void importGpx(e.target.files?.[0] ?? null);
              e.target.value = "";
            }}
          />
        </div>
        {savedRoutes.length >= 3 ? (
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={g.searchTours}
            className="mb-3 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
          />
        ) : null}
        {savedRoutes.length > 0 ? (
          <div className="mb-3 flex flex-wrap gap-1 rounded-xl bg-surface-elevated p-1 text-xs">
            {VISIBILITY_FILTER_OPTIONS.map(({ id }) => (
              <button
                key={id}
                type="button"
                onClick={() => setVisScope(id)}
                className={`rounded-full px-2.5 py-1.5 font-semibold ${
                  visScope === id
                    ? "bg-accent text-on-accent"
                    : "text-text-secondary"
                }`}
              >
                {id === "all_mine"
                  ? g.visAll
                  : id === "private"
                    ? g.visPrivate
                    : g.visPublic}
              </button>
            ))}
            {(["recent", "distance", "name"] as const).map((id) => (
              <button
                key={id}
                type="button"
                onClick={() => setSort(id)}
                className={`rounded-full px-2.5 py-1.5 font-semibold ${
                  sort === id ? "bg-chrome text-on-accent" : "text-text-secondary"
                }`}
              >
                {id === "recent"
                  ? g.sortRecent
                  : id === "distance"
                    ? g.sortDistance
                    : g.sortName}
              </button>
            ))}
          </div>
        ) : null}

        {savedRoutes.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border p-8 text-center">
            <Bookmark className="mx-auto h-8 w-8 text-text-secondary" />
            <p className="mt-3 text-sm text-text-secondary">{g.mappeEmpty}</p>
          </div>
        ) : visibleRoutes.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-border p-6 text-center text-sm text-text-secondary">
            {g.mappeFilterEmpty}
          </p>
        ) : (
          <ul className="divide-y divide-border rounded-xl border border-border">
            {visibleRoutes.map((r) => {
              const stats = mappeCardStats(r);
              const vis =
                visibilityOf(r) === "shared" ? g.shared : g.privateTour;
              return (
                <li key={r.id}>
                  <div className="flex items-center gap-2 px-3 py-2.5">
                    <button
                      type="button"
                      className="min-w-0 flex-1 text-left"
                      onClick={() =>
                        setOpenAkte((cur) => (cur === r.id ? null : r.id))
                      }
                    >
                      <span className="block truncate text-sm font-semibold">
                        {r.name}
                      </span>
                      <span className="mt-0.5 block text-xs tabular-nums text-text-secondary">
                        {stats ? `${stats} · ` : ""}
                        {vis}
                      </span>
                    </button>
                    {savedRouteHasTrack(r) ? (
                      <button
                        type="button"
                        className="shrink-0 text-xs font-semibold text-accent"
                        onClick={() => {
                          const route = activeRouteFromSaved(r);
                          if (!route) return;
                          setActiveRoute(route);
                          router.push("/ride");
                        }}
                      >
                        {g.goRide}
                      </button>
                    ) : (
                      <span className="shrink-0 text-text-secondary">›</span>
                    )}
                  </div>
                  {akteRoute?.id === r.id ? (
                    <div className="border-t border-border px-3 py-3">
                      <TourAkte
                        route={r}
                        onGoRide={() => {
                          const route = activeRouteFromSaved(r);
                          if (!route) return;
                          setActiveRoute(route);
                          router.push("/ride");
                        }}
                      />
                    </div>
                  ) : null}
                </li>
              );
            })}
          </ul>
        )}
      </section>

      {appJoinHref ? (
        <p className="mt-8 text-sm text-text-secondary">
          <a href={appJoinHref} className="font-semibold text-accent">
            {g.openInApp}
          </a>
          {g.joinOnDevice}
        </p>
      ) : null}

      <section className="mt-10">
        <h2 className="mb-3 text-sm font-semibold tracking-wide text-text-secondary">
          {g.stimmenTitle}
        </h2>
        {stimmenInbox.length === 0 ? (
          <p className="text-sm text-text-secondary">{g.stimmenEmpty}</p>
        ) : (
          <ul className="space-y-2">
            {stimmenInbox.slice(0, 8).map((r) => {
              const hit = savedRoutes.find((s) => stimmenTourIdOf(s) === r.tourId);
              return (
                <li key={r.id} className="rounded-xl border border-border px-4 py-3 text-sm">
                  <button
                    type="button"
                    className="font-semibold text-chrome"
                    onClick={() => hit && setOpenAkte(hit.id)}
                  >
                    {hit?.name ?? r.tourId}
                  </button>
                  <p className="mt-1 text-xs text-text-secondary">
                    {r.status === "pending" ? `${g.pending} · ` : ""}
                    {r.body}
                  </p>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <RideGroupsPanel savedRoutes={savedRoutes} visibility={visScope} />

      <section className="mt-10">
        <h2 className="mb-1 text-sm font-semibold tracking-wide text-text-secondary">
          {g.collectionsTitle}
          {routeCollections.length > 0 ? ` · ${routeCollections.length}` : ""}
        </h2>
        <p className="mb-3 text-xs text-text-secondary">{g.collectionsHint}</p>
        {routeCollections.length > 0 ? (
          <ul className="space-y-2">
            {routeCollections.map((c) => (
              <li
                key={c.id}
                className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-border px-4 py-3"
              >
                <div>
                  <span className="font-medium">{c.name}</span>
                  <span className="ml-2 text-xs text-text-secondary">
                    {g.collectionTours(c.routeIds.length)}
                  </span>
                </div>
                <ShareCollectionButton collectionId={c.id} />
              </li>
            ))}
          </ul>
        ) : null}
        <div className="mt-3 flex gap-2">
          <input
            value={colName}
            onChange={(e) => setColName(e.target.value)}
            placeholder={g.collectionName}
            className="min-w-0 flex-1 rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
          />
          <button
            type="button"
            className="rounded-lg border border-border px-2 py-1.5 text-[11px] font-semibold"
            onClick={() => {
              const name = colName.trim();
              if (!name) return;
              createRouteCollection(name);
              setColName("");
            }}
          >
            {g.collectionCreate}
          </button>
        </div>
      </section>
    </div>
  );
}
