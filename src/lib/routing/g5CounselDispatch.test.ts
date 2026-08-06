/**
 * G-5 Counsel-Dispatch — kein Auto-Versand, Paket bereit.
 */
import {
  COUNSEL_FIRM_CANDIDATES,
  counselDispatchStatusLabel,
  getCounselDispatchMeta,
  renderG5CounselCoverLetter,
  renderG5CounselDispatchChecklistMarkdown,
} from "./g5CounselDispatch";
import { G5_LEGAL_REVIEW_PASSED } from "./legalReview";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G5_LEGAL_REVIEW_PASSED === false, "gate open");
assert(COUNSEL_FIRM_CANDIDATES.length >= 2, "candidates");
const meta = getCounselDispatchMeta();
assert(meta.status === "human_must_send" || meta.status === "awaiting_counsel_reply", "human send");
assert(meta.suggestedSenderEmail.includes("@"), "email");
assert(counselDispatchStatusLabel(meta.status).length > 3, "label");
const letter = renderG5CounselCoverLetter();
assert(letter.includes("Mandatsanfrage"), "subject");
assert(letter.includes("Tirol"), "tirol");
assert(letter.includes("Bayern"), "bayern");
assert(letter.includes("manuell"), "manual send note");
const checklist = renderG5CounselDispatchChecklistMarkdown();
assert(checklist.includes("Checkliste Versand"), "checklist");
assert(checklist.includes("kein Auto-Versand"), "no auto");

console.log("g5CounselDispatch.test OK", {
  status: meta.status,
  letterChars: letter.length,
});
