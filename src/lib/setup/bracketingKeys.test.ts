/**
 * Bracketing-Keys ↔ Setup-Overrides
 */
import {
  BRACKETING_PARAMS,
  bracketingParamToSetupOverride,
  bracketingUnit,
  normalizeBracketingParameter,
} from "./bracketingKeys";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

assert(
  normalizeBracketingParameter("shock.rebound") === "rear_shock.rebound",
  "legacy shock"
);
assert(
  normalizeBracketingParameter("tire.front_psi") === "tire_front.pressure_psi",
  "legacy tire"
);
assert(
  normalizeBracketingParameter("fork.rebound") === "fork.rebound",
  "native"
);
assert(BRACKETING_PARAMS.some((p) => p.id === "rear_shock.sag_pct"), "shock sag");
const ov = bracketingParamToSetupOverride("shock.rebound", 11);
assert(ov["rear_shock.rebound"] === 11, "override map");
assert(bracketingUnit("tire.rear_psi") === "psi", "unit");

console.log("bracketingKeys.test OK", { n: BRACKETING_PARAMS.length });
