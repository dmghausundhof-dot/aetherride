"use client";

/**
 * Universal Link Landing: versucht Custom Scheme, zeigt Store-Fallback.
 * ?route=tourId
 */
import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import { FlowLineWordmark } from "@/components/brand/FlowLineWordmark";
import {
  appDeepLink,
  hasStoreLinks,
  rideOpenPath,
} from "@/lib/web/appLinks";
import { useChromeLang } from "@/hooks/useChromeLang";
import { openRideCopy } from "@/lib/i18n/openRideCopy";

function OpenRideInner() {
  const sp = useSearchParams();
  const routeId = sp.get("route");
  const o = openRideCopy(useChromeLang());
  const [tried, setTried] = useState(false);

  const deep = useMemo(
    () => appDeepLink(rideOpenPath(routeId)),
    [routeId]
  );

  useEffect(() => {
    // Intent: open the native app
    window.location.href = deep;
    const t = window.setTimeout(() => setTried(true), 1200);
    return () => window.clearTimeout(t);
  }, [deep]);

  return (
    <div className="mx-auto flex max-w-md flex-col items-center justify-center px-4 py-16 text-center">
      <FlowLineWordmark showMark className="text-2xl font-bold tracking-tight" />
      <h1 className="mt-6 text-2xl font-bold">{o.title}</h1>
      <p className="mt-3 text-sm text-text-secondary">
        {routeId ? o.handingTour : o.handingNav}
      </p>
      <a
        href={deep}
        className="mt-8 inline-flex items-center justify-center rounded-xl bg-accent px-6 py-3 text-sm font-semibold text-on-accent"
      >
        {o.openNow}
      </a>
      {tried && (
        <div className="mt-10 space-y-4">
          <p className="text-xs text-text-secondary">
            {o.notInstalled}{" "}
            {hasStoreLinks() ? o.loadInStore : o.continueInBrowser}
          </p>
          {hasStoreLinks() ? (
            <div className="flex justify-center">
              <AppDownloadButtons size="md" />
            </div>
          ) : (
            <Link
              href={routeId ? `/tours/${encodeURIComponent(routeId)}` : "/discover"}
              className="text-sm font-semibold text-chrome hover:underline"
            >
              {o.continueCta}
            </Link>
          )}
        </div>
      )}
    </div>
  );
}

export default function OpenRidePage() {
  const o = openRideCopy(useChromeLang());
  return (
    <Suspense
      fallback={
        <div className="p-12 text-center text-sm text-text-secondary">
          {o.opening}
        </div>
      }
    >
      <OpenRideInner />
    </Suspense>
  );
}
