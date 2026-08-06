/**
 * Gemeinsame Sync-Store-Typen (File + Postgres)
 */

import type {
  EntityServerState,
  IncomingSyncOp,
  SyncConflict,
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
  seenOpIds: string[];
  ops: PersistedOp[];
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
  persistence?: "postgres" | "file";
}
