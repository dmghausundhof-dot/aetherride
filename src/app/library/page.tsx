"use client";

/**
 * Platz: Mappe, Stimmen, Zusammen raus. Dieselben savedRoutes wie auf der Karte.
 */
import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useAppStore } from "@/store/useAppStore";
import { parseGpx } from "@/lib/import/gpx";
import { fitTourLine } from "@/lib/tours/tourLine";
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
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import { formatPlatzGroupWhen, platzCopy, platzNote } from "@/lib/i18n/platzCopy";
import { resolveAkteSavedRoute, formatMappeDay, joinMappeCaption, lastRideForSavedRoute, latestConditionTag, stimmeInboxTitle } from "@/lib/tours/tourAkte";
import { useCommunityStore } from "@/store/useCommunityStore";
import { RideGroupsPanel } from "@/components/community/RideGroupsPanel";
import { decodeGroupInvite, groupInviteScheme } from "@/lib/community/rideGroupInvite";
import { importMemberTourFromInvite } from "@/lib/community/groupMemberTour";
import { nextActiveMeeting } from "@/lib/community/rideGroup";
import { LOCAL_ONLY_NOTE, listedRideGroups, useRideGroupStore } from "@/store/useRideGroupStore";
import type { SavedRoute } from "@/types/route";
import {
  applyElevBackfill,
  filterMappeQuery,
  mappeCollectionRestLine,
  mappeCollectionTrackCount,
  mappeCollectionTracks,
  mappeSourceChip,
  mappeStartAwayKm,
  mappeTrackClimbM,
  savedRouteNeedsElevBackfill,
  savedRouteTrackCoords,
  sortMappe,
  type MappeSort,
} from "@/lib/tours/mappeList";
import { activeRouteFromSaved } from "@/lib/routing/activeRoute";
import {
  attachElevFromProfile,
  fetchElevationProfile,
  trackHasRealElev,
} from "@/lib/routing/elevationAttach";
import { MappeEmpty } from "@/components/tours/MappeEmpty";
import { MappeGlyph } from "@/components/tours/MappeGlyph";
import { MappeSectionLabel } from "@/components/tours/MappeSectionLabel";
import { MappeStimmeRow } from "@/components/tours/MappeStimmeRow";
import { MappeTourCard } from "@/components/tours/MappeTourCard";
import { TourLineThumb, MappeTrackStack } from "@/components/tours/TourLineThumb";

