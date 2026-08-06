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
 * Demo: versucht optional /api/sync; sonst lokal markieren.
 */
export async function flushOpsLog(
  syncEnabled: boolean,
  opts?: {
    requireOnline?: boolean;
    online?: boolean;
    /** Wenn true: POST /api/sync Stub (Echo-Ack), sonst rein lokal */
    useApiStub?: boolean;
  }
): Promise<{
  flushed: number;
  skipped: boolean;
  reason?: string;
  revision?: string;
  via?: "local_demo" | "api_stub";
  attempt?: number;
}> {
  if (!syncEnabled) {
    recordFlushAttempt(false);
    return {
      flushed: 0,
      skipped: true,
      reason: "Sync erfordert Konto (F-ACC-002)",
      attempt: getFlushAttemptCount(),
    };
  }
  const online =
    opts?.online ??
    (typeof navigator === "undefined" ? true : navigator.onLine);
  if (opts?.requireOnline !== false && !online) {
    recordFlushAttempt(false);
    return {
      flushed: 0,
      skipped: true,
      reason: "Offline — Queue bleibt lokal (NFR-15)",
      attempt: getFlushAttemptCount(),
    };
  }
  const pending = pendingOps();
  if (!pending.length) return { flushed: 0, skipped: false };

  if (opts?.useApiStub !== false && typeof fetch !== "undefined") {
    try {
      const body = buildSyncRequestStub(null);
      const res = await fetch("/api/sync", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      if (res.status === 401) {
        recordFlushAttempt(false);
        return {
          flushed: 0,
          skipped: true,
          reason: "Sync erfordert Anmeldung — bitte unter /login einloggen",
          attempt: getFlushAttemptCount(),
        };
      }
      if (res.ok) {
        const data = (await res.json()) as {
          revision?: string;
          ackedIds?: string[];
        };
        const ids = data.ackedIds?.length
          ? data.ackedIds
          : pending.map((p) => p.id);
        markSynced(ids);
        const revision = data.revision ?? bumpServerRevisionCursor();
        setLastFlushAt(new Date().toISOString());
        recordFlushAttempt(true);
        return {
          flushed: ids.length,
          skipped: false,
          revision,
          via: "api_stub",
          attempt: getFlushAttemptCount(),
        };
      }
    } catch {
      // Fallback lokal nur wenn API nicht erreichbar (Tests/Offline)
    }
  }

  await new Promise((r) => setTimeout(r, 200));
  markSynced(pending.map((p) => p.id));
  const revision = bumpServerRevisionCursor();
  setLastFlushAt(new Date().toISOString());
  recordFlushAttempt(true);
  return {
    flushed: pending.length,
    skipped: false,
    revision,
    via: "local_demo",
    attempt: getFlushAttemptCount(),
  };
}

const ATTEMPT_KEY = "aetherride.sync.flushAttempts";

function recordFlushAttempt(success: boolean) {
  if (typeof window === "undefined") {
    memoryAttempts = success ? 0 : memoryAttempts + 1;
    return;
  }
  if (success) {
    localStorage.setItem(ATTEMPT_KEY, "0");
    return;
  }
  const n = getFlushAttemptCount() + 1;
  localStorage.setItem(ATTEMPT_KEY, String(n));
}

let memoryAttempts = 0;

export function getFlushAttemptCount(): number {
  if (typeof window === "undefined") return memoryAttempts;
  try {
    return Number(localStorage.getItem(ATTEMPT_KEY) || "0") || 0;
  } catch {
    return 0;
  }
}

export function opsLogStats() {
  const all = load();
  return {
    total: all.length,
    pending: all.filter((e) => !e.synced).length,
    synced: all.filter((e) => e.synced).length,
    flushAttempts: getFlushAttemptCount(),
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

export interface SyncAckResponse {
  revision: string;
  ackedIds: string[];
  conflicts: { operation_id: string; reason: string }[];
  note: string;
}

/** Server-Echo für /api/sync — kein Multi-Device-Claim */
export function buildSyncAckFromRequest(body: {
  ops?: { operation_id: string }[];
}): SyncAckResponse {
  const ids = (body.ops ?? []).map((o) => o.operation_id).filter(Boolean);
  return {
    revision: `rev_stub_${Date.now().toString(36)}`,
    ackedIds: ids,
    conflicts: [],
    note: "Demo-Ack — kein echtes Multi-Device-Sync (F-ACC-002 Stub).",
  };
}
