/**
 * FlowLine Rad-Stand marks — Ausführen: npx tsx src/lib/garage/radMark.test.ts
 */
import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { join } from "node:path";
import {
  RAD_EMPTY_STAND,
  RAD_EMPTY_STAND_MARK,
  RAD_MARKS,
  RAD_MARK_SRC,
  RAD_NO_PHOTO,
  RAD_STAND_GROUND,
  RAD_STAND_HEADER,
  radMarkForChip,
  radMarkForItem,
  radMarkForMeasure,
  radMarkForReadiness,
  radMarkForSlot,
  radSilhouetteSrc,
} from "./radMark";

const root = join(import.meta.dirname, "../../..");
for (const name of RAD_MARKS) {
  assert.match(RAD_MARK_SRC[name], /^\/garage\/glyph-.+\.svg$/, name);
  assert.ok(
    existsSync(join(root, "public", RAD_MARK_SRC[name].slice(1))),
    `${name} svg`
  );
}
for (const src of [
  RAD_STAND_HEADER,
  RAD_STAND_GROUND,
  RAD_EMPTY_STAND,
  RAD_EMPTY_STAND_MARK,
  RAD_NO_PHOTO,
]) {
  assert.ok(existsSync(join(root, "public", src.slice(1))), src);
}

assert.equal(radMarkForItem("pressureUnknown"), "pressure");
assert.equal(radMarkForItem("sagUnknown"), "sag");
assert.equal(radMarkForItem("lightsMissing"), "lights");
assert.equal(radMarkForItem("dueCare"), "care");
assert.equal(radMarkForItem("setActive"), "stand");
assert.equal(radMarkForItem("parkTrail"), "setup");

assert.equal(radMarkForReadiness("ready"), "ready");
assert.equal(radMarkForReadiness("almost"), "almost");
assert.equal(radMarkForReadiness("unknown"), "unknown");

assert.equal(radMarkForChip("Druck"), "pressure");
assert.equal(radMarkForChip("Licht"), "lights");
assert.equal(radMarkForChip("Ausweis"), "identity");
assert.equal(radMarkForChip("140/150 mm"), "travel");
assert.equal(radMarkForChip('29"'), "pressure");
assert.equal(radMarkForChip("700c"), "pressure");
assert.equal(radMarkForChip("27.5\""), "pressure");

assert.equal(radMarkForSlot("tire_front"), "pressure");
assert.equal(radMarkForSlot("chain"), "chain");
assert.equal(radMarkForSlot("brake_rear"), "brakes");
assert.equal(radMarkForSlot("battery"), "battery");
assert.equal(radMarkForSlot("handlebar"), "cockpit");
assert.equal(radMarkForSlot("frame"), "parts");

assert.equal(radMarkForMeasure("pressure"), "pressure");
assert.equal(radMarkForMeasure("sag"), "sag");
assert.equal(radMarkForMeasure("travel"), "travel");
assert.match(radSilhouetteSrc({ category: "gravel" }), /gravel\.svg$/);
assert.match(radSilhouetteSrc({ category: "emtb" }), /emtb\.svg$/);
assert.match(radSilhouetteSrc({ category: "hiking" }), /hiking\.svg$/);
assert.notEqual(radSilhouetteSrc({ category: "hiking" }), RAD_NO_PHOTO);
assert.ok(
  existsSync(join(root, "public/garage/silhouettes/hiking.svg")),
  "hiking svg"
);

console.log("radMark.test.ts ok");
