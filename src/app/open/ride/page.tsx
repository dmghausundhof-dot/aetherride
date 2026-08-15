"use client";

/**
 * Universal Link Landing: versucht Custom Scheme, zeigt Store-Fallback.
 * ?route=tourId
 */
import { Suspense, useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { AppDownloadButtons } from "@/components/landing/AppDownloadButtons";
import {
  appDeepLink,
  hasStoreLinks,
  rideOpenPath,
} from "@/lib/web/appLinks";

function OpenRideInner() {
  const sp = useSearchParams();
  const routeId = sp.get("route");
  const [tried, setTried] = useState(false);

  const deep = useMemo(
    () => appDeepLink(rideOpenPath(routeId)),
    [routeId]
  );

  useEffect(() => {
    // Intent: App öffnen
    window.location.href = deep;
    const t = window.setTimeout(() => setTried(true), 1200);
    return () => window.clearTimeout(t);
  }, [deep]);

  return (
    <div className="mx-auto flex min-h-dvh max-w-md flex-col justify-center px-4 py-12 text-center">
      <h1 className="text-2xl font-bold">FlowLine öffnen</h1>
      <p className="mt-3 text-sm text-text-secondary">
        {routeId
          ? "Geplante Tour wird an die App übergeben…"
          : "Weiterleitung zur nativen Navigation…"}
      </p>
      <a
        href={deep}
        className="mt-8 inline-flex items-center justify-center rounded-xl bg-accent px-6 py-3 text-sm font-semibold text-white"
      >
        App jetzt öffnen
      </a>
      {tried && (
        <div className="mt-10 space-y-4">
          <p className="text-xs text-text-secondary">
            App nicht installiert?{" "}
            {hasStoreLinks() ? "Im Store laden:" : "Im Browser fortfahren:"}
          </p>
          {hasStoreLinks() ? (
            <div className="flex justify-center">
              <AppDownloadButtons size="md" />
            </div>
          ) : (
            <Link
              href={routeId ? `/tours/${encodeURIComponent(routeId)}` : "/discover"}
              className="text-sm font-semibold text-accent hover:underline"
            >
              Im Browser fortfahren →
            </Link>
          )}
        </div>
      )}
    </div>
  );
}

export default function OpenRidePage() {
  return (
    <Suspense
      fallback={
        <div className="p-12 text-center text-sm text-text-secondary">
          Öffne App…
        </div>
      }
    >
      <OpenRideInner />
    </Suspense>
  );
}
