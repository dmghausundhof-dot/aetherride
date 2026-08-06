/**
 * A-06 ODbL-Briefing — bereit, Gate offen.
 * Ausführen: npx tsx src/lib/legal/a06OdblBrief.test.ts
 */
import {
  A06_INVENTORY,
  A06_LEGAL_REVIEW_PASSED,
  A06_MANDATE,
  A06_SIGNOFF,
  a06StatusBadge,
  isA06Closed,
  renderA06AttorneyBriefMarkdown,
  renderA06CoverLetter,
} from "./a06OdblBrief";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(A06_LEGAL_REVIEW_PASSED === false, "Gate bleibt false");
assert(isA06Closed() === false, "nicht closed");
assert(A06_SIGNOFF.mayClaimOdblCleared === false, "kein Claim");
assert(A06_SIGNOFF.opinion == null, "kein Fake-Opinion");
assert(A06_INVENTORY.length >= 6, "Inventar");
assert(A06_INVENTORY.some((i) => i.id === "heatmap-agg"), "heatmap");
assert(A06_MANDATE.outOfScope.some((x) => x.includes("G-5")), "G-5 out");
assert(A06_MANDATE.outOfScope.some((x) => x.includes("A-08")), "A-08 out");
assert(a06StatusBadge().includes("ausstehend"), "badge");

const md = renderA06AttorneyBriefMarkdown();
assert(md.includes("ODbL"), "title");
assert(md.includes("likely_derived_db"), "hypothesis");
assert(md.includes("mayClaimOdblCleared"), "signoff");

const letter = renderA06CoverLetter();
assert(letter.includes("ODbL"), "subject");
assert(letter.includes("info@dmgservice.org"), "sender");
assert(letter.includes("kein Auto-Mail"), "manual send");

console.log("a06OdblBrief.test OK", {
  inventory: A06_INVENTORY.length,
  mdChars: md.length,
});
