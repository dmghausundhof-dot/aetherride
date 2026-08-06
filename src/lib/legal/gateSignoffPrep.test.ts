/**
 * Legal/Gate Sign-off Prep — Flags bleiben false
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
  allHumanGateFlagsStillOpen,
  HUMAN_SIGN_GATES,
  legalSignoffPrepSummaryDe,
  renderLegalGateExportBundleMarkdown,
  renderUnifiedGateSignoffChecklistMarkdown,
} from "./gateSignoffPrep";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G0_MOBILE_STACK_CONFIRMED === false, "G-0");
assert(G1_BOSCH_ACCESS_CLEARED === false, "G-1");
assert(G2_SUSPENSION_GATE_PASSED === false, "G-2");
assert(G5_LEGAL_REVIEW_PASSED === false, "G-5");
assert(A06_LEGAL_REVIEW_PASSED === false, "A-06");
assert(A08_LEGAL_REVIEW_PASSED === false, "A-08");
assert(allHumanGateFlagsStillOpen(), "all human open");
assert(HUMAN_SIGN_GATES.length === 6, "six gates");
assert(HUMAN_SIGN_GATES.every((g) => g.requiresHumanSign), "human required");

const checklist = renderUnifiedGateSignoffChecklistMarkdown();
assert(checklist.includes("Human must sign"), "checklist banner");
assert(checklist.includes("G-0"), "G-0");
assert(checklist.includes("A-08"), "A-08");
assert(checklist.includes("`false`"), "false flags");

const bundle = renderLegalGateExportBundleMarkdown();
assert(bundle.includes("G-0 Workshop"), "bundle g0");
assert(bundle.includes("G-1"), "bundle g1");
assert(bundle.includes("G-2"), "bundle g2");
assert(bundle.includes("G-5"), "bundle g5");
assert(bundle.includes("A-06"), "bundle a06");
assert(bundle.includes("A-08"), "bundle a08");
assert(bundle.length > 5000, "bundle size");

assert(legalSignoffPrepSummaryDe().includes("offen"), "summary");

console.log("gateSignoffPrep.test OK", {
  summary: legalSignoffPrepSummaryDe(),
  checklistChars: checklist.length,
  bundleChars: bundle.length,
});
