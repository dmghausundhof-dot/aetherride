import assert from "node:assert/strict";
import { DEFAULT_LEGAL_EMAIL, legalContactEmail } from "./siteLegal";

function testDefaultContactEmail() {
  assert.equal(DEFAULT_LEGAL_EMAIL, "hello@aetherride.app");
  assert.match(legalContactEmail(), /@/);
}

testDefaultContactEmail();
console.log("siteLegal.test.ts OK");
