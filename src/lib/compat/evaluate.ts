import { normalizeCompatValue } from "./bikeEntity";
import gates from "./compat-gates-v1.json";
import { mergeAttrs, parseShopifyTags } from "./tags";
import type {
  CompatAttrMap,
  CompatGatesRuleset,
  CompatRuleDef,
  CompatSeverity,
  CompatWhenAllClause,
  EvaluateCompatInput,
  EvaluateCompatResult,
  MatchedCompatRule,
} from "./types";

const ruleset = gates as CompatGatesRuleset;

const PRECEDENCE: CompatSeverity[] = ["hard_block", "require_attr", "soft_warn", "ok"];

function isNaValue(v: string | undefined): boolean {
  return v === "na" || v === "n/a" || v === "N/A";
}

function normalizeAttrMap(attrs: CompatAttrMap): CompatAttrMap {
  const out: CompatAttrMap = {};
  for (const [dim, value] of Object.entries(attrs)) {
    const n = normalizeCompatValue(value, dim);
    if (n !== undefined) out[dim] = n;
  }
  return out;
}

function hasEitherDimension(
  bikeAttrs: CompatAttrMap,
  partAttrs: CompatAttrMap,
  dimension: string,
  values: string[]
): boolean {
  const set = new Set(values);
  const bv = bikeAttrs[dimension];
  const pv = partAttrs[dimension];
  return (!!bv && set.has(bv)) || (!!pv && set.has(pv));
}

function partTagsMatchRegex(tags: string[], pattern: string): boolean {
  // Research packs may use (?i) — JS needs the `i` flag instead.
  const cleaned = pattern.replace(/^\(\?i\)/i, "");
  let re: RegExp;
  try {
    re = new RegExp(cleaned, "i");
  } catch {
    return false;
  }
  return tags.some((t) => re.test(t));
}

function partHasPrefix(tags: string[], prefixes: string[]): boolean {
  const set = new Set(prefixes.map((p) => p.toLowerCase()));
  return tags.some((t) => {
    const idx = t.indexOf(":");
    if (idx <= 0) return false;
    return set.has(t.slice(0, idx).trim().toLowerCase());
  });
}

function isBikeMissing(bikeAttrs: CompatAttrMap, dimension: string): boolean {
  const v = bikeAttrs[dimension];
  if (v === undefined) return true;
  if (isNaValue(v)) return true;
  if (v === "none") return true;
  return false;
}

function whenAllClausePass(
  clause: CompatWhenAllClause,
  bikeAttrs: CompatAttrMap
): boolean {
  const dim = clause.dimension;
  const val = bikeAttrs[dim];

  if (clause.bike_present === true) {
    if (val === undefined) return false;
  } else if (clause.bike_present === false) {
    if (val !== undefined) return false;
  }

  if (clause.bike_missing === true) {
    if (!isBikeMissing(bikeAttrs, dim)) return false;
  } else if (clause.bike_missing === false) {
    if (isBikeMissing(bikeAttrs, dim)) return false;
  }

  if (clause.bike_not_in?.length) {
    if (val === undefined) return false;
    const banned = new Set(clause.bike_not_in.map((x) => x.toLowerCase()));
    if (banned.has(val.toLowerCase())) return false;
  }

  return true;
}

function whenGatesPass(
  rule: CompatRuleDef,
  input: EvaluateCompatInput,
  bikeAttrs: CompatAttrMap,
  partAttrs: CompatAttrMap
): boolean {
  if (rule.when?.all?.length) {
    for (const clause of rule.when.all) {
      if (!whenAllClausePass(clause, bikeAttrs)) return false;
    }
  }

  if (rule.when_serial_present !== undefined) {
    const present = !!input.serialPresent;
    if (present !== rule.when_serial_present) return false;
  }

  if (rule.when_part_tag_regex) {
    if (!partTagsMatchRegex(input.partTags ?? [], rule.when_part_tag_regex)) {
      // allow require_attr / other rules to also key off slot or prefixes
      const prefixOk =
        rule.when_part_tag_prefixes &&
        partHasPrefix(input.partTags ?? [], rule.when_part_tag_prefixes);
      const slotOk =
        rule.when_slot_in &&
        input.slot &&
        rule.when_slot_in.includes(input.slot);
      if (!prefixOk && !slotOk) return false;
    }
  } else {
    // prefix / slot gates (OR): if either list present, at least one must match
    const hasPrefixGate = !!rule.when_part_tag_prefixes?.length;
    const hasSlotGate = !!rule.when_slot_in?.length;
    if (hasPrefixGate || hasSlotGate) {
      const prefixOk =
        hasPrefixGate &&
        partHasPrefix(input.partTags ?? [], rule.when_part_tag_prefixes!);
      const slotOk =
        hasSlotGate && !!input.slot && rule.when_slot_in!.includes(input.slot);
      if (!prefixOk && !slotOk) return false;
    }
  }

  if (rule.when_either_dimension) {
    if (
      !hasEitherDimension(
        bikeAttrs,
        partAttrs,
        rule.when_either_dimension.dimension,
        rule.when_either_dimension.values
      )
    ) {
      return false;
    }
  }

  if (rule.also_either_dimension) {
    if (
      !hasEitherDimension(
        bikeAttrs,
        partAttrs,
        rule.also_either_dimension.dimension,
        rule.also_either_dimension.values
      )
    ) {
      return false;
    }
  }

  return true;
}

function readBikeValue(rule: CompatRuleDef, bikeAttrs: CompatAttrMap): string | undefined {
  const dim = rule.bike_values_from || rule.dimension;
  if (!dim) return undefined;
  return bikeAttrs[dim];
}

