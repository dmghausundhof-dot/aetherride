"use client";

import { Compass, Mountain, Route, Sparkles } from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { bikeTypeLabel } from "@/lib/utils";

const demoRoutes = [
  {
    id: "1",
    name: "Enduro Alpbachtal",
    type: "enduro",
    distance: 28.4,
    elevation: 1240,
    difficulty: "Schwer",
    match: 94,
  },
  {
    id: "2",
    name: "Gravel Loop Kitzbühel",
    type: "gravel",
    distance: 62.1,
    elevation: 890,
    difficulty: "Mittel",
    match: 87,
  },
  {
    id: "3",
    name: "Flow Trail Söll",
    type: "all_mountain",
    distance: 18.7,
    elevation: 720,
    difficulty: "Mittel",
    match: 91,
  },
  {
    id: "4",
    name: "E-MTB Hochkönig",
    type: "e_mtb",
    distance: 41.2,
    elevation: 1580,
    difficulty: "Schwer",
    match: 88,
  },
];

export default function DiscoverPage() {
  const activeBikeId = useAppStore((s) => s.activeBikeId);
  const bikes = useAppStore((s) => s.bikes);
  const activeBike = bikes.find((b) => b.id === activeBikeId) || bikes[0];

  return (
    <div className="flex flex-col gap-5 p-4 pt-6">
      <header>
        <h1 className="text-2xl font-bold">Discover</h1>
        <p className="text-sm text-text-secondary">
          KI-Routen basierend auf deinem Bike & Fahrstil
        </p>
      </header>

      {activeBike && (
        <div className="rounded-xl bg-primary/20 px-3 py-2 text-sm">
          <span className="text-text-secondary">Aktuelles Bike: </span>
          <span className="font-medium">{activeBike.name}</span>
          <span className="text-text-secondary"> · {bikeTypeLabel(activeBike.type)}</span>
        </div>
      )}

      {/* Filters */}
      <div className="flex gap-2 overflow-x-auto pb-1">
        {["Alle", "Enduro", "Gravel", "E-MTB", "Wandern"].map((f) => (
          <button
            key={f}
            className={`flex-shrink-0 rounded-full px-4 py-1.5 text-sm font-medium transition ${
              f === "Alle"
                ? "bg-accent text-white"
                : "bg-surface border border-border text-text-secondary"
            }`}
          >
            {f}
          </button>
        ))}
      </div>

      {/* KI Suggestions */}
      <section>
        <h3 className="mb-3 flex items-center gap-2 font-semibold">
          <Sparkles className="h-4 w-4 text-accent" /> Empfohlen für dich
        </h3>
        <div className="flex flex-col gap-3">
          {demoRoutes.map((route) => (
            <div
              key={route.id}
              className="rounded-2xl bg-surface border border-border p-4 transition active:scale-[0.99]"
            >
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="font-semibold">{route.name}</h4>
                  <p className="text-sm text-text-secondary">
                    {bikeTypeLabel(route.type)} · {route.difficulty}
                  </p>
                </div>
                <div className="rounded-full bg-accent/20 px-2.5 py-1 text-xs font-bold text-accent">
                  {route.match}% Match
                </div>
              </div>
              <div className="mt-3 flex gap-4 text-sm">
                <div className="flex items-center gap-1.5 text-text-secondary">
                  <Route className="h-4 w-4" />
                  <span className="tabular-nums">{route.distance} km</span>
                </div>
                <div className="flex items-center gap-1.5 text-text-secondary">
                  <Mountain className="h-4 w-4" />
                  <span className="tabular-nums">{route.elevation} hm</span>
                </div>
              </div>
              <button className="mt-3 w-full rounded-xl bg-surface-elevated py-2 text-sm font-medium text-accent">
                Route öffnen
              </button>
            </div>
          ))}
        </div>
      </section>

      <div className="rounded-xl border border-dashed border-border p-4 text-center text-sm text-text-secondary">
        <Compass className="mx-auto mb-2 h-8 w-8 opacity-40" />
        Offline-Routing & Heatmaps in Produktion verfügbar
      </div>
    </div>
  );
}
