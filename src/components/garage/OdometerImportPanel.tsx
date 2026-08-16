"use client";

import { useState } from "react";
import { Upload } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";

/**
 * Manuelle km/h-Korrektur + Hinweis auf Strava-Sync (Marktstandard).
 * Volle OAuth-Strava-Anbindung folgt — hier klarer Import-Pfad ohne Fake-Sync.
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
  const updateBike = useAppStore((s) => s.updateBike);
  const addMaintenanceLog = useAppStore((s) => s.addMaintenanceLog);
  const [km, setKm] = useState(String(Math.round(odometerKm)));
  const [h, setH] = useState(hours.toFixed(1));
  const [saved, setSaved] = useState(false);

  const apply = () => {
    const nextKm = Math.max(0, Number(km) || 0);
    const nextH = Math.max(0, Number(h) || 0);
    updateBike(bikeId, {
      totalOdometerKm: nextKm,
      totalHours: nextH,
    });
    addMaintenanceLog({
      bikeId,
      date: new Date().toISOString().slice(0, 10),
      activity: "Kilometerstand aktualisiert",
      performer: "self",
      notes: `Manuell / Import: ${nextKm.toFixed(0)} km · ${nextH.toFixed(1)} h`,
      odometerKm: nextKm,
      hours: nextH,
    });
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <section className="rounded-2xl border border-border bg-surface p-4">
      <h3 className="flex items-center gap-2 font-semibold">
        <Upload className="h-4 w-4 text-accent" />
        Kilometer & Stunden
      </h3>
      <p className="mt-1 text-xs text-text-secondary">
        Stand von Computer, Bosch oder Strava-Gear übernehmen. Automatischer
        Strava-Sync ist geplant — bis dahin manueller Import (wie in den meisten
        Garage-Apps beim Erst-Setup).
      </p>
      <div className="mt-3 grid grid-cols-2 gap-2">
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-xs text-text-secondary">km gesamt</span>
          <input
            type="number"
            min={0}
            value={km}
            onChange={(e) => setKm(e.target.value)}
            className="rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
        <label className="flex flex-col gap-1 text-sm">
          <span className="text-xs text-text-secondary">Stunden</span>
          <input
            type="number"
            min={0}
            step={0.1}
            value={h}
            onChange={(e) => setH(e.target.value)}
            className="rounded-xl border border-border bg-surface-elevated px-3 py-2"
          />
        </label>
      </div>
      <button
        type="button"
        onClick={apply}
        className="mt-3 w-full rounded-xl bg-accent py-2.5 text-sm font-semibold text-on-accent"
      >
        {saved ? "Gespeichert" : "Stand übernehmen"}
      </button>
    </section>
  );
}
