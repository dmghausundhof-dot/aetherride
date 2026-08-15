import assert from "node:assert/strict";
import {
  isMarketingNavActive,
  isPublicMarketingPath,
  safeAppNextPath,
} from "./marketingNav";

function testMarketingNavProduktOnLanding() {
  assert.equal(isMarketingNavActive("/", "/produkt"), false);
  assert.equal(isMarketingNavActive("/produkt", "/produkt"), true);
  assert.equal(isMarketingNavActive("/guides", "/produkt"), false);
  assert.equal(isMarketingNavActive("/guides/web-vs-app", "/guides"), true);
}

function testPublicMarketingPaths() {
  assert.equal(isPublicMarketingPath("/"), true);
  assert.equal(isPublicMarketingPath("/guides/web-vs-app"), true);
  assert.equal(isPublicMarketingPath("/tours/r-heidelberg-city"), true);
  assert.equal(isPublicMarketingPath("/community"), true);
  assert.equal(isPublicMarketingPath("/anmelden"), true);
  assert.equal(isPublicMarketingPath("/share/t/abc"), true);
  assert.equal(isPublicMarketingPath("/u/luka"), true);
  assert.equal(isPublicMarketingPath("/legal/impressum"), true);
  assert.equal(isPublicMarketingPath("/community/moderation"), false);
  assert.equal(isPublicMarketingPath("/home"), false);
  assert.equal(isPublicMarketingPath("/discover"), false);
  assert.equal(isPublicMarketingPath("/library"), false);
}

function testSafeNextPath() {
  assert.equal(safeAppNextPath("/garage"), "/garage");
  assert.equal(safeAppNextPath("//evil.test"), "/home");
  assert.equal(safeAppNextPath("https://evil.test"), "/home");
  assert.equal(safeAppNextPath(null), "/home");
}

testMarketingNavProduktOnLanding();
testPublicMarketingPaths();
testSafeNextPath();
console.log("marketingNav.test.ts OK");
