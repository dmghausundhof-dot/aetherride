/**
 * Run: npx tsx src/lib/explore/workspace.test.ts
 */
import assert from "node:assert/strict";
import { plannerHref, plannerHrefFromSearch } from "./workspace";

assert.equal(plannerHref(), "/discover?panel=plan");
assert.equal(
  plannerHref({ tour: "r-heidelberg-city" }),
  "/discover?panel=plan&tour=r-heidelberg-city",
);
assert.equal(
  plannerHrefFromSearch({ tour: "idea-koenigstuhl", profile: "gravel" }),
  "/discover?panel=plan&tour=idea-koenigstuhl&profile=gravel",
);

console.log("workspace.test.ts OK");
