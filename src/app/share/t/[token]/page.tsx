"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { ChromeGlyph } from "@/components/chrome/ChromeGlyph";
import {
  decodeTourSharePayload,
  demoTourPayload,
  isShareDemoToken,
} from "@/lib/community/shareCodec";
import { getPublicTour } from "@/lib/catalog/publicTours";
import { useAppStore } from "@/store/useAppStore";
import type { SavedRoute } from "@/types/route";
import {
  isTourShareRevokedLocally,
  isTourShareRevokedOnServer,
} from "@/lib/community/tourShareRevoke";
import { useChromeLang } from "@/hooks/useChromeLang";
import { shareCopy } from "@/lib/i18n/shareCopy";
import { webChrome } from "@/lib/i18n/webChrome";

export default function SharedTourPage() {
  const params = useParams();
  const token = typeof params.token === "string" ? params.token : "";
  const saveRoute = useAppStore((s) => s.saveRoute);
  const [saved, setSaved] = useState(false);
  const lang = useChromeLang();
  const s = shareCopy(lang);
  const chrome = webChrome(lang);

  const payload = useMemo(() => {
    if (isShareDemoToken(token)) return demoTourPayload();
    return decodeTourSharePayload(token);
  }, [token]);

  const [revoked, setRevoked] = useState(false);

  useEffect(() => {
    if (!payload || isShareDemoToken(token)) {
      setRevoked(false);
      return;
    }
    if (isTourShareRevokedLocally(payload.id, payload.epoch)) {
      setRevoked(true);
      return;
    }
    let cancelled = false;
    void isTourShareRevokedOnServer(payload.id, payload.epoch).then((flag) => {
      if (!cancelled && flag) setRevoked(true);
    });
    return () => {
      cancelled = true;
    };
  }, [payload, token]);

  if (!payload) {
    return (
      <div className="mx-auto max-w-lg px-4 py-20 text-center">
        <p className="text-[11px] font-bold tracking-wide text-text-secondary">
          {s.kicker}
        </p>
        <h1 className="mt-2 text-xl font-bold">{s.invalid}</h1>
        <p className="mt-2 text-sm text-text-secondary">{s.invalidTour}</p>
        <div className="mt-6 flex flex-wrap justify-center gap-4 text-sm font-semibold text-chrome">
          <Link href="/share" className="hover:underline">
            {s.howToShare}
          </Link>
          <Link href="/library" className="hover:underline">
            {s.toPlatz}
          </Link>
        </div>
      </div>
    );
  }

  if (revoked) {
    return (
      <div className="mx-auto max-w-lg px-4 py-20 text-center">
        <p className="text-[11px] font-bold tracking-wide text-text-secondary">
          {s.kicker}
        </p>
        <h1 className="mt-2 text-xl font-bold">{s.revoked}</h1>
        <p className="mt-2 text-sm text-text-secondary">{s.revokedBody}</p>
        <div className="mt-6 flex flex-wrap justify-center gap-4 text-sm font-semibold text-chrome">
          <Link href="/share" className="hover:underline">
            {s.howToShare}
          </Link>
          <Link href="/library" className="hover:underline">
            {s.toPlatz}
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
      catalogTourId: payload.catalogTourId,
      geometry: hasTrack
        ? { type: "LineString", coordinates: payload.track! }
        : undefined,
    };
    saveRoute(entry);
    setSaved(true);
  };

  return (
    <div className="mx-auto max-w-lg px-4 py-10 sm:px-6">
      <p className="text-[11px] font-bold tracking-wide text-text-secondary">
        {isDemo ? s.demoLink : s.sharedTour}
      </p>
      <h1 className="mt-2 text-2xl font-bold">{payload.name}</h1>
      <p className="mt-2 text-sm text-text-secondary">
        {s.by(payload.authorLabel)} · {payload.distanceKm} km · {payload.elevationM}{" "}
        hm · {payload.durationMin} min
      </p>
      <p className="mt-2 text-[11px] text-text-secondary">
        {hasTrack
          ? s.trackInLink
          : pub
            ? s.catalogNoTrack
            : s.nameStatsOnly}
      </p>

      {pub ? (
        <Link
          href={`/tours/${pub.id}`}
          className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-chrome hover:underline"
        >
          <ChromeGlyph name="karte" size={16} current /> {s.openCatalog}
        </Link>
      ) : null}

      <button
        type="button"
        onClick={adopt}
        className="mt-8 flex w-full items-center justify-center gap-2 rounded-xl bg-accent py-3 text-sm font-semibold text-on-accent"
      >
        <ChromeGlyph name="merken" size={16} current />
        {saved ? s.inMappe : s.adoptMappe}
      </button>
      <p className="mt-3 text-center text-[11px] text-text-secondary">
        {s.savesTour}
      </p>
      <div className="mt-6 text-center text-sm">
        <Link href="/share" className="text-chrome hover:underline">
          {s.howToShare}
        </Link>
        {" · "}
        <Link href="/library" className="text-chrome hover:underline">
          {chrome.hofNav.platz}
        </Link>
      </div>
    </div>
  );
}
