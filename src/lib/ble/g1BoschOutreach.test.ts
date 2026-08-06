/**
 * G-1 Bosch Outreach — Paket bereit, Gate offen.
 */
import {
  G1_A01_CHECKLIST,
  G1_BOSCH_ACCESS_CLEARED,
  G1_LDI_DATA_INVENTORY,
  G1_OUTREACH_STEPS,
  G1_SIGNOFF,
  g1StatusBadge,
  getG1OutreachMeta,
  isG1Closed,
  renderG1BoschCoverLetter,
  renderG1BoschOutreachMarkdown,
} from "./g1BoschOutreach";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G1_BOSCH_ACCESS_CLEARED === false, "gate open");
assert(isG1Closed() === false, "not closed");
assert(G1_SIGNOFF.mayClaimLdiReady === false, "no claim");
assert(G1_LDI_DATA_INVENTORY.length >= 8, "inventory");
assert(
  G1_LDI_DATA_INVENTORY.some((d) => d.id === "assist_mode" && !d.inFreeLdiList),
  "assist not free"
);
assert(G1_OUTREACH_STEPS.some((s) => s.id === "B-1"), "B-1");
assert(G1_A01_CHECKLIST.length >= 4, "a01");
assert(g1StatusBadge().includes("bereit") || g1StatusBadge().includes("ausstehend"), "badge");

const meta = getG1OutreachMeta();
assert(meta.status === "package_ready", "status");
assert(meta.gatePassed === false, "gate");
assert(meta.freePoints >= 5, "free points");

const md = renderG1BoschOutreachMarkdown();
assert(md.includes("G-1"), "title");
assert(md.includes("G1_BOSCH_ACCESS_CLEARED = false"), "flag");
assert(md.includes("mayClaimLdiReady"), "signoff");

const letter = renderG1BoschCoverLetter();
assert(letter.includes("Live Data Interface"), "ldi");
assert(letter.includes("kein Auto-Mail"), "manual");

console.log("g1BoschOutreach.test OK", {
  inventory: G1_LDI_DATA_INVENTORY.length,
  mdChars: md.length,
});
