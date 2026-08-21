export { evaluateCompat, getCompatGatesRuleset } from "./evaluate";
export {
  flattenBikeModelToAttrs,
  getBikeSchemaSummary,
  normalizeCompatValue,
} from "./bikeEntity";
export { parseShopifyTags, mergeAttrs } from "./tags";
export type {
  BikeEntityModel,
  BikeSchemaSummary,
  CompatAttrMap,
  CompatGatesRuleset,
  CompatSeverity,
  EvaluateCompatInput,
  EvaluateCompatResult,
  MatchedCompatRule,
} from "./types";
