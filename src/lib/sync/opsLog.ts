/**
 * Spec 5.6 — Sync-Engine (Ops-Log)
 *
 * Client führt append-only Ops-Log; Sync bei Konto + Online.
 * Web-Demo: lokaler Queue-Persist + Flush-Stub (kein echtes Backend).
 *
 * Produktions-Shape POST /sync:
 * { since?: serverRevision, ops: OpsEntry[] } → { revision, ackedIds[], conflicts[] }
 */

import {
  bumpServerRevisionCursor,
  setLastFlushAt,
} from "./syncMeta";

export type OpsEntity =
  | "bike"
  | "component"
  | "setup"
  | "ride"
  | "maintenance"
  | "consent"
  | "profile"
  | "calibration";

export interface OpsEntry {
  id: string;
  entity: OpsEntity;
  entityId: string;
  op: "create" | "update" | "delete";
  payload: unknown;
  clientTs: string;
  synced: boolean;
  /** Demo-Cursor für Delta-Sync since= */
  clientRevision?: string;
}

const KEY = "aetherride.opsLog.v1";

/** In-Memory für SSR/Tests (kein window) */
let memoryLog: OpsEntry[] = [];

/** UUIDv7-ähnlich: Zeitpräfix + Zufall (Demo, nicht kryptographisch) */
export function nextOpId(): string {
  const t = Date.now().toString(16).padStart(12, "0");
  const r = Math.random().toString(16).slice(2, 10);
  return `op_${t}${r}`;
}

function load(): OpsEntry[] {
  if (typeof window === "undefined") return memoryLog;
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as OpsEntry[]) : [];
  } catch {
    return [];
  }
}

function save(entries: OpsEntry[]) {
  if (typeof window === "undefined") {
    memoryLog = entries.slice(-2000);
    return;
  }
  localStorage.setItem(KEY, JSON.stringify(entries.slice(-2000)));
}

export function appendOp(
  entry: Omit<OpsEntry, "id" | "clientTs" | "synced">
): OpsEntry {
  const full: OpsEntry = {
    ...entry,
    id: nextOpId(),
    clientTs: new Date().toISOString(),
    synced: false,
    clientRevision: `c_${Date.now().toString(36)}`,
  };
  const all = load();
  all.push(full);
  save(all);
  return full;
}

export function pendingOps(): OpsEntry[] {
  return load().filter((e) => !e.synced);
}

export function markSynced(ids: string[]) {
  const set = new Set(ids);
  const all = load().map((e) => (set.has(e.id) ? { ...e, synced: true } : e));
  save(all);
}

/**
 * Flush: in Produktion POST /sync mit since=<cursor>.
 * Demo: markiert lokal synced wenn syncEnabled + (optional) online.
 */
export async function flushOpsLog(
  syncEnabled: boolean,
  opts?: { requireOnline?: boolean; online?: boolean }
): Promise<{
  flushed: number;
  skipped: boolean;
  reason?: string;
  revision?: string;
}> {
  if (!syncEnabled) {
    return {
      flushed: 0,
      skipped: true,
      reason: "Sync erfordert Konto (F-ACC-002)",
    };
  }
  const online = opts?.online ?? (typeof navigator === "undefined" ? true : navigator.onLine);
  if (opts?.requireOnline !== false && !online) {
    return {
      flushed: 0,
      skipped: true,
      reason: "Offline — Queue bleibt lokal (NFR-15)",
    };
  }
  const pending = pendingOps();
  if (!pending.length) return { flushed: 0, skipped: false };
  // Demo: kein Netzwerk — lokal als synchronisiert markieren
  await new Promise((r) => setTimeout(r, 200));
  markSynced(pending.map((p) => p.id));
  const revision = bumpServerRevisionCursor();
  setLastFlushAt(new Date().toISOString());
  return { flushed: pending.length, skipped: false, revision };
}

export function opsLogStats() {
  const all = load();
  return {
    total: all.length,
    pending: all.filter((e) => !e.synced).length,
    synced: all.filter((e) => e.synced).length,
  };
}

/** Dokumentiertes Request-Shape für Native/Backend */
export function buildSyncRequestStub(since: string | null) {
  return {
    since,
    ops: pendingOps().map((o) => ({
      operation_id: o.id,
      entity: o.entity,
      entity_id: o.entityId,
      op: o.op,
      client_ts: o.clientTs,
      payload: o.payload,
    })),
  };
}
