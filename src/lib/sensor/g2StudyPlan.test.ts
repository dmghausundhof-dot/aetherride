/**
 * G-2 Validierungsstudienplan — bereit, Gate offen.
 * Ausführen: npx tsx src/lib/sensor/g2StudyPlan.test.ts
 */
import { G2_SUSPENSION_GATE_PASSED } from "./fni";
import {
  G2_CRITERIA,
  G2_PHASES,
  G2_STUDY_DESIGN,
  g2StudyStatusSummary,
  renderG2StudyPlanMarkdown,
} from "./g2StudyPlan";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(G2_SUSPENSION_GATE_PASSED === false, "Gate bleibt false");
assert(G2_CRITERIA.length === 7, "7 Kriterien");
assert(G2_CRITERIA.every((c) => c.status === "not_started"), "nicht gestartet");
assert(G2_STUDY_DESIGN.minRiders >= 12, "Fahrer");
assert(G2_STUDY_DESIGN.minRideHours >= 40, "Stunden");
assert(G2_PHASES.length >= 4, "Phasen");
assert(g2StudyStatusSummary().includes("Gate offen"), "summary");

const md = renderG2StudyPlanMarkdown();
assert(md.includes("§7.5") || md.includes("7.5"), "spec ref");
assert(md.includes("bottom_out"), "criterion");
assert(md.includes("G2_SUSPENSION_GATE_PASSED = false"), "gate flag");
assert(!md.toLowerCase().includes("studie bestanden"), "no fake pass");

console.log("g2StudyPlan.test OK", {
  criteria: G2_CRITERIA.length,
  mdChars: md.length,
});
