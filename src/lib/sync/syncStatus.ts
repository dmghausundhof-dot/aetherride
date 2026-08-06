/**
 * Sync-Status & Online-Erkennung (Spec 5.6 / F-ACC-002 / NFR-15)
 */

import { opsLogStats, pendingOps } from "./opsLog";
import {
  getLastConflictCount,
  getLastFlushAt,
  getPulledServerOps,
  getServerRevisionCursor,
} from "./syncMeta";

export interface SyncClientState {
  online: boolean;
  syncEnabled: boolean;
  pending: number;
  synced: number;
  total: number;
  lastFlushAt: string | null;
  /** Demo: nächster Backoff-Versuch (ms) */
  nextBackoffMs: number;
  serverRevisionCursor: string | null;
  lastConflicts: number;
  lastPulled: number;
  note: string;
}

export function isBrowserOnline(): boolean {
  if (typeof navigator === "undefined") return true;
  return navigator.onLine;
}

/** Exponentieller Backoff-Stub: 1s, 2s, 4s … max 32s */
export function backoffMsForAttempt(attempt: number): number {
  const base = 1000 * Math.pow(2, Math.max(0, attempt));
  return Math.min(base, 32000);
}

export function getSyncClientState(syncEnabled: boolean): SyncClientState {
  const stats = opsLogStats();
  const online = isBrowserOnline();
  const lastConflicts = getLastConflictCount();
  const lastPulled = getPulledServerOps();
  let note: string;
  if (!syncEnabled) {
    note = "Lokal · Sync aus (Konto nötig, F-ACC-002)";
  } else if (!online) {
    note = "Offline · Queue lokal (NFR-15)";
  } else if (stats.pending > 0) {
    note = `${stats.pending} ausstehend · Sync v2 bereit`;
  } else if (lastConflicts > 0) {
    note = `Synchron · ${lastConflicts} Konflikt(e) (LWW)`;
  } else {
    note = "Synchron (Server v2)";
  }
  return {
    online,
    syncEnabled,
    pending: stats.pending,
    synced: stats.synced,
    total: stats.total,
    lastFlushAt: getLastFlushAt(),
    nextBackoffMs: backoffMsForAttempt(Math.min(stats.pending, 5)),
    serverRevisionCursor: getServerRevisionCursor(),
    lastConflicts,
    lastPulled,
    note,
  };
}

export function syncChipLabel(state: SyncClientState): string {
  if (!state.syncEnabled) return "Lokal · Sync aus";
  if (!state.online) return "Offline";
  if (state.pending > 0) return `${state.pending} pending`;
  if (state.lastConflicts > 0) return `${state.lastConflicts} conflicts`;
  return "Sync ok";
}

export function describePendingOps(limit = 5): string[] {
  return pendingOps()
    .slice(0, limit)
    .map((o) => `${o.op} ${o.entity}:${o.entityId}`);
}
