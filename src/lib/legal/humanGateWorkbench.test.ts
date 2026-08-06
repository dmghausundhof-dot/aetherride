/**
 * Human Gate Workbench — Flags bleiben false; Checklisten schließen keine Gates
 */
import {
  A06_LEGAL_REVIEW_PASSED,
} from "./a06OdblBrief";
import { A08_LEGAL_REVIEW_PASSED } from "./setupLiability";
import { G0_MOBILE_STACK_CONFIRMED } from "@/lib/platform/g0TeamSetup";
import { G1_BOSCH_ACCESS_CLEARED } from "@/lib/ble/g1BoschOutreach";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";
import { G5_LEGAL_REVIEW_PASSED } from "@/lib/routing/legalReview";
import {
  GATE_WORKBENCH,
  assertMasterFlagsStillFalse,
  gateReadiness,
  renderHumanGateWorkbenchMarkdown,
  resolvePackContent,
  workbenchSummaryDe,
} from "./humanGateWorkbench";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(assertMasterFlagsStillFalse(), "master flags false");
assert(G0_MOBILE_STACK_CONFIRMED === false, "G-0");
assert(G1_BOSCH_ACCESS_CLEARED === false, "G-1");
assert(G2_SUSPENSION_GATE_PASSED === false, "G-2");
assert(G5_LEGAL_REVIEW_PASSED === false, "G-5");
assert(A06_LEGAL_REVIEW_PASSED === false, "A-06");
assert(A08_LEGAL_REVIEW_PASSED === false, "A-08");

assert(GATE_WORKBENCH.length === 6, "six workbench gates");
assert(
  GATE_WORKBENCH.every((g) => g.flagValue === false),
  "workbench flagValue all false"
);
assert(
  GATE_WORKBENCH.every((g) => g.items.some((i) => i.id === "ready_for_code_flag")),
  "ready_for_code_flag on each"
);

for (const g of GATE_WORKBENCH) {
  const r = gateReadiness(g.gateId);
  assert(r.total === g.items.length, `${g.gateId} total`);
  assert(r.done === 0, `${g.gateId} starts empty (no window)`);
  assert(r.allDone === false, `${g.gateId} not done`);
}

const md = renderHumanGateWorkbenchMarkdown();
assert(md.includes("Human must sign"), "banner");
assert(md.includes("G-0"), "g0");
assert(md.includes("A-08"), "a08");
assert(md.includes("`false`"), "false in md");

for (const g of GATE_WORKBENCH) {
  for (const pack of g.packDownloads) {
    const body = resolvePackContent(pack.kind);
    assert(body != null && body.length > 100, `pack ${pack.kind}`);
  }
}

assert(workbenchSummaryDe().includes("offen"), "summary");
assert(resolvePackContent("workbench")!.includes("Human Gate Workbench"), "wb pack");
assert(resolvePackContent("nope") === null, "unknown pack");

console.log("humanGateWorkbench.test OK", {
  summary: workbenchSummaryDe(),
  gates: GATE_WORKBENCH.map((g) => g.gateId),
  mdChars: md.length,
});
