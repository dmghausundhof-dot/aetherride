"use client";

import { useState } from "react";
import { RadGlyph } from "@/components/garage/RadGlyph";
import { BikeStandEditor } from "@/components/garage/BikeStandEditor";
import { useAppStore } from "@/store/useAppStore";
import { useHofCopy } from "@/hooks/useHofCopy";

/**
 * Strava-Hinweis plus derselbe Stand-Dialog wie unter dem Foto.
 * Kein zweites km/h-Formular, kein stiller Sync.
 */
export function OdometerImportPanel({
  bikeId,
  odometerKm,
  hours,
}: {
  bikeId: string;
  odometerKm: number;
  hours: number;
}) {
  const copy = useHofCopy();
  const updateBike = useAppStore((s) => s.updateBike);
  const addMaintenanceLog = useAppStore((s) => s.addMaintenanceLog);
  const [open, setOpen] = useState(false);

  return (
    <section
      className="rounded-2xl border border-border bg-surface p-4"
      data-testid="odometer-import-panel"
    >
      <h3 className="flex items-center gap-2 font-semibold">
        <RadGlyph name="identity" size={16} />
        {copy.workshopStandTitle}
      </h3>
      <p className="mt-1 text-xs text-text-secondary">{copy.workshopStandHint}</p>
      <p className="mt-1 text-xs text-text-secondary">
        {copy.workshopStandStravaHint}
      </p>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="mt-3 min-h-11 w-full rounded-xl bg-chrome py-2.5 text-sm font-semibold text-on-accent"
      >
        {copy.workshopStandOpen}
      </button>
      {open ? (
        <BikeStandEditor
          km={odometerKm}
          hours={hours}
          onClose={() => setOpen(false)}
          onSave={({ km, hours: nextHours }) => {
            updateBike(bikeId, {
              totalOdometerKm: km,
              totalHours: nextHours,
            });
            addMaintenanceLog({
              bikeId,
              date: new Date().toISOString().slice(0, 10),
              activity: copy.workshopStandTitle,
              performer: "self",
              notes: `${km.toFixed(0)} km · ${nextHours.toFixed(1)} h`,
              odometerKm: km,
              hours: nextHours,
            });
            setOpen(false);
          }}
        />
      ) : null}
    </section>
  );
}
