"use client";

import { useMemo } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Bookmark, Map } from "lucide-react";
import { decodeSharePayload } from "@/lib/community/shareCodec";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { useAppStore } from "@/store/useAppStore";
import type { RouteSuggestion } from "@/lib/routing/suggestions";

export default function SharedCollectionPage() {
  const params = useParams();
  const token = typeof params.token === "string" ? params.token : "";
  const saveRoute = useAppStore((s) => s.saveRoute);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const addRouteToCollection = useAppStore((s) => s.addRouteToCollection);

  const payload = useMemo(() => decodeSharePayload(token), [token]);

  if (!payload) {
    return (
      <div className="mx-auto max-w-lg px-4 py-20 text-center">
        <h1 className="text-xl font-bold">Link ungültig</h1>
        <p className="mt-2 text-sm text-text-secondary">
          Die geteilte Sammlung konnte nicht gelesen werden.
        </p>
        <Link href="/library" className="mt-6 inline-block text-accent">
          Zur Bibliothek
        </Link>
      </div>
    );
  }

  const adopt = () => {
    const colId = createRouteCollection(
      `${payload.name} (geteilt)`
    );
    payload.routeIds.forEach((id, i) => {
      const pub = getPublicTour(id);
      const name = payload.routeNames[i] ?? pub?.name ?? id;
      if (pub) {
        const suggestion: RouteSuggestion = {
          id: pub.id,
          name: pub.name,
          category: pub.primaryCategory,
          distanceKm: pub.distanceKm,
          elevationM: pub.elevationM,
          durationMin: pub.durationMin,
          mtbScale: pub.difficulty,
          surface: pub.surface,
          loop: pub.loop,
          uncertainKmPct: 12,
          matchScore: 70,
          reasons: ["Geteilte Sammlung", pub.summary.slice(0, 60), pub.surface],
          center: pub.center,
        };
        saveRoute(suggestion);
      } else {
        saveRoute({
          id,
          name,
          distanceKm: 0,
          elevationM: 0,
          durationMin: 0,
          savedAt: new Date().toISOString(),
          source: "import",
        });
      }
      addRouteToCollection(colId, id);
    });
  };

  return (
    <div className="mx-auto max-w-lg px-4 py-10 sm:px-6">
      <p className="text-xs font-medium uppercase tracking-wide text-accent">
        Geteilte Sammlung
      </p>
      <h1 className="mt-2 text-2xl font-bold">{payload.name}</h1>
      <p className="mt-2 text-sm text-text-secondary">
        Von {payload.authorLabel}
        {payload.authorHandle ? (
          <>
            {" "}
            ·{" "}
            <Link
              href={`/u/${payload.authorHandle}`}
              className="text-accent hover:underline"
            >
              @{payload.authorHandle}
            </Link>
          </>
        ) : null}
      </p>
      <p className="mt-1 text-[11px] text-text-secondary">
        {new Date(payload.createdAt).toLocaleDateString("de-DE")} ·{" "}
        {payload.routeIds.length} Touren · ohne GPS-Tracks
      </p>

      <ul className="mt-8 space-y-2">
        {payload.routeIds.map((id, i) => {
          const pub = getPublicTour(id);
          const name = payload.routeNames[i] ?? pub?.name ?? id;
          return (
            <li
              key={`${id}-${i}`}
              className="flex items-center justify-between gap-2 rounded-xl border border-border bg-surface px-3 py-3"
            >
              <div className="min-w-0">
                <p className="truncate font-medium">{name}</p>
                {pub && (
                  <p className="text-[11px] text-text-secondary">
                    {pub.distanceKm} km · {pub.elevationM} hm
                  </p>
                )}
              </div>
              {pub ? (
                <Link
                  href={`/tours/${pub.id}`}
                  className="shrink-0 text-xs font-medium text-accent"
                >
                  Öffnen
                </Link>
              ) : (
                <Map className="h-4 w-4 shrink-0 text-text-secondary" />
              )}
            </li>
          );
        })}
      </ul>

      <button
        type="button"
        onClick={adopt}
        className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-white"
      >
        <Bookmark className="h-4 w-4" /> In meine Bibliothek übernehmen
      </button>
      <p className="mt-3 text-center text-[11px] text-text-secondary">
        Speichert die Sammlung lokal in diesem Browser.
      </p>
      <div className="mt-6 text-center">
        <Link href="/community" className="text-sm text-accent hover:underline">
          Community
        </Link>
        {" · "}
        <Link href="/library" className="text-sm text-accent hover:underline">
          Bibliothek
        </Link>
      </div>
    </div>
  );
}
