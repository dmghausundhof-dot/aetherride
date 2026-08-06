/**
 * Spec 5.6 — Sync-Engine (Ops-Log)
 *
 * Client: append-only Ops-Log.
 * Sync v2: POST /api/sync mit since= + LWW-Merge (authentifiziert).
 */

import {
  bumpServerRevisionCursor,
  getServerRevisionCursor,
  markConflicts,
  setLastFlushAt,
  setPulledCount,
  setServerRevisionCursor,
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

export type FlushResult = {
  flushed: number;
  skipped: boolean;
  reason?: string;
  revision?: string;
  via?: "server_v2" | "local_test";
  attempt?: number;
  conflicts?: number;
  pulled?: number;
};

/**
 * Flush gegen Sync v2 (auth + LWW).
 * `useApiStub: false` → nur lokaler Test-Flush (kein Server-Claim).
 */
export async function flushOpsLog(
  syncEnabled: boolean,
  opts?: {
    requireOnline?: boolean;
    online?: boolean;
    /** Default true: POST /api/sync. false = lokaler Test-Pfad */
    useApiStub?: boolean;
  }
): Promise<FlushResult> {
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
  const useApi = opts?.useApiStub !== false;

  if (useApi && typeof fetch !== "undefined") {
    try {
      const since = getServerRevisionCursor();
      const body = buildSyncRequestStub(since);
      const res = await fetch("/api/sync", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
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
          conflicts?: { operation_id: string; reason: string }[];
          pulledOps?: unknown[];
          appliedCount?: number;
        };
        const ids = data.ackedIds?.length
          ? data.ackedIds
          : pending.map((p) => p.id);
        markSynced(ids);
        if (data.revision) {
          setServerRevisionCursor(data.revision);
        }
        const conflicts = Array.isArray(data.conflicts) ? data.conflicts.length : 0;
        const pulled = Array.isArray(data.pulledOps) ? data.pulledOps.length : 0;
        markConflicts(conflicts);
        setPulledCount(pulled);
        setLastFlushAt(new Date().toISOString());
        recordFlushAttempt(true);
        return {
          flushed: ids.length,
          skipped: false,
          revision: data.revision,
          via: "server_v2",
          attempt: getFlushAttemptCount(),
          conflicts,
          pulled,
        };
      }
      recordFlushAttempt(false);
      const errPayload = (await res.json().catch(() => null)) as {
        error?: string;
      } | null;
      return {
        flushed: 0,
        skipped: true,
        reason: errPayload?.error ?? `Sync HTTP ${res.status}`,
        attempt: getFlushAttemptCount(),
      };
    } catch (e) {
      recordFlushAttempt(false);
      return {
        flushed: 0,
        skipped: true,
        reason:
          e instanceof Error
            ? `Sync-Netzwerk: ${e.message}`
            : "Sync-Netzwerkfehler",
        attempt: getFlushAttemptCount(),
      };
    }
  }

  // Lokaler Test-Pfad (kein Server-Claim)
  if (!pending.length) {
    return { flushed: 0, skipped: false, via: "local_test" };
  }
  await new Promise((r) => setTimeout(r, 20));
  markSynced(pending.map((p) => p.id));
  const revision = bumpServerRevisionCursor();
  setLastFlushAt(new Date().toISOString());
  markConflicts(0);
  setPulledCount(0);
  recordFlushAttempt(true);
  return {
    flushed: pending.length,
    skipped: false,
    revision,
    via: "local_test",
    attempt: getFlushAttemptCount(),
    conflicts: 0,
    pulled: 0,
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

/** Request-Shape für Native/Backend (Sync v2) */
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

/** Legacy-Echo (ältere Tests) — Produktion nutzt serverStore */
export function buildSyncAckFromRequest(body: {
  ops?: { operation_id: string }[];
}): SyncAckResponse {
  const ids = (body.ops ?? []).map((o) => o.operation_id).filter(Boolean);
  return {
    revision: `rev_stub_${Date.now().toString(36)}`,
    ackedIds: ids,
    conflicts: [],
    note: "Legacy-Ack — Sync v2 nutzt serverStore + LWW.",
  };
}
