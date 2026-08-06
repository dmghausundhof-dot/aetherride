/**
 * Sync-Persistenz auf Supabase Postgres (RLS, Session-User)
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  EntityServerState,
  IncomingSyncOp,
} from "./conflictMerge";
import type { PersistedOp, UserSyncStore } from "./serverStoreTypes";

const MAX_OPS = 5000;
const MAX_SEEN = 8000;

function emptyStore(userId: string): UserSyncStore {
  return {
    version: 2,
    userId,
    revision: "rev_0",
    revisionSeq: 0,
    seenOpIds: [],
    ops: [],
    entities: {},
    updatedAt: new Date().toISOString(),
  };
}

type StateRow = {
  user_id: string;
  revision: string;
  revision_seq: number;
  seen_op_ids: unknown;
  entities: unknown;
  updated_at: string;
};

type OpRow = {
  operation_id: string;
  entity: string;
  entity_id: string;
  op: string;
  client_ts: string;
  server_ts: string;
  revision: string;
  payload: unknown;
};

function asStringArray(v: unknown): string[] {
  return Array.isArray(v) ? v.map(String) : [];
}

function asEntities(v: unknown): Record<string, EntityServerState> {
  if (v && typeof v === "object" && !Array.isArray(v)) {
    return v as Record<string, EntityServerState>;
  }
  return {};
}

export async function loadUserSyncStorePostgres(
  supabase: SupabaseClient,
  userId: string
): Promise<UserSyncStore> {
  const { data: state, error: stateErr } = await supabase
    .from("sync_state")
    .select("*")
    .eq("user_id", userId)
    .maybeSingle();

  if (stateErr) {
    throw new Error(`sync_state: ${stateErr.message}`);
  }

  const { data: ops, error: opsErr } = await supabase
    .from("sync_ops")
    .select(
      "operation_id, entity, entity_id, op, client_ts, server_ts, revision, payload"
    )
    .eq("user_id", userId)
    .order("id", { ascending: true })
    .limit(MAX_OPS);

  if (opsErr) {
    throw new Error(`sync_ops: ${opsErr.message}`);
  }

  if (!state) {
    const empty = emptyStore(userId);
    return empty;
  }

  const row = state as StateRow;
  return {
    version: 2,
    userId,
    revision: row.revision,
    revisionSeq: row.revision_seq,
    seenOpIds: asStringArray(row.seen_op_ids),
    entities: asEntities(row.entities),
    updatedAt: row.updated_at,
    ops: ((ops ?? []) as OpRow[]).map((o) => ({
      operation_id: o.operation_id,
      entity: o.entity,
      entity_id: o.entity_id,
      op: o.op as IncomingSyncOp["op"],
      client_ts: o.client_ts,
      payload: o.payload,
      server_ts: o.server_ts,
      revision: o.revision,
    })),
  };
}

export async function saveUserSyncStorePostgres(
  supabase: SupabaseClient,
  store: UserSyncStore,
  newlyApplied: PersistedOp[]
): Promise<void> {
  const { error: upsertErr } = await supabase.from("sync_state").upsert(
    {
      user_id: store.userId,
      revision: store.revision,
      revision_seq: store.revisionSeq,
      seen_op_ids: store.seenOpIds.slice(-MAX_SEEN),
      entities: store.entities,
      updated_at: new Date().toISOString(),
    },
    { onConflict: "user_id" }
  );
  if (upsertErr) {
    throw new Error(`sync_state upsert: ${upsertErr.message}`);
  }

  if (newlyApplied.length) {
    const rows = newlyApplied.map((op) => ({
      user_id: store.userId,
      operation_id: op.operation_id,
      entity: op.entity,
      entity_id: op.entity_id,
      op: op.op,
      client_ts: op.client_ts,
      server_ts: op.server_ts,
      revision: op.revision,
      payload: op.payload ?? null,
    }));
    const { error: insertErr } = await supabase.from("sync_ops").upsert(rows, {
      onConflict: "user_id,operation_id",
      ignoreDuplicates: true,
    });
    if (insertErr) {
      throw new Error(`sync_ops insert: ${insertErr.message}`);
    }
  }
}
