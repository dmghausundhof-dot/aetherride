/**
 * Loop honesty for Discover (align #37 / D-60-02).
 *
 * Rundkurs / ~60 lens: only real closed routes — never fill with linear A→B.
 * Curated seeds: trust explicit is_loop | loop | closed flags.
 */

/** Explicit catalog/seed flags that mean "honest loop". */
export function seedIsLoopFlag(seed: {
  is_loop?: boolean;
  loop?: boolean;
  closed?: boolean;
}): boolean {
  return seed.is_loop === true || seed.loop === true || seed.closed === true;
}

/** Suggestion/catalog field used by Discover cards + filters. */
export function isHonestLoopSuggestion(route: { loop?: boolean }): boolean {
  return route.loop === true;
}
