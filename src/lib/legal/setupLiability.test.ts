/**
 * A-08 Setup-Liability — Gate offen, kein Fake-Legal.
 * Ausführen: npx tsx src/lib/legal/setupLiability.test.ts
 */
import {
  A08_LEGAL_REVIEW_PASSED,
  SETUP_LIABILITY,
  a08StatusBadge,
  isA08Closed,
} from "./setupLiability";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(A08_LEGAL_REVIEW_PASSED === false, "A-08 master false");
assert(!isA08Closed(), "A-08 nicht closed");
assert(SETUP_LIABILITY.status === "editorial_draft", "editorial");
assert(SETUP_LIABILITY.legalReviewer == null, "kein Fake-Reviewer");
assert(SETUP_LIABILITY.shortDe.includes("A-08"), "short mentions A-08");
assert(!SETUP_LIABILITY.shortDe.includes("juristisch geprüft"), "kein geprüft-Claim");
assert(a08StatusBadge().includes("Legal ausstehend"), "Badge");

console.log("setupLiability.test OK", { version: SETUP_LIABILITY.version });
