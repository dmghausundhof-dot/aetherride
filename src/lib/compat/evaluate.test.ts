/**
 * Compat Gates v1 + Bike Entity flatten — run:
 *   npx tsx src/lib/compat/evaluate.test.ts
 */
import batch2 from "./bike-batch2-attrs-dimmap.json";
import { evaluateCompat } from "./evaluate";
import { flattenBikeModelToAttrs, normalizeCompatValue } from "./bikeEntity";
import type { CompatAttrMap } from "./types";

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

// --- Bike-Batch #2 fixture (Research-corrected) ---
{
  assert(batch2.bikes.length === 12, "batch2 has 12 bikes");

  // 01 Roadlite:ON CF — bosch_hub_line note; no mid-drive smart mapping
  {
    const roadlite = batch2.bikes.find((b) => b.id === "01");
    assert(!!roadlite, "Roadlite present");
    const attrs = roadlite!.attrs as CompatAttrMap;
    assert(attrs.brake_fluid === "mineral", "Roadlite mineral");
    assert(attrs.bosch_system === undefined, "Roadlite bosch_system omitted");
    assert(attrs.charger_family === undefined, "Roadlite charger omitted");
    assert(
      (roadlite as { compat_notes?: string[] }).compat_notes?.includes(
        "bosch_hub_line"
      ),
      "Roadlite compat note bosch_hub_line"
    );

    for (const tag of [
      "charger:bcs220_system2",
      "charger:bpc3400_smart",
      "charger:other_system2",
      "charger:other_smart",
    ]) {
      const r = evaluateCompat({ bikeAttrs: attrs, partTags: [tag] });
      assert(
        r.result !== "hard_block",
        `Roadlite + ${tag} must NOT hard_block, got ${r.result}`
      );
      assert(
        !r.matched.some((m) => ["R050", "R051", "R052"].includes(m.id)),
        `Roadlite + ${tag} must not fire Smart/System2 charger hard gates`
      );
    }
  }

  // 07 Kalkhoff Image 5+ Excite — magura_pad_shape=7
  {
    const kalkhoff = batch2.bikes.find((b) => b.id === "07");
    assert(!!kalkhoff, "Kalkhoff present");
    const attrs = kalkhoff!.attrs as CompatAttrMap;
    assert(attrs.brake_fluid === "mineral", "Kalkhoff mineral");
    assert(attrs.magura_pad_shape === "7", "Kalkhoff magura shape 7");

    // Magura shape-8 pad → hard_block (R020 family)
    {
      const r = evaluateCompat({
        bikeAttrs: attrs,
        partTags: ["brand:magura", "magura_shape:8"],
      });
      assert(
        r.result === "hard_block",
        `Kalkhoff + Magura shape 8 → hard_block, got ${r.result}`
      );
      assert(
        r.matched.some((m) => m.id === "R020" || m.id === "R022"),
        "expected R020/R022 family"
      );
    }

    // Magura shape-7 pad → ok (not require_attr R026)
    {
      const r = evaluateCompat({
        bikeAttrs: attrs,
        partTags: ["brand:magura", "magura_shape:7"],
      });
      assert(
        r.result === "ok",
        `Kalkhoff + Magura shape 7 → ok, got ${r.result}`
      );
      assert(
        !r.matched.some((m) => m.id === "R026"),
        "shape-7 must not require_attr R026"
      );
    }
  }

  // 08 Topstone Neo probes
  {
    const topstone = batch2.bikes.find((b) => b.id === "08");
    assert(!!topstone, "Topstone Neo present");
    const attrs = topstone!.attrs as CompatAttrMap;
    assert(attrs.brake_fluid === "mineral", "Topstone mineral");
    assert(attrs.freehub === "hg", "Topstone hg");
    assert(attrs.bosch_system === "smart", "Topstone smart (alias)");
    assert(attrs.charger_family === "bpc3400_smart", "Topstone bpc3400_smart");
    assert(
      attrs.chain_speed_family === undefined,
      "Topstone unknown chain omitted"
    );

    // + System2 charger → hard_block
    {
      const r = evaluateCompat({
        bikeAttrs: attrs,
        partTags: ["charger:bcs220_system2"],
      });
      assert(
        r.result === "hard_block",
        `Topstone + System2 charger → hard_block, got ${r.result}`
      );
      assert(
        r.matched.some((m) => m.id === "R050"),
        "expected R050 smart vs system2 charger"
      );
    }

    // + DOT fluid → hard_block
    {
      const r = evaluateCompat({
        bikeAttrs: attrs,
        partTags: ["fluid:dot_5_1"],
      });
      assert(
        r.result === "hard_block",
        `Topstone + DOT → hard_block, got ${r.result}`
      );
    }

    // + HG cassette → ok
    {
      const r = evaluateCompat({
        bikeAttrs: attrs,
        partTags: ["freehub:hg"],
      });
      assert(r.result === "ok", `Topstone + HG cassette → ok, got ${r.result}`);
    }
  }

  // ingest aliases / omit sanity across batch
  for (const bike of batch2.bikes) {
    const a = bike.attrs as CompatAttrMap;
    for (const [k, v] of Object.entries(a)) {
      assert(v !== "unknown" && v !== "none", `${bike.id} ${k} not omitted`);
      assert(
        v !== "shimano_hg_plus_12" &&
          v !== "sram_eagle_12" &&
          v !== "smart_system" &&
          v !== "bpc3400_smart_4a",
        `${bike.id} ${k} alias not applied: ${v}`
      );
    }
  }
}

console.log(
  "OK: compat gates v1 + bike entity flatten + batch2 tests passed"
);
