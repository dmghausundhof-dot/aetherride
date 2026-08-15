"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Bookmark, Map } from "lucide-react";
import {
  decodeTourSharePayload,
  demoTourPayload,
  isShareDemoToken,
} from "@/lib/community/shareCodec";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { useAppStore } from "@/store/useAppStore";
import type { SavedRoute } from "@/types/route";

export default function SharedTourPage() {
  const params = useParams();
  const token = typeof params.token === "string" ? params.token : "";
  const saveRoute = useAppStore((s) => s.saveRoute);
  const [saved, setSaved] = useState(false);

  const payload = useMemo(() => {
    if (isShareDemoToken(token)) return demoTourPayload();
    return decodeTourSharePayload(token);
  }, [token]);

  if (!payload) {
    return (
      <div className="mx-auto max-w-lg px-4 py-20 text-center">
        <p className="text-[11px] font-bold tracking-wide text-chrome">Teilen</p>
        <h1 className="mt-2 text-xl font-bold">Link ungültig</h1>
        <p className="mt-2 text-sm text-text-secondary">
          Die geteilte Tour konnte nicht gelesen werden. Kein Feed, kein
          stiller Track.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-4 text-sm font-semibold text-chrome">
          <Link href="/share" className="hover:underline">
            So teilen
          </Link>
          <Link href="/library" className="hover:underline">
            Zum Platz
          </Link>
        </div>
      </div>
    );
  }

  const pub = payload.catalogTourId
    ? getPublicTour(payload.catalogTourId)
    : getPublicTour(payload.id);
  const hasTrack = payload.includeTrack && (payload.track?.length ?? 0) >= 2;
  const isDemo = isShareDemoToken(token);

  const adopt = () => {
    const entry: SavedRoute = {
      id: payload.id,
      name: payload.name,
      distanceKm: payload.distanceKm,
      elevationM: payload.elevationM,
      durationMin: payload.durationMin,
      savedAt: new Date().toISOString(),
      source:
        payload.source === "import" || payload.source === "engine"
          ? payload.source
          : "suggestion",
      geometry: hasTrack
        ? { type: "LineString", coordinates: payload.track! }
        : undefined,
    };
    saveRoute(entry);
    setSaved(true);
  };

  return (
    <div className="mx-auto max-w-lg px-4 py-10 sm:px-6">
      <p className="text-[11px] font-bold tracking-wide text-chrome">
        {isDemo ? "Beispiel-Link" : "Geteilte Tour"}
      </p>
      <h1 className="mt-2 text-2xl font-bold">{payload.name}</h1>
      <p className="mt-2 text-sm text-text-secondary">
        Von {payload.authorLabel} · {payload.distanceKm} km · {payload.elevationM}{" "}
        hm · {payload.durationMin} min
      </p>
      <p className="mt-2 text-[11px] text-text-secondary">
        {hasTrack
          ? "Der Link enthält eine vereinfachte Spur."
          : pub
            ? "Kein Extra-Track im Link — Katalog-Tour, schon öffentlich."
            : "Nur Name und Stats im Link — kein GPS-Track."}
      </p>

      {pub ? (
        <Link
          href={`/tours/${pub.id}`}
          className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-chrome hover:underline"
        >
          <Map className="h-4 w-4" /> Im Katalog öffnen
        </Link>
      ) : null}

      <button
        type="button"
        onClick={adopt}
        className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-white"
      >
        <Bookmark className="h-4 w-4" />
        {saved ? "In der Mappe" : "In die Mappe übernehmen"}
      </button>
      <p className="mt-3 text-center text-[11px] text-text-secondary">
        Speichert die Tour lokal in diesem Browser.
      </p>
      <div className="mt-6 text-center text-sm">
        <Link href="/share" className="text-chrome hover:underline">
          So teilen
        </Link>
        {" · "}
        <Link href="/library" className="text-chrome hover:underline">
          Platz
        </Link>
      </div>
    </div>
  );
}
