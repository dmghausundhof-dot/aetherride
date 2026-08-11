/**
 * Compat Gates v1 + Bike Entity flatten — run:
 *   npx tsx src/lib/compat/evaluate.test.ts
 */
import { evaluateCompat } from "./evaluate";
import { flattenBikeModelToAttrs, normalizeCompatValue } from "./bikeEntity";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

// --- Core gates demos ---

// mineral bike + DOT part → hard_block
{
  const r = evaluateCompat({
    bikeAttrs: { brake_fluid: "mineral" },
    partTags: ["fluid:dot_5_1"],
  });
  assert(r.result === "hard_block", `mineral+DOT → hard_block, got ${r.result}`);
  assert(
    r.matched.some((m) => m.id === "R001" || m.id === "R002"),
    "expected R001/R002"
  );
  assert(r.ruleset === "compat-gates-v1", "ruleset version");
}

// Magura part without magura_shape → require_attr R026
{
  const r = evaluateCompat({
    bikeAttrs: {},
    partTags: ["brand:magura", "type:brake_pad"],
  });
  assert(
    r.result === "require_attr",
    `Magura without shape → require_attr, got ${r.result}`
  );
  assert(
    r.matched.some((m) => m.id === "R026"),
    "expected R026"
  );
  assert(
    r.missing_attrs.includes("magura_pad_shape"),
    `missing magura_pad_shape, got ${r.missing_attrs.join(",")}`
  );
}

// matching freehub → ok
{
  const r = evaluateCompat({
    bikeAttrs: { freehub: "microspline" },
    partTags: ["freehub:microspline"],
  });
  assert(r.result === "ok", `matching freehub → ok, got ${r.result}`);
  assert(r.matched.length === 0, "no matched rules for identical freehub");
}

// missing attr skips hard_block
{
  const r = evaluateCompat({
    bikeAttrs: { brake_fluid: "mineral" },
    partTags: ["freehub:xd"],
  });
  assert(r.result === "ok", "no fluid on part → skip fluid hard_block");
}

// na ignores dimension
{
  const r = evaluateCompat({
    bikeAttrs: { brake_fluid: "na" },
    partTags: ["fluid:dot_5_1"],
  });
  assert(r.result === "ok", "na bike fluid ignores dimension");
}

// freehub hard mismatch
{
  const r = evaluateCompat({
    bikeAttrs: { freehub: "hg" },
    partTags: ["freehub:microspline"],
  });
  assert(r.result === "hard_block", "hg vs microspline hard_block");
}

// XD on XDR → soft_warn
{
  const r = evaluateCompat({
    bikeAttrs: { freehub: "xdr" },
    partTags: ["freehub:xd"],
  });
  assert(r.result === "soft_warn", `XD on XDR soft_warn, got ${r.result}`);
  assert(
    r.matched.some((m) => m.id === "R015"),
    "expected R015"
  );
}

// precedence: hard_block > require_attr
{
  const r = evaluateCompat({
    bikeAttrs: { brake_fluid: "mineral" },
    partTags: ["fluid:dot_4", "brand:magura"],
  });
  assert(r.result === "hard_block", "hard_block wins over require_attr");
}

// serial_required without serial → hard_block R081
{
  const r = evaluateCompat({
    bikeAttrs: { frame_bearing_lookup: "serial_required" },
    partTags: [],
    serialPresent: false,
  });
  assert(r.result === "hard_block", "R081 serial hard_block");
  assert(
    r.matched.some((m) => m.id === "R081"),
    "expected R081"
  );
}

// --- Bike entity flatten + evaluate ---

// aliases
assert(
  normalizeCompatValue("shimano_hg_plus_12", "chain_speed_family") ===
    "hg_plus_12",
  "alias hg+"
);
assert(
  normalizeCompatValue("sram_eagle_12", "chain_speed_family") === "eagle_12",
  "alias eagle"
);
assert(
  normalizeCompatValue("sram_t_type", "chain_speed_family") === "ttype_flattop",
  "alias t-type"
);
assert(normalizeCompatValue("smart_system", "bosch_system") === "smart", "smart");
assert(normalizeCompatValue("system_2", "bosch_system") === "system2", "system2");
assert(
  normalizeCompatValue("bpc3400_smart_4a", "charger_family") === "bpc3400_smart",
  "charger alias"
);
assert(
  normalizeCompatValue("bcs220_system2_4a", "charger_family") === "bcs220_system2",
  "charger alias 2"
);
assert(normalizeCompatValue("31.8", "display_clamp_od") === "31_8", "clamp 31.8");
assert(normalizeCompatValue("35.0", "display_clamp_od") === "35_0", "clamp 35.0");
assert(normalizeCompatValue("none", "magura_pad_shape") === "na", "magura none→na");
assert(
  normalizeCompatValue("unknown", "magura_pad_shape") === undefined,
  "unknown omitted"
);

{
  const attrs = flattenBikeModelToAttrs({
    brakes: { fluid_type: "mineral" },
    drivetrain: { freehub: "hg", chain_speed_family: "shimano_hg_plus_12" },
    ebike: { bosch_system: "smart_system" },
    compat_tags: ["clamp_od:31.8"],
  });
  assert(attrs.brake_fluid === "mineral", "flatten fluid");
  assert(attrs.freehub === "hg", "flatten freehub");
  assert(attrs.chain_speed_family === "hg_plus_12", "flatten alias chain");
  assert(attrs.bosch_system === "smart", "flatten alias bosch");
  assert(attrs.display_clamp_od === "31_8", "flatten tag clamp");
}

// bike_model mineral + part fluid:dot_5_1 → hard_block after flatten
{
  const bikeAttrs = flattenBikeModelToAttrs({
    brakes: { fluid_type: "mineral" },
  });
  const r = evaluateCompat({
    bikeAttrs,
    partTags: ["fluid:dot_5_1"],
  });
  assert(
    r.result === "hard_block",
    `bike_model mineral + DOT tag → hard_block, got ${r.result}`
  );
}

console.log("OK: compat gates v1 + bike entity flatten tests passed");
