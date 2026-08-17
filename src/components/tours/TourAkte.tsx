"use client";

import { useMemo, useState } from "react";
import { TourReviews } from "@/components/community/TourReviews";
import { TourCommunityChip } from "@/components/community/TourCommunityChip";
import { catalogTourIdOf, ridesForSavedRoute } from "@/lib/tours/tourAkte";
import { stimmenTourIdOf, visibilityOf } from "@/lib/tours/routeVisibility";
import { ShareTourButton } from "@/components/tours/ShareTourButton";
import { useHofCopy } from "@/hooks/useHofCopy";
import { useChromeLang } from "@/hooks/useChromeLang";
import { platzCopy, platzShareHonesty } from "@/lib/i18n/platzCopy";
import { useAppStore } from "@/store/useAppStore";
import type { SavedRoute } from "@/types/route";

type Shelf = "mein" | "stimmen";

export function TourAkte({ route }: { route: SavedRoute }) {
  const copy = useHofCopy();
  const lang = useChromeLang();
  const p = platzCopy(lang);

  const [shelf, setShelf] = useState<Shelf>("mein");
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const updateSavedRoute = useAppStore((s) => s.updateSavedRoute);
  const collections = useAppStore((s) => s.routeCollections);
  const addRouteToCollection = useAppStore((s) => s.addRouteToCollection);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const [colName, setColName] = useState("");
  const [colMsg, setColMsg] = useState("");

  const catalogId = catalogTourIdOf(route);
  const visibility = visibilityOf(route);
  const stimmenId = stimmenTourIdOf(route);
  const onThis = useMemo(
    () => ridesForSavedRoute(rides, route),
    [rides, route],
  );
  const lastRideBikeId = onThis[0]?.bikeId ?? route.preferredBikeId ?? null;
  const riddenWith = bikes.find((b) => b.id === lastRideBikeId)?.name ?? null;
  const hasTrack = Boolean(
    route.geometry?.coordinates && route.geometry.coordinates.length >= 2,
  );

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <div className="flex flex-wrap items-start justify-between gap-2">
        <div className="min-w-0">
          <p className="text-[11px] font-bold tracking-wide text-text-secondary">
            {p.tourKicker}
          </p>
          <h3 className="text-lg font-semibold">{route.name}</h3>
          <p className="mt-0.5 text-xs tabular-nums text-text-secondary">
            {route.distanceKm} km · {route.elevationM} hm · {route.durationMin}{" "}
            min
            {route.source === "import" ? " · GPX" : ""}
            {catalogId ? ` · ${p.catalogTag}` : ""}
            {visibility === "shared" ? ` · ${p.shared}` : ` · ${p.privateTour}`}
          </p>
          {riddenWith ? (
            <p className="mt-1 text-[11px] text-text-secondary">
              {p.riddenWith(riddenWith)}
            </p>
          ) : null}
        </div>
        {catalogId ? <TourCommunityChip tourId={catalogId} /> : null}
      </div>

      <div className="mt-3 grid grid-cols-2 gap-1 rounded-xl bg-surface-elevated p-1 text-xs">
        {(
          [
            ["mein", copy.akteMein],
            ["stimmen", copy.akteStimmen],
          ] as const
        ).map(([id, label]) => (
          <button
            key={id}
            type="button"
            onClick={() => setShelf(id)}
            className={`rounded-lg py-2 font-semibold ${
              shelf === id ? "bg-chrome text-on-accent" : "text-text-secondary"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {shelf === "mein" ? (
        <div className="mt-4 space-y-3">
          <p className="text-sm text-text-secondary">
            {route.geometry ? p.trackLocal : p.noTrackMappe}
          </p>
          {collections.filter((c) => c.routeIds.includes(route.id)).length >
          0 ? (
            <p className="text-xs text-text-secondary">
              {p.inCollections(
                collections
                  .filter((c) => c.routeIds.includes(route.id))
                  .map((c) => c.name)
                  .join(", "),
              )}
            </p>
          ) : null}
          <div className="rounded-xl border border-border bg-background p-3">
            <p className="text-xs font-semibold text-text-secondary">
              {p.addToCollection}
            </p>
            {collections.length > 0 ? (
              <select
                className="mt-2 w-full rounded-lg border border-border bg-surface px-2 py-1.5 text-xs"
                defaultValue=""
                onChange={(e) => {
                  const id = e.target.value;
                  if (!id) return;
                  addRouteToCollection(id, route.id);
                  e.target.value = "";
                  setColMsg(p.collectionAdded);
                }}
              >
                <option value="" disabled>
                  {p.addToCollection}
                </option>
                {collections.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            ) : (
              <p className="mt-1 text-[11px] text-text-secondary">
                {p.collectionEmpty}
              </p>
            )}
            <div className="mt-2 flex gap-2">
              <input
                value={colName}
                onChange={(e) => setColName(e.target.value)}
                placeholder={p.collectionName}
                className="min-w-0 flex-1 rounded-lg border border-border bg-background px-2 py-1.5 text-xs"
              />
              <button
                type="button"
                className="rounded-lg border border-border px-2 py-1.5 text-[11px] font-semibold"
                onClick={() => {
                  const name = colName.trim();
                  if (!name) return;
                  const id = createRouteCollection(name);
                  addRouteToCollection(id, route.id);
                  setColName("");
                  setColMsg(p.collectionAdded);
                }}
              >
                {p.collectionCreate}
              </button>
            </div>
            {colMsg ? (
              <p className="mt-1 text-[11px] text-text-secondary">{colMsg}</p>
            ) : null}
          </div>
          <div className="rounded-xl border border-border bg-background p-3">
            <p className="text-xs font-semibold text-text-secondary">
              {p.visibility}
            </p>
            <div className="mt-2 grid grid-cols-2 gap-1 rounded-lg bg-surface-elevated p-1">
              {(["private", "shared"] as const).map((id) => (
                <button
                  key={id}
                  type="button"
                  onClick={() => {
                    if (id === "private") {
                      const epoch = (route.shareEpoch ?? 0) + 1;
                      updateSavedRoute(route.id, {
                        visibility: "private",
                        shareEpoch: epoch,
                      });
                      void import("@/lib/community/tourShareRevoke").then(
                        (m) => {
                          m.revokeTourShareLocally(route.id, epoch);
                          void m.revokeTourShareOnServer(route.id, epoch);
                        },
                      );
                      return;
                    }
                    updateSavedRoute(route.id, { visibility: id });
                  }}
                  className={`rounded-md py-1.5 text-xs font-semibold ${
                    visibility === id
                      ? "bg-chrome text-on-accent"
                      : "text-text-secondary"
                  }`}
                >
                  {id === "private" ? p.visPrivate : p.shareOut}
                </button>
              ))}
            </div>
            <p className="mt-2 text-[11px] leading-snug text-text-secondary">
              {platzShareHonesty(Boolean(catalogId), hasTrack, lang)}
            </p>
            {visibility === "shared" ? (
              <div className="mt-2">
                <ShareTourButton route={route} />
              </div>
            ) : null}
          </div>
          <label className="block text-xs text-text-secondary">
            {p.privateNote}
            <textarea
              defaultValue={route.personalNote ?? ""}
              rows={2}
              className="mt-1 w-full rounded-lg border border-border bg-background px-3 py-2 text-sm text-foreground"
              placeholder={p.notePlaceholder}
              onBlur={(e) =>
                updateSavedRoute(route.id, {
                  personalNote: e.target.value.trim() || undefined,
                })
              }
            />
          </label>
        </div>
      ) : null}

      {shelf === "stimmen" ? (
        <div className="mt-4">
          {stimmenId ? (
            <TourReviews tourId={stimmenId} showHeading={false} />
          ) : (
            <p className="text-sm text-text-secondary">
              {copy.stimmenPrivateHint}
            </p>
          )}
        </div>
      ) : null}
    </section>
  );
}
