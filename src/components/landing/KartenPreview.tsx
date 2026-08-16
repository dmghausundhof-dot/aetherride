"use client";

import { useMemo, useState } from "react";
import { MapView } from "@/components/MapView";
import {
  MAP_ATTRIBUTION,
  ONLINE_BASEMAP_RIDER,
  type OnlineBasemapId,
  riderBasemap,
} from "@/lib/map/onlineBasemap";
import { KARTEN_PAGE } from "@/lib/content/kartenCopy";

export function KartenPreview({
  initialId = "dach-z11",
}: {
  initialId?: OnlineBasemapId;
}) {
  const [id, setId] = useState<OnlineBasemapId>(initialId);
  const region = useMemo(() => riderBasemap(id), [id]);

  return (
    <div>
      <p className="text-sm text-text-secondary">{KARTEN_PAGE.previewHint}</p>
      <div className="mt-4 flex flex-wrap gap-2">
        {ONLINE_BASEMAP_RIDER.map((r) => {
          const on = r.id === id;
          return (
            <button
              key={r.id}
              type="button"
              onClick={() => setId(r.id)}
              className={
                on
                  ? "rounded-full border border-chrome/50 bg-chrome/10 px-3 py-1 text-xs font-semibold text-chrome"
                  : "rounded-full border border-border px-3 py-1 text-xs font-medium transition hover:border-chrome/40"
              }
            >
              {r.name}
            </button>
          );
        })}
      </div>
      <div className="mt-4 overflow-hidden rounded-2xl border border-border">
        <MapView
          key={id}
          center={region.center}
          zoom={region.zoom}
          className="h-[min(52vh,460px)]"
        />
      </div>
      <p className="mt-3 text-sm text-text-secondary">
        <span className="font-medium text-foreground">{region.name}.</span>{" "}
        {region.teaser} {region.hole}
      </p>
      <p className="mt-1 text-xs text-text-secondary">{MAP_ATTRIBUTION}</p>
    </div>
  );
}
