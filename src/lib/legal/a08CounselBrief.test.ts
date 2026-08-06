/**
 * A-08 Anwalt-Briefing — bereit, Gate offen.
 * Ausführen: npx tsx src/lib/legal/a08CounselBrief.test.ts
 */
import { A08_LEGAL_REVIEW_PASSED } from "./setupLiability";
import {
  A08_COPY_INVENTORY,
  A08_HARD_LIMITS_FOR_COUNSEL,
  A08_MANDATE,
  A08_SIGNOFF,
  renderA08AttorneyBriefMarkdown,
  renderA08CoverLetter,
} from "./a08CounselBrief";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(A08_LEGAL_REVIEW_PASSED === false, "Gate bleibt false");
assert(A08_SIGNOFF.opinion == null, "kein Fake-Opinion");
assert(A08_SIGNOFF.mayClaimLegallyReviewed === false, "kein Claim");
assert(A08_COPY_INVENTORY.length >= 5, "Textinventar");
assert(A08_HARD_LIMITS_FOR_COUNSEL.length >= 5, "harte Grenzen");
assert(A08_MANDATE.outOfScope.some((x) => x.includes("G-5")), "G-5 out");
assert(A08_MANDATE.outOfScope.some((x) => x.includes("A-06")), "A-06 out");

const md = renderA08AttorneyBriefMarkdown();
assert(md.includes("A-08"), "title");
assert(md.includes("shortDe"), "copy id");
assert(md.includes("mayClaimLegallyReviewed"), "signoff");
assert(!md.toLowerCase().includes("gutachten abgeschlossen"), "no fake done");

const letter = renderA08CoverLetter();
assert(letter.includes("Setup-Haftung"), "subject");
assert(letter.includes("info@dmgservice.org"), "sender");
assert(letter.includes("kein Auto-Mail"), "manual send");

console.log("a08CounselBrief.test OK", {
  copy: A08_COPY_INVENTORY.length,
  mdChars: md.length,
});
