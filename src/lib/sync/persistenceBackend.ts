/**
 * Persistenz-Backend: Postgres (Supabase) oder File-Fallback
 */

import { isSupabaseConfigured } from "@/lib/supabase/config";

export type SyncPersistenceBackend = "postgres" | "file";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isUuidUserId(userId: string): boolean {
  return UUID_RE.test(userId);
}

/**
 * Postgres nur mit Supabase + UUID-User (auth.users).
 * FORCE_FILE_SYNC=true erzwingt File (Tests/Notfall).
 */
export function getSyncPersistenceBackend(
  userId?: string
): SyncPersistenceBackend {
  if (process.env.FORCE_FILE_SYNC === "true") return "file";
  if (!isSupabaseConfigured()) return "file";
  if (userId && !isUuidUserId(userId)) return "file";
  return "postgres";
}

export function syncPersistenceLabelDe(
  backend: SyncPersistenceBackend = getSyncPersistenceBackend()
): string {
  return backend === "postgres"
    ? "Supabase Postgres (sync_state + sync_ops)"
    : "File-Store data/sync (Fallback)";
}
