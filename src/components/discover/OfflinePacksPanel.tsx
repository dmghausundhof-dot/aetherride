"use client";

import { useCallback, useEffect, useState } from "react";
import { Download, HardDrive, Loader2 } from "lucide-react";

type PackRow = {
  id: string;
  name?: string;
  engines?: { offline_graph?: boolean; valhalla_tiles?: boolean };
  cdn?: { packGz?: string };
};

/**
 * Browser-Download für Offline-Region-Packs (API).
 * Aktivierung/Valhalla nur in der Mobile-App — hier ehrlich nur Download.
 */
export function OfflinePacksPanel({ className = "" }: { className?: string }) {
  const [packs, setPacks] = useState<PackRow[]>([]);
  const [note, setNote] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    void fetch("/api/offline/packs", { headers: { Accept: "application/json" } })
      .then(async (r) => {
        if (!r.ok) throw new Error(`HTTP ${r.status}`);
        return r.json() as Promise<{ packs?: PackRow[] }>;
      })
      .then((data) => {
        if (cancelled) return;
        setPacks(data.packs ?? []);
        setNote(
          (data.packs?.length ?? 0) === 0
            ? "Keine Packs im Katalog — Region-Build lokal ausführen."
            : null
        );
      })
      .catch(() => {
        if (!cancelled) {
          setPacks([]);
          setNote("Offline-Katalog nicht erreichbar.");
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const downloadPack = useCallback(async (pack: PackRow) => {
    const id = pack.id;
    setBusyId(id);
    setNote(null);
    try {
      let file = pack.cdn?.packGz ?? `${id}.tar.gz`;
      try {
        const manRes = await fetch(`/api/offline/packs/${id}`);
        if (manRes.ok) {
          const man = (await manRes.json()) as {
            cdn?: { packGz?: string };
          };
          if (man.cdn?.packGz) file = man.cdn.packGz;
        }
      } catch {
        /* Katalog-Default behalten */
      }
      const res = await fetch(`/api/offline/packs/${id}/${file}`);
      if (!res.ok) throw new Error(`Download HTTP ${res.status}`);
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = file;
      a.click();
      URL.revokeObjectURL(url);
      setNote(
        `${pack.name ?? id}: Download gestartet. Aktivierung nur in der Mobile-App (Offline-Sheet).`
      );
    } catch (e) {
      setNote(e instanceof Error ? e.message : "Download fehlgeschlagen");
    } finally {
      setBusyId(null);
    }
  }, []);

  return (
    <div
      className={`rounded-2xl border border-border bg-surface p-4 ${className}`}
    >
      <h3 className="mb-1 flex items-center gap-2 font-semibold">
        <HardDrive className="h-4 w-4 text-accent" aria-hidden />
        Offline-Regionen
      </h3>
      <p className="mb-3 text-xs text-text-secondary">
        Pack als .tar.gz herunterladen. Routing/Karten-Aktivierung läuft in der
        Android/iOS-App (Valhalla / offline_graph).
      </p>
      {loading ? (
        <p className="text-xs text-text-secondary">Katalog…</p>
      ) : packs.length === 0 ? (
        <p className="text-xs text-text-secondary">
          {note ?? "Keine Packs verfügbar."}
        </p>
      ) : (
        <ul className="flex flex-col gap-2">
          {packs.map((p) => (
            <li
              key={p.id}
              className="flex items-center justify-between gap-2 rounded-xl border border-border px-3 py-2"
            >
              <div className="min-w-0">
                <div className="truncate text-sm font-medium">
                  {p.name ?? p.id}
                </div>
                <div className="text-[11px] text-text-secondary">
                  {p.engines?.valhalla_tiles
                    ? "Valhalla-Tiles"
                    : "offline_graph"}
                </div>
              </div>
              <button
                type="button"
                disabled={busyId === p.id}
                onClick={() => void downloadPack(p)}
                aria-label={`Offline-Pack ${p.name ?? p.id} herunterladen`}
                className="inline-flex shrink-0 items-center gap-1 rounded-lg bg-accent px-2.5 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
              >
                {busyId === p.id ? (
                  <Loader2 className="h-3.5 w-3.5 animate-spin" aria-hidden />
                ) : (
                  <Download className="h-3.5 w-3.5" aria-hidden />
                )}
                Laden
              </button>
            </li>
          ))}
        </ul>
      )}
      {note && packs.length > 0 && (
        <p className="mt-2 text-[11px] text-text-secondary">{note}</p>
      )}
    </div>
  );
}
