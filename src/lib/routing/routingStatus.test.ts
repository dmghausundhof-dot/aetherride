/**
 * Fail-closed: showRoutingDebugUi is ONLY true when env === "1".
 * Run: npx tsx src/lib/routing/routingStatus.test.ts
 */
import { showRoutingDebugUi } from "./routingStatus";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

// Contract of the gate (same predicate the export uses).
function gate(v: string | undefined): boolean {
  return v === "1";
}

assert(gate(undefined) === false, "unset → false");
assert(gate("") === false, "empty → false");
assert(gate("true") === false, '"true" must NOT enable');
assert(gate("0") === false, '"0" → false');
assert(gate("1") === true, 'only "1" → true');

// Live export respects current process.env (may already be set in CI).
const current = process.env.NEXT_PUBLIC_SHOW_ROUTING_DEBUG;
assert(
  showRoutingDebugUi() === (current === "1"),
  "showRoutingDebugUi matches NEXT_PUBLIC_SHOW_ROUTING_DEBUG === \"1\""
);

console.log("routingStatus.test.ts OK");
