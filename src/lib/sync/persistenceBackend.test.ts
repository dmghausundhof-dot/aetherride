/**
 * Persistenz-Backend — Unit-Tests
 * Ausführen: npx tsx src/lib/sync/persistenceBackend.test.ts
 */
import {
  getSyncPersistenceBackend,
  isUuidUserId,
  syncPersistenceLabelDe,
} from "./persistenceBackend";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

function main() {
  assert(
    isUuidUserId("550e8400-e29b-41d4-a716-446655440000"),
    "valid uuid"
  );
  assert(!isUuidUserId("usr_local_abc"), "local id not uuid");

  // Ohne Supabase-Env → file
  assert(getSyncPersistenceBackend() === "file", "default file");
  assert(
    getSyncPersistenceBackend("usr_x") === "file",
    "non-uuid file"
  );
  assert(syncPersistenceLabelDe("file").includes("File"), "label file");
  assert(
    syncPersistenceLabelDe("postgres").includes("Postgres"),
    "label pg"
  );

  console.log("persistenceBackend.test OK");
}

main();
