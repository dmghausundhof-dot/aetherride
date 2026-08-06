"use client";

import { useEffect, useState } from "react";
import { useAppStore } from "@/store/useAppStore";
import {
  getSyncClientState,
  syncChipLabel,
  type SyncClientState,
} from "@/lib/sync/syncStatus";

export function SyncStatusChip() {
  const syncEnabled = useAppStore((s) => s.authSession.syncEnabled);
  const [state, setState] = useState<SyncClientState>(() =>
    getSyncClientState(false)
  );

  useEffect(() => {
    const refresh = () => setState(getSyncClientState(syncEnabled));
    refresh();
    window.addEventListener("online", refresh);
    window.addEventListener("offline", refresh);
    const id = window.setInterval(refresh, 4000);
    return () => {
      window.removeEventListener("online", refresh);
      window.removeEventListener("offline", refresh);
      window.clearInterval(id);
    };
  }, [syncEnabled]);

  return (
    <div
      className="rounded-lg border border-border bg-surface-elevated px-2 py-1 text-[10px] text-text-secondary"
      role="status"
      aria-live="polite"
      title={state.note}
    >
      <span className="font-medium text-foreground">{syncChipLabel(state)}</span>
      <span className="mx-1 opacity-40">·</span>
      <span>{state.note}</span>
    </div>
  );
}
