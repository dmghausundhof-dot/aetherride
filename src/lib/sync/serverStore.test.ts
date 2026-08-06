/**
 * User Sync Store — Unit-Tests (tmp dir)
 * Ausführen: npx tsx src/lib/sync/serverStore.test.ts
 */
import { promises as fs } from "fs";
import path from "path";
import os from "os";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

async function main() {
  // Isoliere data/sync über cwd-Wechsel in temp
  const tmp = await fs.mkdtemp(path.join(os.tmpdir(), "aether-sync-"));
  const prev = process.cwd();
  process.chdir(tmp);

  try {
    // Dynamischer Import nach cwd-Wechsel
    const { pushUserOps, loadUserSyncStore, opsSince, peekEntity } =
      await import("./serverStore");

    const userId = "user_test_1";
    const r1 = await pushUserOps(
      userId,
      [
        {
          operation_id: "op_1",
          entity: "bike",
          entity_id: "bk1",
          op: "create",
          client_ts: "2026-06-01T10:00:00.000Z",
          payload: { name: "Trail" },
        },
      ],
      null
    );
    assert(r1.appliedCount === 1, "applied 1");
    assert(r1.ackedIds.includes("op_1"), "acked");
    assert(r1.conflicts.length === 0, "no conflicts");
    assert(r1.revision.startsWith("rev_1_"), "rev1");

    const store1 = await loadUserSyncStore(userId);
    assert(peekEntity(store1, "bike", "bk1")?.lastOpId === "op_1", "entity");

    // Ältere Op → Konflikt
    const r2 = await pushUserOps(
      userId,
      [
        {
          operation_id: "op_stale",
          entity: "bike",
          entity_id: "bk1",
          op: "update",
          client_ts: "2026-05-01T10:00:00.000Z",
          payload: { name: "Stale" },
        },
      ],
      r1.revision
    );
    assert(r2.conflicts.length === 1, "stale conflict");
    assert(r2.appliedCount === 0, "stale not applied");

    // Duplikat
    const r3 = await pushUserOps(
      userId,
      [
        {
          operation_id: "op_1",
          entity: "bike",
          entity_id: "bk1",
          op: "create",
          client_ts: "2026-06-01T10:00:00.000Z",
        },
      ],
      r2.revision
    );
    assert(r3.duplicates.includes("op_1"), "dup");

    // Neuere Op + Delta-Pull
    const r4 = await pushUserOps(
      userId,
      [
        {
          operation_id: "op_2",
          entity: "bike",
          entity_id: "bk1",
          op: "update",
          client_ts: "2026-06-02T10:00:00.000Z",
          payload: { name: "Trail Pro" },
        },
      ],
      r1.revision
    );
    assert(r4.appliedCount === 1, "op2 applied");
    const store = await loadUserSyncStore(userId);
    const delta = opsSince(store, r1.revision);
    assert(delta.length >= 1, "delta since r1");
    assert(
      (peekEntity(store, "bike", "bk1")?.payload as { name?: string } | undefined)
        ?.name === "Trail Pro",
      "payload updated"
    );

    // Persistenz-Datei
    const file = path.join(tmp, "data", "sync", "user_test_1.json");
    const raw = await fs.readFile(file, "utf8");
    const parsed = JSON.parse(raw) as { version: number };
    assert(parsed.version === 2, "store v2 on disk");

    console.log("serverStore.test OK", {
      revision: r4.revision,
      ops: store.ops.length,
    });
  } finally {
    process.chdir(prev);
    await fs.rm(tmp, { recursive: true, force: true });
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
