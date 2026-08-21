/**
 * Druck-Einheit — Ausführen: npx tsx src/lib/garage/pressureUnit.test.ts
 */
import {
  barToPsi,
  enteredPressureToPsi,
  formatLoggedTirePressure,
  pressureUnitLabel,
  pressureUsesBar,
  psiToBar,
} from "./pressureUnit";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

assert(pressureUsesBar("urban"), "city bar");
assert(pressureUsesBar("road"), "road bar");
assert(pressureUsesBar("gravel"), "gravel bar");
assert(pressureUsesBar("cargo"), "cargo bar");
assert(pressureUsesBar("folding"), "folding bar");
assert(pressureUsesBar("kids"), "kids bar");
assert(!pressureUsesBar("mtb_am"), "mtb psi");
assert(!pressureUsesBar("emtb"), "emtb psi");
assert(pressureUnitLabel("urban") === "bar", "label bar");
assert(pressureUnitLabel("dh") === "psi", "label psi");

const stored = enteredPressureToPsi(4.5, "urban");
assert(stored > 65 && stored < 66, `4.5 bar → ${stored} psi`);
assert(psiToBar(stored) === 4.5, "round-trip bar");
assert(enteredPressureToPsi(22, "mtb_am") === 22, "mtb passthrough");
assert(barToPsi(1) > 14.4 && barToPsi(1) < 14.6, "1 bar");

const logged = formatLoggedTirePressure(
  [
    {
      values: [
        { adjusterKey: "tire_front.pressure_psi", valueNum: 26.1 },
        { adjusterKey: "tire_rear.pressure_psi", valueNum: 29 },
      ],
    },
  ],
  false
);
assert(logged === "26 / 29 psi", "mtb pressure pair");
assert(
  formatLoggedTirePressure(
    [{ values: [{ adjusterKey: "tire_front.pressure_psi", valueNum: 26.1 }] }],
    true
  ) === "1.8 bar",
  "single bar"
);
assert(formatLoggedTirePressure([], true) === null, "empty setups");

console.log("pressureUnit.test.ts ok");
