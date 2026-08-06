/**
 * G-5 Legal-Review Gate — ehrlich offen bis Sign-off.
 * Ausführen: npx tsx src/lib/routing/legalReview.test.ts
 */
import {
  G5_LEGAL_REVIEW_PASSED,
  LEGAL_REVIEW_BY_JURISDICTION,
  g5StatusBadge,
  g5StatusShort,
  isG5ClosedFor,
  listLaunchBlockedJurisdictions,
} from "./legalReview";
import { evaluateAccessForEdges, JURISDICTIONS } from "./accessRights";
import type { RouteEdgeDemo } from "./profiles";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G5_LEGAL_REVIEW_PASSED === false, "Master-Gate muss false bleiben");
assert(!isG5ClosedFor("AT-7"), "AT-7 nicht closed");
assert(!isG5ClosedFor("DE-BY"), "DE-BY nicht closed");
assert(JURISDICTIONS["AT-7"].legalReviewedAt == null, "Profil AT-7 unreviewed");
assert(JURISDICTIONS["DE-BY"].legalReviewedAt == null, "Profil DE-BY unreviewed");

const at = LEGAL_REVIEW_BY_JURISDICTION["AT-7"];
assert(at.status === "editorial_done", "AT-7 editorial");
assert(at.legalReviewer == null, "kein Fake-Reviewer");
assert(at.sources.length >= 2, "AT-7 Quellen");
assert(at.openQuestions.length >= 1, "AT-7 offene Fragen");
assert(at.launchEligible === false, "AT-7 nicht launch-fähig");

const by = LEGAL_REVIEW_BY_JURISDICTION["DE-BY"];
assert(by.status === "editorial_done", "DE-BY editorial");
assert(by.launchEligible === false, "DE-BY nicht launch-fähig");

assert(
  g5StatusBadge("AT-7").includes("offen"),
  "Badge sagt offen"
);
assert(
  g5StatusShort("AT-7").includes("keine Rechtsberatung"),
  "Kurztext Disclaimer"
);
assert(
  !g5StatusShort("AT-7").includes("juristisch geprüft"),
  "kein geprüfte-Claim"
);

const blocked = listLaunchBlockedJurisdictions();
assert(blocked.includes("AT-7") && blocked.includes("DE-BY"), "beide blockiert");

const edges: RouteEdgeDemo[] = [
  {
    id: "banned",
    distanceM: 50,
    highway: "path",
    bicycleAccess: "no",
    latlng: [
      [47.45, 12.15],
      [47.451, 12.151],
    ],
  },
];
const ev = evaluateAccessForEdges(edges, "AT-7");
assert(ev.legalGateOpen === true, "Gate offen = Review pending");
assert(ev.legalNoteShort.includes("G-5"), "Eval nutzt G-5 Text");
assert(ev.blocked, "bicycle=no weiterhin block");

console.log("legalReview.test OK", {
  g5Passed: G5_LEGAL_REVIEW_PASSED,
  blockedJurisdictions: blocked,
});
