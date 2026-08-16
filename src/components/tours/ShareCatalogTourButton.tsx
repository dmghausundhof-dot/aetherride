"use client";

import { useState } from "react";
import { Check, Link2 } from "lucide-react";
import {
  encodeTourShareToken,
  shareTourPath,
} from "@/lib/community/shareCodec";
import type { PublicTour } from "@/lib/catalog/publicTours";
import type { SavedRoute } from "@/types/route";
import { useChromeLang } from "@/hooks/useChromeLang";
import { catalogCopy } from "@/lib/i18n/catalogCopy";

export function ShareCatalogTourButton({ tour }: { tour: PublicTour }) {
  const t = catalogCopy(useChromeLang()).tour;
  const [copied, setCopied] = useState(false);
  const [url, setUrl] = useState<string | null>(null);

  const copy = async () => {
    const route: SavedRoute = {
      id: tour.id,
      name: tour.name,
      distanceKm: tour.distanceKm,
      elevationM: tour.elevationM,
      durationMin: tour.durationMin,
      savedAt: new Date().toISOString(),
      source: "suggestion",
    };
    const { token } = encodeTourShareToken(route, "FlowLine-Katalog");
    const path = shareTourPath(token);
    const full =
      typeof window !== "undefined" ? `${window.location.origin}${path}` : path;
    setUrl(full);
    try {
      await navigator.clipboard.writeText(full);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* URL bleibt sichtbar */
    }
  };

  return (
    <div className="mt-3 space-y-1">
      <button
        type="button"
        onClick={() => void copy()}
        className="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-2 text-xs font-semibold hover:border-chrome/40"
      >
        {copied ? (
          <Check className="h-3.5 w-3.5 text-success" />
        ) : (
          <Link2 className="h-3.5 w-3.5 text-chrome" />
        )}
        {copied ? t.linkCopied : t.copyLink}
      </button>
      {url ? (
        <a
          href={url}
          className="block max-w-full truncate text-[10px] text-chrome hover:underline"
        >
          {url}
        </a>
      ) : (
        <p className="text-[11px] text-text-secondary">{t.noTrackHint}</p>
      )}
    </div>
  );
}
