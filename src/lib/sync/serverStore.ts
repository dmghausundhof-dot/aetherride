/**
 * Serverseitige Sync-Persistenz (File → später Postgres)
 * User-scoped append-only Ops + Entity-Snapshots + Revision.
 */

import { promises as fs } from "fs";
import path from "path";
import {
  entityKey,
  mergeIncomingOps,
  type EntityServerState,
  type IncomingSyncOp,
  type SyncConflict,
} from "./conflictMerge";

export interface PersistedOp extends IncomingSyncOp {
  server_ts: string;
  revision: string;
}

export interface UserSyncStore {
  version: 2;
  userId: string;
  revision: string;
  revisionSeq: number;
  /** Alle jemals gesehenen Op-IDs (Idempotenz) */
  seenOpIds: string[];
  /** Append-only Log (kappt auf maxOps) */
  ops: PersistedOp[];
  /** Aktueller Entity-Stand */
  entities: Record<string, EntityServerState>;
  updatedAt: string;
}

export interface SyncPushResult {
  revision: string;
  ackedIds: string[];
  conflicts: SyncConflict[];
  duplicates: string[];
  appliedCount: number;
  pulledOps: PersistedOp[];
  note: string;
}

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

export async function loadUserSyncStore(userId: string): Promise<UserSyncStore> {
  await fs.mkdir(ROOT, { recursive: true });
  try {
    const raw = await fs.readFile(storePath(userId), "utf8");
    const parsed = JSON.parse(raw) as UserSyncStore;
    if (!parsed.version || parsed.version < 2) {
      // migrate v1 revision log → empty v2
      return emptyStore(userId);
    }
    return parsed;
  } catch {
    return emptyStore(userId);
  }
}

async function saveUserSyncStore(store: UserSyncStore): Promise<void> {
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

/** Ops mit revision > since (lexikographisch unsicher — nutze Seq aus rev_N_) */
export function opsSince(
  store: UserSyncStore,
  since: string | null | undefined
): PersistedOp[] {
  if (!since || since === "rev_0") return [...store.ops];
  const idx = store.ops.findIndex((o) => o.revision === since);
  if (idx < 0) {
    // unknown cursor → full replay of recent ops
    return store.ops.slice(-200);
  }
  return store.ops.slice(idx + 1);
}

/**
 * Push Client-Ops, Merge, Persist, optional Pull seit `since`.
 */
export async function pushUserOps(
  userId: string,
  incoming: IncomingSyncOp[],
  since?: string | null
): Promise<SyncPushResult> {
  const store = await loadUserSyncStore(userId);
  const seen = new Set(store.seenOpIds);
  const existing = entitiesToMap(store.entities);
  const merged = mergeIncomingOps(incoming, existing, seen);

  const revision = bumpRevision(store);
  const serverTs = new Date().toISOString();

  for (const op of merged.applied) {
    store.ops.push({
      ...op,
      server_ts: serverTs,
      revision,
    });
  }

  store.entities = mapToEntities(merged.nextStates);
  store.seenOpIds = Array.from(seen).slice(-MAX_SEEN);
  store.ops = store.ops.slice(-MAX_OPS);
  await saveUserSyncStore(store);

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
    note:
      "User-scoped File-Store v2 + LWW Conflict-Merge — Postgres-Adapter folgt (Roadmap 4).",
  };
}

export async function getUserSyncStatus(userId: string): Promise<{
  revision: string;
  opCount: number;
  entityCount: number;
  updatedAt: string;
}> {
  const store = await loadUserSyncStore(userId);
  return {
    revision: store.revision,
    opCount: store.ops.length,
    entityCount: Object.keys(store.entities).length,
    updatedAt: store.updatedAt,
  };
}

/** Für Tests / Debug */
export function peekEntity(
  store: UserSyncStore,
  entity: string,
  entityId: string
): EntityServerState | undefined {
  return store.entities[entityKey(entity, entityId)];
}
