"use client";

import { useCallback, useEffect, useState } from "react";
import { Download, HardDrive, Loader2 } from "lucide-react";

type PackRow = {
  id: string;
  name?: string;
  engines?: { offline_graph?: boolean; valhalla_tiles?: boolean };
  cdn?: { baseUrl?: string; packGz?: string };
  downloadable?: boolean;
  status?: "ready" | "stub";
  bytes?: number | null;
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
      let cdnBase = pack.cdn?.baseUrl?.replace(/\/$/, "") ?? "";
      try {
        const manRes = await fetch(`/api/offline/packs/${id}`);
        if (manRes.ok) {
          const man = (await manRes.json()) as {
            cdn?: { baseUrl?: string; packGz?: string };
          };
          if (man.cdn?.packGz) file = man.cdn.packGz;
          if (man.cdn?.baseUrl) cdnBase = man.cdn.baseUrl.replace(/\/$/, "");
        }
      } catch {
        /* Katalog-Default behalten */
      }
      const urls = [
        ...(cdnBase ? [`${cdnBase}/${file}`] : []),
        `/api/offline/packs/${id}/${file}`,
      ];
      let res: Response | null = null;
      for (const u of urls) {
        res = await fetch(u);
        if (res.ok) break;
      }
      if (!res?.ok) throw new Error(`Download HTTP ${res?.status ?? 0}`);
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
        Nur gebaute Packs sind ladbar. Aktivierung (Routing + Kartenkacheln)
        läuft in der Android/iOS-App.
      </p>
      {loading ? (
        <p className="text-xs text-text-secondary">Katalog…</p>
      ) : packs.length === 0 ? (
        <p className="text-xs text-text-secondary">
          {note ?? "Keine Packs verfügbar."}
        </p>
      ) : (
        <ul className="flex flex-col gap-2">
          {packs.map((p) => {
            const ready = p.downloadable !== false && p.status !== "stub";
            const size =
              typeof p.bytes === "number" && p.bytes > 0
                ? `${(p.bytes / (1024 * 1024)).toFixed(1)} MB`
                : null;
            return (
              <li
                key={p.id}
                className="flex items-center justify-between gap-2 rounded-xl border border-border px-3 py-2"
              >
                <div className="min-w-0">
                  <div className="truncate text-sm font-medium">
                    {p.name ?? p.id}
                  </div>
                  <div className="text-[11px] text-text-secondary">
                    {!ready
                      ? "Noch nicht gebaut"
                      : [
                          size,
                          p.engines?.valhalla_tiles
                            ? "Valhalla-Tiles"
                            : "offline_graph",
                        ]
                          .filter(Boolean)
                          .join(" · ")}
                  </div>
                </div>
                <button
                  type="button"
                  disabled={!ready || busyId === p.id}
                  onClick={() => void downloadPack(p)}
                  aria-label={`Offline-Pack ${p.name ?? p.id} herunterladen`}
                  className="inline-flex shrink-0 items-center gap-1 rounded-lg bg-accent px-2.5 py-1.5 text-xs font-semibold text-white disabled:opacity-50"
                >
                  {busyId === p.id ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" aria-hidden />
                  ) : (
                    <Download className="h-3.5 w-3.5" aria-hidden />
                  )}
                  {ready ? "Laden" : "Stub"}
                </button>
              </li>
            );
          })}
        </ul>
      )}
      {note && packs.length > 0 && (
        <p className="mt-2 text-[11px] text-text-secondary">{note}</p>
      )}
    </div>
  );
}
