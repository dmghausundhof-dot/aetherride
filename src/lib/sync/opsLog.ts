/**
 * Spec 5.6 — Sync-Engine (Ops-Log)
 *
 * Client führt append-only Ops-Log; Sync bei Konto + WLAN/Online.
 * Web-Demo: lokaler Queue-Persist + Flush-Stub.
 */

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
}

const KEY = "aetherride.opsLog.v1";

function load(): OpsEntry[] {
  if (typeof window === "undefined") return [];
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as OpsEntry[]) : [];
  } catch {
    return [];
  }
}

function save(entries: OpsEntry[]) {
  if (typeof window === "undefined") return;
  localStorage.setItem(KEY, JSON.stringify(entries.slice(-2000)));
}

export function appendOp(
  entry: Omit<OpsEntry, "id" | "clientTs" | "synced">
): OpsEntry {
  const full: OpsEntry = {
    ...entry,
    id: `op_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 6)}`,
    clientTs: new Date().toISOString(),
    synced: false,
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
 * Flush: in Produktion POST /sync. Hier Stub — markiert als synced wenn syncEnabled.
 */
export async function flushOpsLog(syncEnabled: boolean): Promise<{
  flushed: number;
  skipped: boolean;
  reason?: string;
}> {
  if (!syncEnabled) {
    return {
      flushed: 0,
      skipped: true,
      reason: "Sync erfordert Konto (F-ACC-002)",
    };
  }
  const pending = pendingOps();
  if (!pending.length) return { flushed: 0, skipped: false };
  // Demo: kein Netzwerk — lokal als synchronisiert markieren
  await new Promise((r) => setTimeout(r, 200));
  markSynced(pending.map((p) => p.id));
  return { flushed: pending.length, skipped: false };
}

export function opsLogStats() {
  const all = load();
  return {
    total: all.length,
    pending: all.filter((e) => !e.synced).length,
    synced: all.filter((e) => e.synced).length,
  };
}
