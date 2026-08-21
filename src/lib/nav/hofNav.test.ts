/**
 * Run: npx tsx src/lib/nav/hofNav.test.ts
 */
import assert from "node:assert/strict";
import { HOF_NAV, hofDoorForPath, isHofNavActive } from "./hofNav";

assert.equal(HOF_NAV.length, 4);
assert.deepEqual(
  HOF_NAV.map((item) => item.id),
  ["hof", "karte", "platz", "werkstatt"]
);
assert.ok(!HOF_NAV.some((item) => item.href === "/shop"));
assert.ok(!HOF_NAV.some((item) => item.id === "laden"));

assert.equal(isHofNavActive("/shop", "/garage"), true);
assert.equal(isHofNavActive("/shop/p/sram-kette", "/garage"), true);
assert.equal(isHofNavActive("/checkout", "/garage"), true);
assert.equal(isHofNavActive("/shop", "/home"), false);
assert.equal(isHofNavActive("/home", "/home"), true);
assert.equal(isHofNavActive("/discover", "/discover"), true);
assert.equal(isHofNavActive("/planner", "/discover"), true);
assert.equal(isHofNavActive("/library", "/library"), true);

assert.equal(hofDoorForPath("/profile"), "hof");
assert.equal(hofDoorForPath("/chat"), "hof");
assert.equal(hofDoorForPath("/privacy"), "hof");
assert.equal(hofDoorForPath("/activities/42"), "hof");
assert.equal(hofDoorForPath("/post-ride"), "hof");
assert.equal(isHofNavActive("/profile", "/home"), true);
assert.equal(isHofNavActive("/profile", "/discover"), false);
assert.equal(isHofNavActive("/chat", "/garage"), false);
assert.equal(hofDoorForPath("/produkt"), null);

console.log("hofNav.test.ts OK");
