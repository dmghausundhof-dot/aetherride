/**
 * Conflict-Merge LWW — Unit-Tests
 * Ausführen: npx tsx src/lib/sync/conflictMerge.test.ts
 */
import {
  entityKey,
  mergeIncomingOps,
  type EntityServerState,
  type IncomingSyncOp,
} from "./conflictMerge";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

function op(
  partial: Partial<IncomingSyncOp> &
    Pick<IncomingSyncOp, "operation_id" | "entity_id" | "client_ts">
): IncomingSyncOp {
  return {
    entity: "bike",
    op: "update",
    ...partial,
  };
}

function main() {
  const seen = new Set<string>();
  const empty = new Map<string, EntityServerState>();

  // Apply first op
  const a = op({
    operation_id: "op_a",
    entity_id: "b1",
    client_ts: "2026-01-01T10:00:00.000Z",
    payload: { name: "A" },
  });
  let r = mergeIncomingOps([a], empty, seen, "2026-01-01T12:00:00.000Z");
  assert(r.applied.length === 1, "applied a");
  assert(r.conflicts.length === 0, "no conflict a");
  assert(r.nextStates.get(entityKey("bike", "b1"))?.payload !== undefined, "state");

  // Duplicate operation_id → ack, not re-apply
  r = mergeIncomingOps([a], r.nextStates, seen, "2026-01-01T12:01:00.000Z");
  assert(r.duplicates.includes("op_a"), "dup");
  assert(r.applied.length === 0, "no re-apply");
  assert(r.ackedIds.includes("op_a"), "dup ack");

  // Older ts → conflict
  const older = op({
    operation_id: "op_old",
    entity_id: "b1",
    client_ts: "2026-01-01T09:00:00.000Z",
    payload: { name: "OLD" },
  });
  r = mergeIncomingOps([older], r.nextStates, seen, "2026-01-01T12:02:00.000Z");
  assert(r.conflicts.length === 1, "older conflict");
  assert(r.applied.length === 0, "older not applied");
  assert(
    r.nextStates.get(entityKey("bike", "b1"))?.lastOpId === "op_a",
    "state unchanged"
  );

  // Newer wins
  const newer = op({
    operation_id: "op_new",
    entity_id: "b1",
    client_ts: "2026-01-01T11:00:00.000Z",
    payload: { name: "NEW" },
  });
  r = mergeIncomingOps([newer], r.nextStates, seen, "2026-01-01T12:03:00.000Z");
  assert(r.applied.length === 1, "newer applied");
  assert(r.nextStates.get(entityKey("bike", "b1"))?.lastOpId === "op_new", "new id");

  // Delete wins
  const del = op({
    operation_id: "op_del",
    entity_id: "b1",
    op: "delete",
    client_ts: "2026-01-01T11:30:00.000Z",
  });
  r = mergeIncomingOps([del], r.nextStates, seen, "2026-01-01T12:04:00.000Z");
  assert(r.nextStates.get(entityKey("bike", "b1"))?.deleted === true, "deleted");

  // Invalid op
  const badSeen = new Set<string>();
  r = mergeIncomingOps(
    [{ operation_id: "", entity: "", entity_id: "", op: "update", client_ts: "" }],
    new Map(),
    badSeen
  );
  assert(r.conflicts.length === 1, "invalid conflict");

  console.log("conflictMerge.test OK");
}

main();