export default function LibraryPage() {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const g = platzCopy(lang);
  const stimme = catalogCopy(lang).stimmen;
  const router = useRouter();

  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const unsaveRoute = useAppStore((s) => s.unsaveRoute);
  const updateSavedRoute = useAppStore((s) => s.updateSavedRoute);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);
  const rides = useAppStore((s) => s.rides);
  const bikes = useAppStore((s) => s.bikes);
  const routeCollections = useAppStore((s) => s.routeCollections);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const myReviews = useCommunityStore((s) => s.myReviews);
  const markInboxSeen = useRideGroupStore((s) => s.markInboxSeen);
  const groups = useRideGroupStore((s) => s.groups);

  const [msg, setMsg] = useState<string | null>(null);
  const [appJoinHref, setAppJoinHref] = useState<string | null>(null);
  const [openAkte, setOpenAkte] = useState<string | null>(null);
  const [groupCreateId, setGroupCreateId] = useState<string | null>(null);
  const [visScope, setVisScope] = useState<VisibilityScope>("all_mine");
  const [query, setQuery] = useState("");
  const [sort, setSort] = useState<MappeSort>("recent");
  const [colName, setColName] = useState("");
  const [addStart, setAddStart] = useState<[number, number] | null>(null);
  const [addStartSource, setAddStartSource] = useState<"gps" | "map" | null>(
    null,
  );
  const [stimmenOpen, setStimmenOpen] = useState<boolean | null>(null);
  const [collectionsOpen, setCollectionsOpen] = useState<boolean | null>(null);
  const visibleRoutes = sortMappe(
    filterMappeQuery(filterSavedByVisibility(savedRoutes, visScope), query),
    sort,
  );
  const meet = nextActiveMeeting(listedRideGroups(groups));
  const akteRoute = resolveAkteSavedRoute(openAkte, savedRoutes);
  const stimmenInbox = myReviews.filter((r) =>
    savedRoutes.some((s) => stimmenTourIdOf(s) === r.tourId)
  );
  const stimmenExpanded = stimmenOpen ?? stimmenInbox.length > 0;
  const collectionsExpanded =
    collectionsOpen ?? routeCollections.length > 0;

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const akte = params.get("akte")?.trim();
    if (akte) setOpenAkte(akte);
    const groupCreate = params.get("groupCreate")?.trim();
    if (groupCreate) setGroupCreateId(groupCreate);
  }, []);
  useEffect(() => {
    let cancelled = false;
    const tried = new Set<string>();
    const run = async () => {
      const routes = useAppStore.getState().savedRoutes;
      for (const r of routes) {
        if (cancelled) break;
        if (tried.has(r.id)) continue;
        if (!savedRouteNeedsElevBackfill(r)) {
          tried.add(r.id);
          continue;
        }
        tried.add(r.id);
        const coords = savedRouteTrackCoords(r);
        if (trackHasRealElev(coords)) {
          const climb = mappeTrackClimbM(coords);
          if (climb == null) continue;
          const patch = applyElevBackfill(r, coords, climb);
          if (patch) updateSavedRoute(r.id, patch);
          continue;
        }
        const profile = await fetchElevationProfile(coords);
        if (cancelled || !profile) continue;
        const next = attachElevFromProfile(coords, profile);
        const patch = applyElevBackfill(r, next, profile.totalClimbM);
        if (patch) updateSavedRoute(r.id, patch);
      }
    };
    void run();
    return () => {
      cancelled = true;
    };
  }, [updateSavedRoute]);
  useEffect(() => {
    if (!groupCreateId) return;
    document
      .getElementById("group-create")
      ?.scrollIntoView({ behavior: "smooth", block: "start" });
  }, [groupCreateId]);

  const consumeGroupCreate = () => {
    setGroupCreateId(null);
    const url = new URL(window.location.href);
    url.searchParams.delete("groupCreate");
    window.history.replaceState({}, "", `${url.pathname}${url.search}`);
  };
  useEffect(() => {
    let cancelled = false;
    const vp = readDiscoverViewport();
    const map = vp ? ([vp.lng, vp.lat] as [number, number]) : null;
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
          if (token) {
            const entry = importMemberTourFromInvite({
              payload: decodeGroupInvite(token),
              existing: useAppStore.getState().savedRoutes,
            });
            if (entry) useAppStore.getState().saveRoute(entry);
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
        loop: fitTourLine(parsed.coordinates)?.loop === true,
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
        <h1 className="flex items-baseline gap-2 text-2xl font-bold tracking-tight">
          {copy.libraryTitle}
          {savedRoutes.length > 0 ? (
            <span className="text-base font-semibold text-text-secondary">
              {visibleRoutes.length}
            </span>
          ) : null}
        </h1>
        {savedRoutes.length === 0 ? (
          <p className="mt-1 text-sm text-text-secondary">{copy.libraryHint}</p>
        ) : null}
      </div>

      {msg && (
        <p className="mt-4 rounded-lg border border-border bg-surface px-3 py-2 text-xs text-text-secondary">
          {msg}
        </p>
      )}

      {meet ? (
        <div className="mt-6 overflow-hidden rounded-2xl border border-border bg-surface">
          {(() => {
            const hit = savedRoutes.find((s) => s.id === meet.savedRouteId);
            const coords = hit ? savedRouteTrackCoords(hit) : [];
            return coords.length >= 2 && hit ? (
              <TourLineThumb
                coordinates={coords}
                label={hit.name}
                noTrackLabel={g.noTrackLabel}
                size={72}
                wide
              />
            ) : null;
          })()}
          <div className="flex items-center justify-between gap-3 px-3 py-2.5">
          <div className="flex min-w-0 items-center gap-2.5">
            <MappeGlyph name="meet" size={22} />
            <p className="min-w-0 truncate text-sm font-semibold">
              {meet.title} ·{" "}
              {formatPlatzGroupWhen(
                meet.startWindowStart,
                meet.startWindowEnd,
                lang,
              )}
            </p>
          </div>
          <button
            type="button"
            className="shrink-0"
            onClick={() => {
              const hit = savedRoutes.find((s) => s.id === meet.savedRouteId);
              if (!hit) return;
              const route = activeRouteFromSaved(hit);
              if (!route) return;
              setActiveRoute(route);
              router.push("/ride");
            }}
            aria-label={g.goRide}
          >
            <MappeGlyph name="ride" size={32} alt={g.goRide} />
          </button>
          </div>
        </div>
      ) : null}

      <section className="mt-8">
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
        {savedRoutes.length > 0 ? (
          <div className="mb-3 flex flex-wrap items-center gap-2">
            <AddRouteForm
              compact
              defaultStart={addStart}
              startSource={addStartSource}
              onPickGpx={() => gpxRef.current?.click()}
            />
          </div>
        ) : null}
        {savedRoutes.length > 0 ? (
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={g.searchTours}
            aria-label={g.searchTours}
            className="mb-3 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm"
          />
        ) : null}
        {savedRoutes.length > 0 ? (
          <>
          <div className="mb-2 flex flex-wrap gap-1 rounded-xl bg-surface-elevated p-1 text-xs">
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
          </div>
          <div className="mb-3 flex flex-wrap gap-1 text-xs">
            {(["recent", "distance", "name"] as const).map((id) => (
              <button
                key={id}
                type="button"
                onClick={() => setSort(id)}
                className={`rounded-full px-2.5 py-1 font-semibold ${
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
          </>
        ) : null}

        {savedRoutes.length === 0 ? (
          <MappeEmpty
            title={g.mappeEmptyTitle}
            hint={g.mappeEmpty}
            actions={
              <>
                <button
                  type="button"
                  className="rounded-xl bg-accent px-3 py-2 text-xs font-semibold text-on-accent"
                  onClick={() => router.push("/discover")}
                >
                  {g.keepOnMap}
                </button>
                <button
                  type="button"
                  className="rounded-xl border border-border px-3 py-2 text-xs font-semibold"
                  onClick={() => gpxRef.current?.click()}
                >
                  {g.importGpx}
                </button>
                <AddRouteForm
                  compact
                  tone="ghost"
                  label={g.keepName}
                  defaultStart={addStart}
                  startSource={addStartSource}
                  onPickGpx={() => gpxRef.current?.click()}
                />
              </>
            }
          />
        ) : visibleRoutes.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border bg-surface px-4 py-6 text-center">
            <p className="flex items-center justify-center gap-2 text-sm font-semibold">
              <MappeGlyph name="mappe" size={16} />
              {g.mappeFilterEmpty}
            </p>
            <button
              type="button"
              className="mt-3 text-sm font-semibold text-accent"
              onClick={() => setVisScope("all_mine")}
            >
              {g.showAll}
            </button>
          </div>
        ) : (
          <ul className="space-y-2.5">
            {visibleRoutes.map((r) => {
              const vis =
                visibilityOf(r) === "shared" ? g.shared : g.privateTour;
              const last = lastRideForSavedRoute(rides, r);
              const bikeName = bikes.find(
                (b) => b.id === (last?.bikeId ?? r.preferredBikeId),
              )?.name;
              const away =
                addStartSource === "gps"
                  ? mappeStartAwayKm(
                      savedRouteTrackCoords(r),
                      addStart?.[1],
                      addStart?.[0],
                    )
                  : null;
              const caption = joinMappeCaption([
                bikeName ? g.riddenWith(bikeName) : null,
                last ? g.lastRidden(formatMappeDay(last.startTime)) : null,
              ]);
              const awayLabel =
                away != null ? g.startAwayKm(away) : undefined;
              const tag = latestConditionTag(
                myReviews,
                stimmenTourIdOf(r),
              );
              const goRide = () => {
                const route = activeRouteFromSaved(r);
                if (!route) return;
                setActiveRoute(route);
                router.push("/ride");
              };
              return (
                <MappeTourCard
                  key={r.id}
                  route={r}
                  visLabel={vis}
                  loopLabel={g.loopTag}
                  noTrackLabel={g.noTrackLabel}
                  rideLabel={g.goRide}
                  caption={caption}
                  awayLabel={awayLabel}
                  conditionLabel={tag ? stimme.tagLabel(tag) : undefined}
                  sourceChip={mappeSourceChip(r.source, {
                    import: g.sourceImport,
                    planned: g.sourcePlanned,
                    recorded: g.sourceRecorded,
                  })}
                  open={akteRoute?.id === r.id}
                  onOpen={() =>
                    setOpenAkte((cur) => (cur === r.id ? null : r.id))
                  }
                  onGoRide={goRide}
                >
                  <TourAkte
                    route={r}
                    onGoRide={goRide}
                    onShowOnMap={() => {
                      const route = activeRouteFromSaved(r);
                      if (route) setActiveRoute(route);
                      router.push(
                        `/discover?route=${encodeURIComponent(r.id)}`,
                      );
                    }}
                    onCreateGroup={() => setGroupCreateId(r.id)}
                    onRemoveFromMappe={() => {
                      unsaveRoute(r.id);
                      setOpenAkte(null);
                    }}
                  />
                </MappeTourCard>
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

      <section className="mt-10 rounded-2xl border border-border bg-surface px-3 py-3">
        <MappeSectionLabel
          glyph="stimmen"
          count={stimmenInbox.length}
          expanded={stimmenExpanded}
          onToggle={() => setStimmenOpen(!stimmenExpanded)}
        >
          {g.stimmenTitle}
        </MappeSectionLabel>
        {stimmenExpanded ? (
          stimmenInbox.length === 0 ? (
            <p className="text-sm text-text-secondary">{g.stimmenEmpty}</p>
          ) : (
            <ul className="space-y-2.5">
              {stimmenInbox.slice(0, 8).map((r) => {
                const hit = savedRoutes.find((s) => stimmenTourIdOf(s) === r.tourId);
                const tag = latestConditionTag([r], r.tourId);
                return (
                  <MappeStimmeRow
                    key={r.id}
                    title={stimmeInboxTitle(hit?.name, r.body, g.stimmeUntitled)}
                    body={r.body}
                    noTrackLabel={g.noTrackLabel}
                    pendingLabel={r.status === "pending" ? g.pending : undefined}
                    conditionLabel={tag ? stimme.tagLabel(tag) : undefined}
                    route={hit}
                    onOpen={hit ? () => setOpenAkte(hit.id) : undefined}
                  />
                );
              })}
            </ul>
          )
        ) : null}
      </section>

      <RideGroupsPanel
        savedRoutes={savedRoutes}
        visibility={visScope}
        initialRouteId={groupCreateId}
        origin={
          addStart
            ? { lng: addStart[0], lat: addStart[1] }
            : null
        }
        originKind={addStartSource}
        onCreated={consumeGroupCreate}
      />

      <section className="mt-10 rounded-2xl border border-border bg-surface px-3 py-3">
        <MappeSectionLabel
          glyph="collection"
          count={routeCollections.length}
          expanded={collectionsExpanded}
          onToggle={() => setCollectionsOpen(!collectionsExpanded)}
        >
          {g.collectionsTitle}
        </MappeSectionLabel>
        {collectionsExpanded ? (
          <>
            <p className="mb-3 text-xs text-text-secondary">{g.collectionsHint}</p>
            {routeCollections.length > 0 ? (
              <ul className="space-y-2">
                {routeCollections.map((c) => {
                  const tracks = mappeCollectionTracks(c.routeIds, savedRoutes);
                  const extra =
                    mappeCollectionTrackCount(c.routeIds, savedRoutes) -
                    tracks.length;
                  return (
                  <li
                    key={c.id}
                    className="overflow-hidden rounded-xl border border-border bg-surface-elevated"
                  >
                    {tracks.length > 0 ? (
                      <MappeTrackStack
                        tracks={tracks}
                        label={c.name}
                        noTrackLabel={g.noTrackLabel}
                        size={56}
                        extraCount={extra}
                      />
                    ) : null}
                    <div className="flex flex-wrap items-center justify-between gap-2 px-3 py-2.5">
                    <div className="flex min-w-0 items-center gap-2">
                      <MappeGlyph name="collection" size={18} />
                      <div>
                        <span className="font-medium">{c.name}</span>
                        <span className="ml-2 text-xs text-text-secondary">
                          {mappeCollectionRestLine(
                            g.collectionTours(c.routeIds.length),
                            extra,
                          )}
                        </span>
                      </div>
                    </div>
                    <ShareCollectionButton collectionId={c.id} />
                    </div>
                  </li>
                  );
                })}
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
                  setCollectionsOpen(true);
                }}
              >
                {g.collectionCreate}
              </button>
            </div>
          </>
        ) : null}
      </section>
    </div>
  );
}
