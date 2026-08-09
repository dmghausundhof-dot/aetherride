/**
 * Smoke: npx tsx src/lib/strava/oauthState.test.ts
 */
import assert from "node:assert/strict";

process.env.STRAVA_CLIENT_SECRET = "test-secret-for-hmac";

import {
  signStravaOAuthState,
  verifyStravaOAuthState,
} from "./oauthState";

const state = signStravaOAuthState("user-123", { mobile: true });
const parsed = verifyStravaOAuthState(state);
assert.ok(parsed);
assert.equal(parsed!.userId, "user-123");
assert.equal(parsed!.mobile, true);
assert.equal(verifyStravaOAuthState("tampered." + state.split(".")[1]), null);

console.log("strava oauthState ok");
