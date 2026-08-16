"use client";

import { useCallback, useEffect, useState } from "react";
import { Download, HardDrive, Loader2 } from "lucide-react";
import { useChromeLang } from "@/hooks/useChromeLang";
import { DISCOVER_STATUS_DE, discoverStatus, discoverUi } from "@/lib/i18n/discoverUi";

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
  const lang = useChromeLang();
  const d = discoverUi(lang);
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
            ? DISCOVER_STATUS_DE.packsEmpty
            : null
        );
      })
      .catch(() => {
        if (!cancelled) {
          setPacks([]);
          setNote(DISCOVER_STATUS_DE.packsUnreachable);
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
        d.packsStarted(pack.name ?? id),
      );
    } catch (e) {
      setNote(e instanceof Error ? e.message : d.packsFail);
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
        {d.packsTitle}
      </h3>
      <p className="mb-3 text-xs text-text-secondary">
        {d.packsLead}
      </p>
      {loading ? (
        <p className="text-xs text-text-secondary">{d.packsCatalog}</p>
      ) : packs.length === 0 ? (
        <p className="text-xs text-text-secondary">
          {discoverStatus(note, lang) || d.packsNone}
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
                      ? d.packsNotBuilt
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
                  aria-label={d.packsDownload(p.name ?? p.id)}
                  className="inline-flex shrink-0 items-center gap-1 rounded-xl bg-accent px-2.5 py-1.5 text-xs font-semibold text-on-accent disabled:opacity-50"
                >
                  {busyId === p.id ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" aria-hidden />
                  ) : (
                    <Download className="h-3.5 w-3.5" aria-hidden />
                  )}
                  {ready ? d.packsLoad : d.packsStub}
                </button>
              </li>
            );
          })}
        </ul>
      )}
      {note && packs.length > 0 && (
        <p className="mt-2 text-[11px] text-text-secondary">
          {discoverStatus(note, lang) || note}
        </p>
      )}
    </div>
  );
}
