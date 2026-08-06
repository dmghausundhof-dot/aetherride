/**
 * Sync-Stubs — Offline/Online + Ops-Log.
 * Ausführen: npx tsx src/lib/sync/opsLog.test.ts
 */
import {
  appendOp,
  buildSyncRequestStub,
  flushOpsLog,
  nextOpId,
  opsLogStats,
  pendingOps,
} from "./opsLog";
import { backoffMsForAttempt, getSyncClientState } from "./syncStatus";
import {
  OFFLINE_REGIONS_DEMO,
  canDownloadOfflineOnWeb,
} from "./offlineRegions";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

async function main() {
  assert(nextOpId().startsWith("op_"), "op id");
  assert(backoffMsForAttempt(0) === 1000, "backoff 0");
  assert(backoffMsForAttempt(10) === 32000, "backoff cap");
  assert(!canDownloadOfflineOnWeb(), "no PMTiles on web");
  assert(OFFLINE_REGIONS_DEMO.length >= 2, "regions");

  const before = opsLogStats().pending;
  appendOp({
    entity: "profile",
    entityId: "test",
    op: "update",
    payload: { t: 1 },
  });
  assert(pendingOps().length >= before + 1, "pending grew");

  const skipped = await flushOpsLog(false);
  assert(!!skipped.skipped && !!skipped.reason?.includes("F-ACC-002"), "no account");

  const offline = await flushOpsLog(true, { online: false });
  assert(!!offline.skipped && !!offline.reason?.includes("Offline"), "offline skip");

  const ok = await flushOpsLog(true, { online: true });
  assert(!ok.skipped && (ok.flushed ?? 0) >= 1, "flush demo");
  assert(!!ok.revision?.startsWith("rev_demo_"), "revision");

  const state = getSyncClientState(true);
  assert(typeof state.note === "string", "state note");
  assert(Array.isArray(buildSyncRequestStub(null).ops), "request stub");

  console.log("opsLog.test OK", {
    flushed: ok.flushed,
    pending: opsLogStats().pending,
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
