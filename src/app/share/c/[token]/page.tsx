"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Bookmark, Map } from "lucide-react";
import { decodeSharePayload, demoCollectionPayload, isShareDemoToken } from "@/lib/community/shareCodec";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { useAppStore } from "@/store/useAppStore";
import type { RouteSuggestion } from "@/lib/routing/suggestions";
import type { SharedCollectionPayload } from "@/lib/community/types";
import { useChromeLang } from "@/hooks/useChromeLang";
import { chromeDateLocale } from "@/lib/i18n/chromeLang";
import { shareCopy } from "@/lib/i18n/shareCopy";
import { webChrome } from "@/lib/i18n/webChrome";
import { formatDistanceElevation } from "@/lib/discover/elevationGuard";

export default function SharedCollectionPage() {
  const params = useParams();
  const token = typeof params.token === "string" ? params.token : "";
  const saveRoute = useAppStore((s) => s.saveRoute);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const addRouteToCollection = useAppStore((s) => s.addRouteToCollection);
  const [remote, setRemote] = useState<SharedCollectionPayload | null>(null);
  const [remoteDone, setRemoteDone] = useState(false);
  const lang = useChromeLang();
  const s = shareCopy(lang);
  const chrome = webChrome(lang);

  const encoded = useMemo(
    () =>
      isShareDemoToken(token)
        ? demoCollectionPayload()
        : decodeSharePayload(token),
    [token],
  );
  const isShort = /^[a-zA-Z0-9]{6,12}$/.test(token) && !isShareDemoToken(token);

  useEffect(() => {
    if (!isShort || encoded) {
      setRemoteDone(true);
      return;
    }
    let cancelled = false;
    fetch(`/api/community/collections?id=${encodeURIComponent(token)}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (cancelled) return;
        if (data?.payload) setRemote(data.payload as SharedCollectionPayload);
        setRemoteDone(true);
      })
      .catch(() => {
        if (!cancelled) setRemoteDone(true);
      });
    return () => {
      cancelled = true;
    };
  }, [token, isShort, encoded]);

  const payload = encoded || remote;

  if (!payload) {
    if (isShort && !encoded && !remoteDone) {
      return (
        <div className="mx-auto max-w-lg px-4 py-20 text-center text-sm text-text-secondary">
          {s.loadingCollection}
        </div>
      );
    }
    return (
      <div className="mx-auto max-w-lg px-4 py-20 text-center">
        <h1 className="text-xl font-bold">{s.invalid}</h1>
        <p className="mt-2 text-sm text-text-secondary">{s.invalidCollection}</p>
        <Link href="/library" className="mt-6 inline-block text-chrome">
          {s.toPlatz}
        </Link>
      </div>
    );
  }

  const adopt = () => {
    const colId = createRouteCollection(s.sharedSuffix(payload.name));
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
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {isShareDemoToken(token) ? s.demoMappe : s.sharedCollection}
      </p>
      <h1 className="mt-2 text-2xl font-bold">{payload.name}</h1>
      <p className="mt-2 text-sm text-text-secondary">
        {s.by(payload.authorLabel)}
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
        {new Date(payload.createdAt).toLocaleDateString(chromeDateLocale(lang))} ·{" "}
        {s.toursNoGps(payload.routeIds.length)}
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
                    {formatDistanceElevation(pub.distanceKm, pub.elevationM)}
                  </p>
                )}
              </div>
              {pub ? (
                <Link
                  href={`/tours/${pub.id}`}
                  className="shrink-0 text-xs font-medium text-accent"
                >
                  {s.open}
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
        className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-on-accent"
      >
        <Bookmark className="h-4 w-4" /> {s.adoptMappe}
      </button>
      <p className="mt-3 text-center text-[11px] text-text-secondary">
        {s.savesCollection}
      </p>
      <div className="mt-6 text-center">
        <Link href="/share" className="text-sm text-chrome hover:underline">
          {s.howToShare}
        </Link>
        {" · "}
        <Link href="/community" className="text-sm text-chrome hover:underline">
          {chrome.marketingNav["/community"]}
        </Link>
        {" · "}
        <Link href="/library" className="text-sm text-chrome hover:underline">
          {chrome.hofNav.platz}
        </Link>
      </div>
    </div>
  );
}
