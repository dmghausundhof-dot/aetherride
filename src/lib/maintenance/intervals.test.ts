/**
 * Wartungs-Defaults nach Kategorie und OEM.
 * Ausführen: npx tsx src/lib/maintenance/intervals.test.ts
 */
import {
  chainCheckKm,
  intervalTemplatesFor,
} from "./intervals";
import type { BikeCategory, ComponentSlot } from "@/types/garage";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

function bike(
  category: BikeCategory,
  isEbike: boolean,
  parts: { slot: ComponentSlot; manufacturer?: string; componentModelId?: string }[] = []
) {
  return {
    category,
    isEbike,
    components: parts.map((p, i) => ({
      slot: p.slot,
      manufacturer: p.manufacturer,
      componentModelId: p.componentModelId,
      id: String(i),
      bikeId: "b",
      installedAt: "",
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    })),
  };
}

assert(chainCheckKm({ category: "mtb_am", isEbike: false }) === 1000, "MTB Kette");
assert(chainCheckKm({ category: "emtb", isEbike: true }) === 700, "eMTB Kette");
assert(chainCheckKm({ category: "road", isEbike: false }) === 1500, "Road Kette");
assert(chainCheckKm({ category: "cargo", isEbike: true }) === 600, "Lastenrad Kette");
assert(chainCheckKm({ category: "kids", isEbike: false }) === 800, "Kinderrad Kette");
assert(chainCheckKm({ category: "dh", isEbike: false }) === 600, "DH Kette");

const mtb = intervalTemplatesFor(bike("mtb_am", false));
assert(
  mtb.some((t) => t.label.includes("Lower-Leg") && t.intervalHours === 50),
  "MTB Lower-Leg 50 h"
);
assert(
  mtb.some((t) => t.label.includes("Vollservice") && t.intervalHours === 125),
  "MTB Full default 125 h"
);
assert(
  !mtb.some((t) => t.label.includes("Erste E-Bike")),
  "Analog ohne Bosch-Erstcheck"
);

const cargo = intervalTemplatesFor(
  bike("cargo", true, [
    { slot: "chain", manufacturer: "Gates", componentModelId: "cm-gates-cdx-belt" },
    { slot: "brake_front", manufacturer: "Magura", componentModelId: "cm-magura-cme-front" },
    { slot: "fork", manufacturer: "SR Suntour", componentModelId: "cm-suntour-mobie-cargo-80" },
  ])
);
assert(
  cargo.some((t) => t.label.includes("Erste E-Bike") && t.intervalKm === 300),
  "Bosch Erstcheck 300 km"
);
assert(
  cargo.some((t) => t.label.includes("Riemen") && t.intervalKm === 5000),
  "Gates-Riemen statt Kette"
);
assert(
  cargo.some((t) => t.label.includes("Mineralöl") && t.intervalDays === 730),
  "Magura Mineralöl 24 Monate"
);
assert(
  cargo.some(
    (t) => t.slot === "fork" && t.label.includes("Vollservice") && t.intervalHours === 100
  ),
  "Suntour Cargo-Gabel 100 h Full"
);
assert(
  cargo.some((t) => t.slot === "brake_pads_front" && t.intervalKm === 500),
  "Lastenrad Beläge 500 km"
);

const fox = intervalTemplatesFor(
  bike("mtb_enduro", false, [
    { slot: "fork", manufacturer: "Fox", componentModelId: "cm-fox-36-factory-170" },
  ])
);
assert(
  fox.some((t) => t.label.includes("Vollservice") && t.intervalHours === 125),
  "Fox Full 125 h"
);

const rs = intervalTemplatesFor(
  bike("mtb_enduro", false, [
    { slot: "fork", manufacturer: "RockShox", componentModelId: "cm-rockshox-lyrik-160" },
  ])
);
assert(
  rs.some((t) => t.label.includes("Vollservice") && t.intervalHours === 200),
  "RockShox Full 200 h"
);

const kids = intervalTemplatesFor(bike("kids", false));
assert(
  kids.some((t) => t.slot === "brake_pads_front" && t.intervalKm === 1200),
  "Kinderrad Beläge"
);
assert(
  !kids.some((t) => t.slot === "fork" && t.intervalHours),
  "starre Kindergabel ohne Stundenintervall"
);

const road = intervalTemplatesFor(bike("road", false));
assert(
  !road.some((t) => t.slot === "fork" && t.intervalHours),
  "Rennrad ohne Gabel-Stunden"
);

  const dh = intervalTemplatesFor(bike("dh", false));
  assert(
    dh.some((t) => t.slot === "brake_pads_front" && t.intervalKm === 400),
    "DH Beläge"
  );

  const boschFirst = intervalTemplatesFor(
    bike("emtb", true, [
      { slot: "motor", manufacturer: "Bosch", componentModelId: "cm-bosch-cx-gen5" },
    ])
  );
  assert(
    boschFirst.some(
      (t) => t.label.includes("Erste") && t.intervalKm === 300 && t.intervalDays === 28
    ),
    "Bosch Erstcheck 300 km"
  );

  const shimanoFirst = intervalTemplatesFor(
    bike("emtb", true, [
      { slot: "motor", manufacturer: "Shimano", componentModelId: "cm-shimano-ep600" },
    ])
  );
  assert(
    shimanoFirst.some((t) => t.label.includes("STEPS") && t.intervalKm === 500),
    "Shimano STEPS Ersteinspektion"
  );
  assert(
    !shimanoFirst.some((t) => t.sourceLabel?.includes("Bosch Erstcheck")),
    "STEPS ohne Bosch-300-km"
  );

  const broseFirst = intervalTemplatesFor(
    bike("emtb", true, [
      {
        slot: "motor",
        manufacturer: "Specialized",
        componentModelId: "cm-specialized-2-2",
      },
    ])
  );
  assert(
    !broseFirst.some((t) => t.intervalKm === 300 && t.intervalDays === 28),
    "Brose/Specialized 2.2 ohne Bosch-Erstcheck"
  );
  assert(
    broseFirst.some((t) => t.sourceLabel.includes("Brose")),
    "Brose Jahres-Service"
  );

console.log("intervals.test.ts ok");
