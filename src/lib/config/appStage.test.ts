/**
 * Run: npx tsx src/lib/config/appStage.test.ts
 */
import assert from "node:assert/strict";
import {
  appStage,
  isAppLaunched,
  isCommerceOpen,
  isPublicIndexable,
} from "./appStage";

const prevPublic = process.env.NEXT_PUBLIC_APP_STAGE;
const prevApp = process.env.APP_STAGE;

try {
  delete process.env.NEXT_PUBLIC_APP_STAGE;
  delete process.env.APP_STAGE;
  assert.equal(appStage(), "development", "unset stage stays development");
  assert.equal(isAppLaunched(), false);
  assert.equal(isCommerceOpen(), false);
  assert.equal(isPublicIndexable(), false);

  process.env.NEXT_PUBLIC_APP_STAGE = "preview";
  assert.equal(appStage(), "preview");
  assert.equal(isCommerceOpen(), false, "preview still cannot sell");

  process.env.NEXT_PUBLIC_APP_STAGE = "launched";
  assert.equal(appStage(), "launched");
  assert.equal(isCommerceOpen(), true);
  assert.equal(isPublicIndexable(), true);

  process.env.NEXT_PUBLIC_APP_STAGE = "production";
  assert.equal(
    appStage(),
    "development",
    "NODE-like 'production' is not a launch switch"
  );
  assert.equal(isCommerceOpen(), false);
} finally {
  if (prevPublic === undefined) delete process.env.NEXT_PUBLIC_APP_STAGE;
  else process.env.NEXT_PUBLIC_APP_STAGE = prevPublic;
  if (prevApp === undefined) delete process.env.APP_STAGE;
  else process.env.APP_STAGE = prevApp;
}

console.log("appStage.test.ts OK");
