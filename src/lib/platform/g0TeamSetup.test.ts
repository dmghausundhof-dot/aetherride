/**
 * G-0 Team-Setup Gate — ehrlich offen.
 * Ausführen: npx tsx src/lib/platform/g0TeamSetup.test.ts
 */
import {
  G0_MOBILE_STACK_CONFIRMED,
  G0_DECISION,
  NATIVE_MODULE_MATRIX,
  evaluateG0GoNoGo,
  g0StatusBadge,
  g0StatusShort,
  isG0Closed,
} from "./g0TeamSetup";
import { webDemoCapabilities, SENSOR_BATCH_INVARIANTS } from "./nativeContracts";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G0_MOBILE_STACK_CONFIRMED === false, "G-0 master false");
assert(!isG0Closed(), "G-0 nicht closed");
assert(G0_DECISION.chosenStack === "undecided", "Stack undecided");
assert(G0_DECISION.checklist.some((c) => !c.done), "Checklist offen");
assert(NATIVE_MODULE_MATRIX.length >= 6, "Modul-Matrix");
assert(SENSOR_BATCH_INVARIANTS.noPerSampleMethodChannel, "Batch-Invariante");

const go = evaluateG0GoNoGo();
assert(go.result === "no_go", "ohne Entscheidung = no_go");
assert(g0StatusBadge().includes("offen"), "Badge offen");
assert(!g0StatusShort().toLowerCase().includes("bestätigt") || g0StatusShort().includes("unbestätigt"), "kein Fake-Confirm");

const caps = webDemoCapabilities();
assert(caps.flutter === false, "flutter false");
assert(caps.webDemoOnly === true, "web only");
assert(caps.g0Closed === false, "g0Closed false");

console.log("g0TeamSetup.test OK", { go: go.result, modules: NATIVE_MODULE_MATRIX.length });
