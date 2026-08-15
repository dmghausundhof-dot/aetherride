"use client";

/**
 * Bibliothek: gespeicherte Touren, Sammlungen, GPX-Import, Offline-Packs.
 */
import { useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import {
  Bookmark,
  FolderPlus,
  Play,
  Route,
  Trash2,
  Upload,
} from "lucide-react";
import { useAppStore } from "@/store/useAppStore";
import { parseGpx } from "@/lib/import/gpx";
import { OfflinePacksPanel } from "@/components/discover/OfflinePacksPanel";
import { ShareCollectionButton } from "@/components/community/ShareCollectionButton";
import { AddRouteForm } from "@/components/library/AddRouteForm";
import { activeRouteFromSuggestion } from "@/lib/routing/activeRoute";
import type { SavedRoute } from "@/types/route";
import type { RouteSuggestion } from "@/lib/routing/suggestions";

function savedToSuggestion(r: SavedRoute): RouteSuggestion {
  return {
    id: r.id,
    name: r.name,
    category: "road",
    distanceKm: r.distanceKm,
    elevationM: r.elevationM,
    durationMin: r.durationMin,
    mtbScale: r.mtbScale ?? "—",
    surface: r.surface ?? "—",
    loop: r.loop ?? false,
    uncertainKmPct: 5,
    matchScore: 80,
    reasons: r.reasons ?? ["Gespeicherte Tour", "Bibliothek", r.source],
  };
}

export default function LibraryPage() {
  const router = useRouter();
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const unsaveRoute = useAppStore((s) => s.unsaveRoute);
  const saveRoute = useAppStore((s) => s.saveRoute);
  const routeCollections = useAppStore((s) => s.routeCollections);
  const createRouteCollection = useAppStore((s) => s.createRouteCollection);
  const addRouteToCollection = useAppStore((s) => s.addRouteToCollection);
  const setActiveRoute = useAppStore((s) => s.setActiveRoute);

  const [collectionName, setCollectionName] = useState("");
  const [msg, setMsg] = useState<string | null>(null);
  const gpxRef = useRef<HTMLInputElement | null>(null);

  const importGpx = async (file: File | null) => {
    if (!file) return;
    try {
      const text = await file.text();
      const parsed = parseGpx(text, file.name.replace(/\.gpx$/i, ""));
      if (!parsed?.coordinates?.length) {
        setMsg("GPX ohne Track");
        return;
      }
      const entry: SavedRoute = {
        id: `gpx-${Date.now()}`,
        name: parsed.name || "GPX Import",
        distanceKm: Math.round(parsed.distanceKm * 10) / 10,
        elevationM: Math.round(parsed.elevationM),
        durationMin: parsed.durationMin,
        surface: "import",
        loop: false,
        savedAt: new Date().toISOString(),
        source: "import",
        geometry: {
          type: "LineString",
          coordinates: parsed.coordinates,
        },
      };
      saveRoute(entry);
      setMsg(`Importiert: ${entry.name}`);
    } catch {
      setMsg("GPX konnte nicht gelesen werden");
    }
  };

  const openInApp = (r: SavedRoute) => {
    const s = savedToSuggestion(r);
    setActiveRoute(
      activeRouteFromSuggestion(s, r.geometry ?? null)
    );
    router.push("/ride");
  };

  return (
    <div className="mx-auto max-w-4xl px-4 py-8 sm:px-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Gespeichert</h1>
          <p className="mt-1 text-sm text-text-secondary">
            Hinter der Karte — lokale Touren und Sammlungen, kein fünfter Tab.
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Link
            href="/discover?sheet=plan"
            className="inline-flex items-center gap-1.5 rounded-xl bg-chrome px-3 py-2 text-sm font-semibold text-background"
          >
            <Route className="h-4 w-4" /> Planen
          </Link>
          <Link
            href="/discover"
            className="inline-flex items-center gap-1.5 rounded-xl border border-border px-3 py-2 text-sm font-medium"
          >
            Karte
          </Link>
        </div>
      </div>

      {msg && (
        <p className="mt-4 rounded-lg border border-border bg-surface px-3 py-2 text-xs text-text-secondary">
          {msg}
        </p>
      )}

      <section className="mt-8">
        <div className="mb-3 flex items-center justify-between gap-2">
          <h2 className="text-sm font-semibold uppercase tracking-wide text-text-secondary">
            Meine Touren ({savedRoutes.length})
          </h2>
          <div>
            <input
              ref={gpxRef}
              type="file"
              accept=".gpx,application/gpx+xml,text/xml"
              className="hidden"
              onChange={(e) => {
                void importGpx(e.target.files?.[0] ?? null);
                e.target.value = "";
              }}
            />
            <button
              type="button"
              onClick={() => gpxRef.current?.click()}
              className="inline-flex items-center gap-1.5 rounded-lg border border-border px-2.5 py-1.5 text-xs font-medium"
            >
              <Upload className="h-3.5 w-3.5" /> GPX importieren
            </button>
          </div>
        </div>
        <div className="mb-3">
          <AddRouteForm />
        </div>

        {savedRoutes.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border p-8 text-center">
            <Bookmark className="mx-auto h-8 w-8 text-text-secondary" />
            <p className="mt-3 text-sm text-text-secondary">
              Noch nichts gespeichert. Route hinzufügen, Touren speichern oder
              GPX importieren.
            </p>
            <Link
              href="/regions"
              className="mt-4 inline-block text-sm font-semibold text-accent"
            >
              Regionen entdecken →
            </Link>
          </div>
        ) : (
          <ul className="space-y-3">
            {savedRoutes.map((r) => (
              <li
                key={r.id}
                className="rounded-2xl border border-border bg-surface p-4"
              >
                <div className="flex flex-wrap items-start justify-between gap-3">
                  <div className="min-w-0">
                    <h3 className="font-semibold">{r.name}</h3>
                    <p className="mt-0.5 text-xs tabular-nums text-text-secondary">
                      {r.distanceKm} km · {r.elevationM} hm · {r.durationMin}{" "}
                      min
                      {r.source === "import" ? " · GPX" : ""}
                      {r.geometry ? " · Track" : ""}
                    </p>
                    <p className="mt-1 text-[11px] text-text-secondary">
                      Gespeichert{" "}
                      {new Date(r.savedAt).toLocaleDateString("de-DE")}
                    </p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {routeCollections.length > 0 && (
                      <select
                        className="rounded-lg border border-border bg-background px-2 py-1.5 text-[11px]"
                        defaultValue=""
                        onChange={(e) => {
                          const id = e.target.value;
                          if (!id) return;
                          addRouteToCollection(id, r.id);
                          setMsg("Zur Sammlung hinzugefügt");
                          e.target.value = "";
                        }}
                      >
                        <option value="" disabled>
                          + Sammlung
                        </option>
                        {routeCollections.map((c) => (
                          <option key={c.id} value={c.id}>
                            {c.name}
                          </option>
                        ))}
                      </select>
                    )}
                    <Link
                      href={`/planner`}
                      className="rounded-lg border border-border px-2.5 py-1.5 text-[11px] font-medium"
                    >
                      Planen
                    </Link>
                    <button
                      type="button"
                      onClick={() => openInApp(r)}
                      className="inline-flex items-center gap-1 rounded-lg bg-accent px-2.5 py-1.5 text-[11px] font-semibold text-white"
                    >
                      <Play className="h-3 w-3 fill-current" /> In App
                    </button>
                    <button
                      type="button"
                      onClick={() => unsaveRoute(r.id)}
                      className="rounded-lg border border-border px-2 py-1.5 text-text-secondary"
                      aria-label="Entfernen"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="mt-10">
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-text-secondary">
          Sammlungen
        </h2>
        <div className="mb-3 flex gap-2">
          <input
            value={collectionName}
            onChange={(e) => setCollectionName(e.target.value)}
            placeholder="Name der Sammlung"
            className="min-w-0 flex-1 rounded-lg border border-border bg-surface px-3 py-2 text-sm"
          />
          <button
            type="button"
            onClick={() => {
              if (!collectionName.trim()) return;
              createRouteCollection(collectionName.trim());
              setCollectionName("");
              setMsg("Sammlung angelegt");
            }}
            className="inline-flex items-center gap-1 rounded-lg bg-accent px-3 py-2 text-sm font-semibold text-white"
          >
            <FolderPlus className="h-4 w-4" /> Anlegen
          </button>
        </div>
        {routeCollections.length === 0 ? (
          <p className="text-sm text-text-secondary">
            Noch keine Sammlung — z. B. „Wochenende“ oder „Alpen 2026“.
          </p>
        ) : (
          <ul className="space-y-2">
            {routeCollections.map((c) => (
              <li
                key={c.id}
                className="flex flex-wrap items-center justify-between gap-2 rounded-xl border border-border px-4 py-3"
              >
                <div>
                  <span className="font-medium">{c.name}</span>
                  <span className="ml-2 text-xs text-text-secondary">
                    {c.routeIds.length} Touren
                  </span>
                </div>
                <ShareCollectionButton collectionId={c.id} />
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="mt-10">
        <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-text-secondary">
          Offline-Packs
        </h2>
        <p className="mb-3 text-xs text-text-secondary">
          Packs für die App vormerken — Download und Navigation nativ.
        </p>
        <OfflinePacksPanel />
      </section>
    </div>
  );
}