function matchValuePair(
  rule: CompatRuleDef,
  bikeVal: string | undefined,
  partVal: string | undefined
): boolean {
  if (rule.match_mode === "either_has") {
    const values = new Set([
      ...(rule.bike_values ?? []),
      ...(rule.part_values ?? []),
    ]);
    return (
      (!!bikeVal && values.has(bikeVal)) || (!!partVal && values.has(partVal))
    );
  }

  if (!bikeVal || !partVal) return false;
  if (isNaValue(bikeVal) || isNaValue(partVal)) return false;

  const forward =
    !!rule.bike_values?.includes(bikeVal) &&
    !!rule.part_values?.includes(partVal);
  if (forward) return true;

  if (rule.bidirectional) {
    return (
      !!rule.bike_values?.includes(partVal) &&
      !!rule.part_values?.includes(bikeVal)
    );
  }
  return false;
}

function evaluateRequireAttr(
  rule: CompatRuleDef,
  bikeAttrs: CompatAttrMap,
  partAttrs: CompatAttrMap,
  input: EvaluateCompatInput
): { matched: boolean; missing?: string } {
  const attr = rule.require_attr;
  if (!attr) return { matched: false };
  if (!whenGatesPass(rule, input, bikeAttrs, partAttrs)) {
    return { matched: false };
  }

  const on = rule.require_on ?? "either";
  const bikeHas = bikeAttrs[attr] !== undefined && !isNaValue(bikeAttrs[attr]);
  const partHas = partAttrs[attr] !== undefined && !isNaValue(partAttrs[attr]);

  let missing = false;
  if (on === "bike") missing = !bikeHas;
  else if (on === "part") missing = !partHas;
  else missing = !bikeHas && !partHas;

  if (!missing) return { matched: false };
  return { matched: true, missing: attr };
}

function evaluateDimensionRule(
  rule: CompatRuleDef,
  bikeAttrs: CompatAttrMap,
  partAttrs: CompatAttrMap,
  input: EvaluateCompatInput
): MatchedCompatRule | null {
  if (!whenGatesPass(rule, input, bikeAttrs, partAttrs)) return null;

  const bikeVal = readBikeValue(rule, bikeAttrs);
  const partVal = rule.dimension ? partAttrs[rule.dimension] : undefined;

  // R081-style: bike value only + serial gate (part optional)
  if (
    rule.severity === "hard_block" &&
    rule.bike_values?.length &&
    !rule.part_values &&
    rule.when_serial_present !== undefined
  ) {
    if (!bikeVal || isNaValue(bikeVal)) {
      // missing attr → skip hard_block
      return null;
    }
    if (!rule.bike_values.includes(bikeVal)) return null;
    return {
      id: rule.id,
      severity: rule.severity,
      message_de: rule.message_de,
      dimension: rule.dimension,
      bike_value: bikeVal,
    };
  }

  // missing attr skips hard_block / soft_warn (contract)
  if (rule.severity === "hard_block" || rule.severity === "soft_warn") {
    if (rule.match_mode === "either_has") {
      if (!matchValuePair(rule, bikeVal, partVal)) return null;
      return {
        id: rule.id,
        severity: rule.severity,
        message_de: rule.message_de,
        dimension: rule.dimension,
        bike_value: bikeVal,
        part_value: partVal,
      };
    }

    const needPart = !!rule.part_values?.length;
    const needBike = !!rule.bike_values?.length;
    if (needBike && (bikeVal === undefined || isNaValue(bikeVal))) return null;
    if (needPart && (partVal === undefined || isNaValue(partVal))) return null;
    if (!matchValuePair(rule, bikeVal, partVal)) return null;

    return {
      id: rule.id,
      severity: rule.severity,
      message_de: rule.message_de,
      dimension: rule.bike_values_from || rule.dimension,
      bike_value: bikeVal,
      part_value: partVal,
    };
  }

  return null;
}

function pickResult(matched: MatchedCompatRule[]): CompatSeverity {
  for (const sev of PRECEDENCE) {
    if (sev === "ok") continue;
    if (matched.some((m) => m.severity === sev)) return sev;
  }
  return "ok";
}

/**
 * Pure Compat Gates v1 evaluator.
 * Honors evaluation_contract: missing attr skips hard_block unless require_attr;
 * `na` ignores dimension; precedence hard_block > require_attr > soft_warn > ok.
 */
export function evaluateCompat(input: EvaluateCompatInput): EvaluateCompatResult {
  const fromTags = parseShopifyTags(input.partTags ?? [], ruleset.dimensions);
  const partAttrs = normalizeAttrMap(mergeAttrs(fromTags, input.partAttrs));
  const bikeAttrs = normalizeAttrMap(input.bikeAttrs ?? {});

  const matched: MatchedCompatRule[] = [];
  const missing = new Set<string>();

  for (const rule of ruleset.rules) {
    if (rule.severity === "require_attr") {
      const r = evaluateRequireAttr(rule, bikeAttrs, partAttrs, input);
      if (r.matched) {
        matched.push({
          id: rule.id,
          severity: "require_attr",
          message_de: rule.message_de,
          dimension: rule.require_attr,
        });
        if (r.missing) missing.add(r.missing);
      }
      continue;
    }

    const hit = evaluateDimensionRule(rule, bikeAttrs, partAttrs, input);
    if (hit) matched.push(hit);
  }

  return {
    ruleset: ruleset.version,
    result: pickResult(matched),
    matched,
    missing_attrs: [...missing],
  };
}

export function getCompatGatesRuleset(): CompatGatesRuleset {
  return ruleset;
}
