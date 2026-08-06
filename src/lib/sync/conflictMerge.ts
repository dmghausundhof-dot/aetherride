/**
 * F-ACC-002 — Conflict-Merge (Last-Write-Wins)
 *
 * Regeln:
 * - Gleicher operation_id → Duplikat, ack ohne erneutes Anwenden
 * - Gleicher entity+entityId: neueres client_ts gewinnt
 * - delete gewinnt über create/update bei gleichem/neuerem Timestamp
 * - Ältere Ops nach neuerem Server-State → conflict (nicht ack als applied)
 *
 * Postgres-fähig: reine Funktionen, kein I/O.
 */

export type SyncOpKind = "create" | "update" | "delete";

export interface IncomingSyncOp {
  operation_id: string;
  entity: string;
  entity_id: string;
  op: SyncOpKind;
  client_ts: string;
  payload?: unknown;
}

export interface EntityServerState {
  entity: string;
  entityId: string;
  lastOpId: string;
  lastOp: SyncOpKind;
  lastClientTs: string;
  lastServerTs: string;
  payload?: unknown;
  deleted: boolean;
}

export interface SyncConflict {
  operation_id: string;
  reason: string;
  serverLastTs?: string;
  serverLastOpId?: string;
}

export interface MergeResult {
  applied: IncomingSyncOp[];
  ackedIds: string[];
  conflicts: SyncConflict[];
  duplicates: string[];
  nextStates: Map<string, EntityServerState>;
}

export function entityKey(entity: string, entityId: string): string {
  return `${entity}::${entityId}`;
}

function tsMs(iso: string): number {
  const n = Date.parse(iso);
  return Number.isFinite(n) ? n : 0;
}

/**
 * Merged Incoming-Ops gegen bestehenden Entity-State.
 * `seenOpIds` verhindert Doppelverarbeitung derselben operation_id.
 */
export function mergeIncomingOps(
  incoming: IncomingSyncOp[],
  existing: Map<string, EntityServerState>,
  seenOpIds: Set<string>,
  serverNowIso = new Date().toISOString()
): MergeResult {
  const nextStates = new Map(existing);
  const applied: IncomingSyncOp[] = [];
  const ackedIds: string[] = [];
  const conflicts: SyncConflict[] = [];
  const duplicates: string[] = [];

  // Stable order by client_ts then operation_id
  const sorted = [...incoming].sort((a, b) => {
    const d = tsMs(a.client_ts) - tsMs(b.client_ts);
    if (d !== 0) return d;
    return a.operation_id.localeCompare(b.operation_id);
  });

  for (const op of sorted) {
    if (!op.operation_id || !op.entity || !op.entity_id) {
      conflicts.push({
        operation_id: op.operation_id || "unknown",
        reason: "Ungültige Op (id/entity/entity_id fehlen)",
      });
      continue;
    }

    if (seenOpIds.has(op.operation_id)) {
      duplicates.push(op.operation_id);
      ackedIds.push(op.operation_id); // idempotent ack
      continue;
    }

    const key = entityKey(op.entity, op.entity_id);
    const cur = nextStates.get(key);

    if (cur && tsMs(op.client_ts) < tsMs(cur.lastClientTs)) {
      conflicts.push({
        operation_id: op.operation_id,
        reason: `LWW: Server hat neueren Stand (${cur.lastClientTs})`,
        serverLastTs: cur.lastClientTs,
        serverLastOpId: cur.lastOpId,
      });
      // ältere Op nicht anwenden, aber als gesehen speichern
      seenOpIds.add(op.operation_id);
      continue;
    }

    if (
      cur &&
      tsMs(op.client_ts) === tsMs(cur.lastClientTs) &&
      op.operation_id !== cur.lastOpId
    ) {
      // Tie-break: höhere operation_id gewinnt; sonst conflict
      if (op.operation_id < cur.lastOpId) {
        conflicts.push({
          operation_id: op.operation_id,
          reason: "LWW Tie-Break: andere Op mit gleichem Timestamp gewinnt",
          serverLastTs: cur.lastClientTs,
          serverLastOpId: cur.lastOpId,
        });
        seenOpIds.add(op.operation_id);
        continue;
      }
    }

    const state: EntityServerState = {
      entity: op.entity,
      entityId: op.entity_id,
      lastOpId: op.operation_id,
      lastOp: op.op,
      lastClientTs: op.client_ts,
      lastServerTs: serverNowIso,
      payload: op.payload,
      deleted: op.op === "delete",
    };
    nextStates.set(key, state);
    seenOpIds.add(op.operation_id);
    applied.push(op);
    ackedIds.push(op.operation_id);
  }

  return { applied, ackedIds, conflicts, duplicates, nextStates };
}
