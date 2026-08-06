/**
 * Serverseitige Sync-Persistenz
 * Primär: Supabase Postgres · Fallback: File data/sync/
 */

import { promises as fs } from "fs";
import path from "path";
import {
  entityKey,
  mergeIncomingOps,
  type EntityServerState,
  type IncomingSyncOp,
} from "./conflictMerge";
import {
  getSyncPersistenceBackend,
  syncPersistenceLabelDe,
} from "./persistenceBackend";
import {
  loadUserSyncStorePostgres,
  saveUserSyncStorePostgres,
} from "./postgresStore";
import type {
  PersistedOp,
  SyncPushResult,
  UserSyncStore,
} from "./serverStoreTypes";

export type { PersistedOp, SyncPushResult, UserSyncStore } from "./serverStoreTypes";

const ROOT = path.join(process.cwd(), "data", "sync");
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

function storePath(userId: string): string {
  const safe = userId.replace(/[^a-zA-Z0-9_-]/g, "_");
  return path.join(ROOT, `${safe}.json`);
}

export async function loadUserSyncStoreFile(
  userId: string
): Promise<UserSyncStore> {
  await fs.mkdir(ROOT, { recursive: true });
  try {
    const raw = await fs.readFile(storePath(userId), "utf8");
    const parsed = JSON.parse(raw) as UserSyncStore;
    if (!parsed.version || parsed.version < 2) {
      return emptyStore(userId);
    }
    return parsed;
  } catch {
    return emptyStore(userId);
  }
}

async function saveUserSyncStoreFile(store: UserSyncStore): Promise<void> {
  await fs.mkdir(ROOT, { recursive: true });
  store.updatedAt = new Date().toISOString();
  await fs.writeFile(
    storePath(store.userId),
    JSON.stringify(store, null, 2),
    "utf8"
  );
}

function bumpRevision(store: UserSyncStore): string {
  store.revisionSeq += 1;
  store.revision = `rev_${store.revisionSeq}_${Date.now().toString(36)}`;
  return store.revision;
}

function entitiesToMap(
  entities: Record<string, EntityServerState>
): Map<string, EntityServerState> {
  return new Map(Object.entries(entities));
}

function mapToEntities(
  map: Map<string, EntityServerState>
): Record<string, EntityServerState> {
  return Object.fromEntries(map.entries());
}

export function opsSince(
  store: UserSyncStore,
  since: string | null | undefined
): PersistedOp[] {
  if (!since || since === "rev_0") return [...store.ops];
  const idx = store.ops.findIndex((o) => o.revision === since);
  if (idx < 0) {
    return store.ops.slice(-200);
  }
  return store.ops.slice(idx + 1);
}

export async function loadUserSyncStore(
  userId: string
): Promise<UserSyncStore> {
  const backend = getSyncPersistenceBackend(userId);
  if (backend === "postgres") {
    try {
      const { createSupabaseServerClient } = await import(
        "@/lib/supabase/server"
      );
      const supabase = await createSupabaseServerClient();
      return await loadUserSyncStorePostgres(supabase, userId);
    } catch (e) {
      console.warn(
        "[sync] Postgres load fehlgeschlagen → File-Fallback",
        e instanceof Error ? e.message : e
      );
      return loadUserSyncStoreFile(userId);
    }
  }
  return loadUserSyncStoreFile(userId);
}

/**
 * Push Client-Ops, Merge, Persist, optional Pull seit `since`.
 */
export async function pushUserOps(
  userId: string,
  incoming: IncomingSyncOp[],
  since?: string | null
): Promise<SyncPushResult> {
  let backend = getSyncPersistenceBackend(userId);
  let store: UserSyncStore;
  let usedPostgres = false;

  if (backend === "postgres") {
    try {
      const { createSupabaseServerClient } = await import(
        "@/lib/supabase/server"
      );
      const supabase = await createSupabaseServerClient();
      store = await loadUserSyncStorePostgres(supabase, userId);
      usedPostgres = true;
    } catch (e) {
      console.warn(
        "[sync] Postgres push-load fehlgeschlagen → File",
        e instanceof Error ? e.message : e
      );
      backend = "file";
      store = await loadUserSyncStoreFile(userId);
    }
  } else {
    store = await loadUserSyncStoreFile(userId);
  }

  const seen = new Set(store.seenOpIds);
  const existing = entitiesToMap(store.entities);
  const merged = mergeIncomingOps(incoming, existing, seen);

  const revision = bumpRevision(store);
  const serverTs = new Date().toISOString();
  const newlyApplied: PersistedOp[] = [];

  for (const op of merged.applied) {
    const persisted: PersistedOp = {
      ...op,
      server_ts: serverTs,
      revision,
    };
    store.ops.push(persisted);
    newlyApplied.push(persisted);
  }

  store.entities = mapToEntities(merged.nextStates);
  store.seenOpIds = Array.from(seen).slice(-MAX_SEEN);
  store.ops = store.ops.slice(-MAX_OPS);
  store.updatedAt = serverTs;

  if (usedPostgres) {
    try {
      const { createSupabaseServerClient } = await import(
        "@/lib/supabase/server"
      );
      const supabase = await createSupabaseServerClient();
      await saveUserSyncStorePostgres(supabase, store, newlyApplied);
    } catch (e) {
      console.warn(
        "[sync] Postgres save fehlgeschlagen → File",
        e instanceof Error ? e.message : e
      );
      await saveUserSyncStoreFile(store);
      usedPostgres = false;
      backend = "file";
    }
  } else {
    await saveUserSyncStoreFile(store);
  }

  const pulledOps = opsSince(store, since).filter(
    (o) => !merged.ackedIds.includes(o.operation_id)
  );

  return {
    revision,
    ackedIds: merged.ackedIds,
    conflicts: merged.conflicts,
    duplicates: merged.duplicates,
    appliedCount: merged.applied.length,
    pulledOps,
    persistence: usedPostgres ? "postgres" : "file",
    note: `${syncPersistenceLabelDe(usedPostgres ? "postgres" : "file")} · LWW Conflict-Merge.`,
  };
}

export async function getUserSyncStatus(userId: string): Promise<{
  revision: string;
  opCount: number;
  entityCount: number;
  updatedAt: string;
  persistence: "postgres" | "file";
}> {
  const store = await loadUserSyncStore(userId);
  const backend = getSyncPersistenceBackend(userId);
  return {
    revision: store.revision,
    opCount: store.ops.length,
    entityCount: Object.keys(store.entities).length,
    updatedAt: store.updatedAt,
    persistence: backend,
  };
}

export function peekEntity(
  store: UserSyncStore,
  entity: string,
  entityId: string
): EntityServerState | undefined {
  return store.entities[entityKey(entity, entityId)];
}
