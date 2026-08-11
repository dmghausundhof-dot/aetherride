"use client";

import { useAppStore } from "@/store/useAppStore";
import type { SyncConflictState } from "@/lib/sync/webSync";
import { summarizePayload } from "@/lib/sync/webSync";

export function SyncConflictPanel({
  conflict,
  busy,
  onKeepRemote,
  onKeepLocal,
  onDismiss,
}: {
  conflict: SyncConflictState;
  busy?: boolean;
  onKeepRemote: () => void;
  onKeepLocal: () => void;
  onDismiss?: () => void;
}) {
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const savedRoutes = useAppStore((s) => s.savedRoutes);
  const routeCollections = useAppStore((s) => s.routeCollections);

  const remoteAt = conflict.remoteUpdatedAt
    ? new Date(conflict.remoteUpdatedAt).toLocaleString("de-DE")
    : "—";
  const localAt = conflict.localUpdatedAt
    ? new Date(conflict.localUpdatedAt).toLocaleString("de-DE")
    : "—";

  return (
    <div
      className="rounded-2xl border border-warning/50 bg-warning/10 p-4"
      role="alert"
    >
      <h3 className="font-semibold text-warning">Sync-Konflikt</h3>
      <p className="mt-1 text-xs text-text-secondary">
        Cloud und dieses Gerät haben beide Änderungen. Wähle, welche Version
        gilt.
      </p>
      <div className="mt-3 grid gap-2 text-xs sm:grid-cols-2">
        <div className="rounded-xl border border-border bg-background/60 p-3">
          <p className="font-medium">Cloud</p>
          <p className="mt-1 text-text-secondary">
            {summarizePayload(conflict.remote)}
          </p>
          <p className="mt-1 tabular-nums text-text-secondary">{remoteAt}</p>
        </div>
        <div className="rounded-xl border border-border bg-background/60 p-3">
          <p className="font-medium">Dieses Gerät</p>
          <p className="mt-1 text-text-secondary">
            {summarizePayload({
              bikes,
              rides,
              savedRoutes,
              routeCollections,
            })}
          </p>
          <p className="mt-1 tabular-nums text-text-secondary">{localAt}</p>
        </div>
      </div>
      <div className="mt-4 flex flex-wrap gap-2">
        <button
          type="button"
          disabled={busy}
          onClick={onKeepRemote}
          className="rounded-xl bg-accent px-3 py-2 text-xs font-semibold text-white disabled:opacity-40"
        >
          Cloud behalten
        </button>
        <button
          type="button"
          disabled={busy}
          onClick={onKeepLocal}
          className="rounded-xl border border-border px-3 py-2 text-xs font-semibold disabled:opacity-40"
        >
          Gerät erzwingen
        </button>
        {onDismiss && (
          <button
            type="button"
            disabled={busy}
            onClick={onDismiss}
            className="rounded-xl px-3 py-2 text-xs text-text-secondary"
          >
            Später
          </button>
        )}
      </div>
    </div>
  );
}
