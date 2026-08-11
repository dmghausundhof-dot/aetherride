/** Compat Gates v1 — shared types (Research handoff). */

export type CompatSeverity =
  | "hard_block"
  | "require_attr"
  | "soft_warn"
  | "ok";

export type CompatAttrMap = Record<string, string>;

export interface CompatDimensionDef {
  id: string;
  values: string[];
  shopify_tag_prefix: string;
}

export interface CompatWhenEitherDimension {
  dimension: string;
  values: string[];
}

export interface CompatRuleDef {
  id: string;
  severity: Exclude<CompatSeverity, "ok">;
  message_de: string;
  dimension?: string;
  /** Values compared on the bike side (default dimension, or bike_values_from). */
  bike_values?: string[];
  /** Optional override: read bike value from this dimension id. */
  bike_values_from?: string;
  part_values?: string[];
  /** Also match with bike/part values swapped. */
  bidirectional?: boolean;
  /** require_attr target dimension/attr id */
  require_attr?: string;
  require_on?: "bike" | "part" | "either";
  when_part_tag_regex?: string;
  when_part_tag_prefixes?: string[];
  when_slot_in?: string[];
  /** If set, rule only applies when serialPresent === this value. */
  when_serial_present?: boolean;
  /** Extra gate: bike or part has dimension in values. */
  when_either_dimension?: CompatWhenEitherDimension;
  /** soft_warn helper: either side carries dimension value */
  match_mode?: "default" | "either_has";
  also_either_dimension?: CompatWhenEitherDimension;
}

export interface CompatEvaluationContract {
  missing_attr_skips_hard_block_unless_require_attr: boolean;
  na_ignores_dimension: boolean;
  precedence: CompatSeverity[];
}

export interface CompatGatesRuleset {
  version: string;
  demo_priority?: boolean;
  evaluation_contract: CompatEvaluationContract;
  dimensions: CompatDimensionDef[];
  rules: CompatRuleDef[];
}

export interface EvaluateCompatInput {
  bikeAttrs: CompatAttrMap;
  partTags: string[];
  partAttrs?: CompatAttrMap;
  slot?: string;
  serialPresent?: boolean;
}

export interface MatchedCompatRule {
  id: string;
  severity: Exclude<CompatSeverity, "ok">;
  message_de: string;
  dimension?: string;
  bike_value?: string;
  part_value?: string;
}

export interface EvaluateCompatResult {
  ruleset: string;
  result: CompatSeverity;
  matched: MatchedCompatRule[];
  missing_attrs: string[];
}

/** Nested bike entity (Bike Entity Schema v1) — thin runtime shape. */
export interface BikeEntityModel {
  compat_tags?: string[];
  drivetrain?: Record<string, unknown>;
  brakes?: Record<string, unknown>;
  cockpit?: Record<string, unknown>;
  ebike?: Record<string, unknown>;
  frame?: Record<string, unknown>;
  /** Allow additional groups without failing flatten. */
  [group: string]: unknown;
}

export interface BikeSchemaFieldSummary {
  group: string;
  field: string;
  maps_to_compat_dim: string;
}

export interface BikeSchemaSummary {
  version: string;
  geometry_required: boolean;
  fields: BikeSchemaFieldSummary[];
  value_aliases: Record<string, string>;
  notes: string[];
}
