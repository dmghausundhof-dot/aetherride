/**
 * Run: npx tsx src/lib/i18n/setupTemplateCopy.test.ts
 */
import assert from "node:assert/strict";
import { presentSetupTemplate } from "./setupTemplateCopy";
import { presentCompat, compatVerdictLabel } from "./compatCopy";
import { presentBracketingSummary, bracketingCopy } from "./bracketingCopy";
import type { CompatibilityResult } from "@/types/garage";

assert.equal(
  presentSetupTemplate("tpl-editorial-wet-roots", "en").label,
  "Editorial: wet roots"
);
assert.ok(
  !presentSetupTemplate("tpl-fox-oem-base", "en").label.includes("Gewichtstabelle")
);
assert.ok(
  presentSetupTemplate("tpl-gravel-base", "fr").disclaimer
    .toLowerCase()
    .includes("tubeless")
);
assert.equal(
  presentSetupTemplate("unknown", "en", {
    label: "Fallback",
    disclaimer: "d",
  }).label,
  "Fallback"
);

const fail: CompatibilityResult = {
  verdict: "INCOMPATIBLE",
  ruleCode: "RL-DRV-011",
  title: "Kassette benötigt passenden Freilaufkörper",
  severity: "functional",
  explainDe:
    "Die Kassette benötigt XD, deine Nabe hat Micro Spline. Ein Freilaufkörper-Tausch ist bei manchen Naben möglich.",
  missingAttributes: [],
  evidence: [
    {
      ruleCode: "RL-DRV-011",
      attributeKey: "freehub_standard",
      valueA: "XD",
      valueB: "Micro Spline",
    },
  ],
  torqueSpecs: [],
};
const enFail = presentCompat(fail, "en");
assert.equal(enFail.title, "Cassette needs matching freehub body");
assert.ok(enFail.explain.includes("XD"));
assert.ok(enFail.explain.includes("Micro Spline"));
assert.ok(!enFail.explain.includes("Kassette benötigt"));
assert.equal(compatVerdictLabel("INCOMPATIBLE", "en"), "No fit");

const ok: CompatibilityResult = {
  ...fail,
  verdict: "COMPATIBLE",
  explainDe: "Kassette benötigt passenden Freilaufkörper: Prüfung bestanden.",
};
assert.equal(presentCompat(ok, "nl").explain, "Regel gehaald.");

assert.equal(
  presentBracketingSummary("Kein belegbarer Unterschied — die Lauf-zu-Lauf-Streuung übersteigt die gemessenen Differenzen (|Δ| ≤ 1,5× gepoolte SD). Das ist ein gültiges Ergebnis (F-SET-003).", "en").startsWith("No proven difference"),
  true
);
assert.equal(bracketingCopy("en").title, "Try two variants");
assert.ok(!bracketingCopy("en").title.includes("Zwei Varianten"));

console.log("setupTemplateCopy.test.ts OK");
