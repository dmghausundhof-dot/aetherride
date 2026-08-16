"use client";

import { useMemo, useState } from "react";
import { MapView } from "@/components/MapView";
import { BikeOverlayLegend } from "@/components/BikeOverlayLegend";
import { detailOverlayRegionIdForPoint } from "@/lib/coverage/dachRegions";
import {
  MAP_ATTRIBUTION,
  ONLINE_BASEMAP_RIDER,
  type OnlineBasemapId,
  riderBasemap,
} from "@/lib/map/onlineBasemap";
import {
  BIKE_WAYS_MIN_ZOOM,
  chooseOnlineBikeOverlay,
} from "@/lib/map/onlineCycleMesh";
import { KARTEN_PAGE } from "@/lib/content/kartenCopy";

const HAUSBERGE: Array<{
  name: string;
  center: [number, number];
  zoom: number;
  blatt: OnlineBasemapId;
}> = [
  { name: "Heidelberg", center: [8.68, 49.41], zoom: 13, blatt: "dach-z11" },
  { name: "Freiburg", center: [7.85, 47.99], zoom: 13, blatt: "dach-z11" },
  { name: "Vogesen", center: [6.9, 47.95], zoom: 12.6, blatt: "dach-z11" },
  { name: "Zermatt", center: [7.75, 46.02], zoom: 13, blatt: "dach-z11" },
  { name: "Innsbruck", center: [11.4, 47.27], zoom: 13, blatt: "dach-z11" },
  { name: "Paris", center: [2.35, 48.86], zoom: 13, blatt: "france-west-z11" },
  { name: "Lyon", center: [4.835, 45.76], zoom: 13, blatt: "france-west-z11" },
  { name: "Annecy", center: [6.13, 45.9], zoom: 13, blatt: "alps-south-z11" },
];

export function KartenPreview({
  initialId = "dach-z11",
}: {
  initialId?: OnlineBasemapId;
}) {
  const [id, setId] = useState<OnlineBasemapId>(initialId);
  const [overlayOn, setOverlayOn] = useState(true);
  const [jump, setJump] = useState(0);
  const [view, setView] = useState(() => {
    const r = riderBasemap(initialId);
    return { center: r.center, zoom: r.zoom };
  });
  const region = useMemo(() => riderBasemap(id), [id]);
  const overlay = useMemo(() => {
    const [lng, lat] = view.center;
    return chooseOnlineBikeOverlay({
      regionId: detailOverlayRegionIdForPoint(lng, lat),
      lng,
      lat,
      zoom: view.zoom,
      archiveId: id,
    });
  }, [view, id]);

  function selectBlatt(next: OnlineBasemapId) {
    const r = riderBasemap(next);
    setId(next);
    setView({ center: r.center, zoom: r.zoom });
    setJump((n) => n + 1);
  }

  function flyHausberg(h: (typeof HAUSBERGE)[number]) {
    setId(h.blatt);
    setView({ center: h.center, zoom: h.zoom });
    setJump((n) => n + 1);
  }

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
              onClick={() => selectBlatt(r.id)}
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
      {HAUSBERGE.some((h) => h.blatt === id) && (
        <div className="mt-3 flex flex-wrap gap-2">
          {HAUSBERGE.filter((h) => h.blatt === id).map((h) => (
            <button
              key={h.name}
              type="button"
              onClick={() => flyHausberg(h)}
              className="rounded-full border border-border px-3 py-1 text-[11px] font-medium text-text-secondary transition hover:border-chrome/40 hover:text-foreground"
            >
              {h.name}
            </button>
          ))}
        </div>
      )}
      <div className="mt-4 overflow-hidden rounded-2xl border border-border">
        <div className="relative">
        <MapView
          key={`${id}-${jump}`}
          center={view.center}
          zoom={view.zoom}
          className="h-[min(52vh,460px)]"
          bikeOverlayUrl={overlay.url}
          bikeOverlayKind="pmtiles"
          bikeOverlayFamily="road"
          bikeOverlayVisible={overlayOn}
          bikeOverlayMinZoom={overlay.kind === "ways" ? 10 : 5}
          onViewChange={(next) => setView(next)}
        />
        <div className="pointer-events-auto absolute left-3 top-3 z-10">
          <BikeOverlayLegend
            family="road"
            visible={overlayOn}
            extraOn={[]}
            hasOverlayData={overlay.kind !== "none"}
            overlayKind={overlay.kind === "ways" ? "ways" : "mesh"}
            onToggleVisible={() => setOverlayOn((v) => !v)}
            onToggleClass={() => setOverlayOn(true)}
          />
        </div>
        </div>
      </div>
      <p className="mt-3 text-sm text-text-secondary">
        <span className="font-medium text-foreground">{region.name}.</span>{" "}
        {region.teaser} {region.hole}
      </p>
      <p className="mt-1 text-xs text-text-secondary">
        {overlay.kind === "ways"
          ? `Wege ab Zoom ${BIKE_WAYS_MIN_ZOOM} · ${MAP_ATTRIBUTION}`
          : MAP_ATTRIBUTION}
      </p>
    </div>
  );
}
