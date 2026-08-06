/**
 * G-5 Anwalt-Paket — bereit, aber ohne Fake-Sign-off.
 * Ausführen: npx tsx src/lib/routing/g5AttorneyBrief.test.ts
 */
import {
  G5_ATTORNEY_MANDATE,
  G5_RULE_INVENTORY,
  G5_SIGNOFF_TEMPLATES,
  attorneyPackageStatus,
  g5ClosureProcedureDe,
  renderG5AttorneyBriefMarkdown,
} from "./g5AttorneyBrief";
import { G5_LEGAL_REVIEW_PASSED } from "./legalReview";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G5_LEGAL_REVIEW_PASSED === false, "Gate bleibt false");
assert(G5_ATTORNEY_MANDATE.startMarkets.includes("AT-7"), "AT-7");
assert(G5_ATTORNEY_MANDATE.startMarkets.includes("DE-BY"), "DE-BY");
assert(
  G5_ATTORNEY_MANDATE.outOfScope.some((x) => x.includes("A-08")),
  "A-08 out of scope"
);
assert(G5_RULE_INVENTORY.length >= 6, "Regelinventar");
assert(G5_SIGNOFF_TEMPLATES["AT-7"].opinion == null, "kein Fake-Opinion AT");
assert(G5_SIGNOFF_TEMPLATES["DE-BY"].opinion == null, "kein Fake-Opinion BY");
assert(
  G5_SIGNOFF_TEMPLATES["AT-7"].mayClaimLegallyReviewed === false,
  "kein Claim"
);

const status = attorneyPackageStatus();
assert(status.readyForCounsel === true, "ready");
assert(status.gatePassed === false, "not passed");
assert(status.pendingSignOff.length === 2, "beide pending");
assert(!status.summaryDe.includes("Sign-off vorhanden"), "summary");

const md = renderG5AttorneyBriefMarkdown();
assert(md.includes("Anwalt-Briefing"), "title");
assert(md.includes("GLOBAL-bicycle-no"), "rule");
assert(md.includes("BayWaldG"), "bayern law");
assert(md.includes("mayClaimLegallyReviewed"), "signoff field");
assert(!md.toLowerCase().includes("gutachten abgeschlossen"), "no fake done");
assert(g5ClosureProcedureDe().length >= 5, "closure steps");

console.log("g5AttorneyBrief.test OK", {
  rules: G5_RULE_INVENTORY.length,
  mdChars: md.length,
});
