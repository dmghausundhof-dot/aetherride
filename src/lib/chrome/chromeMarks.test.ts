/**
 * Run: npx tsx src/lib/chrome/chromeMarks.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { CHROME_MARKS, CHROME_MARK_SRC } from "./chromeMarks";

const MUTED = "#9CA3AF";
const ORANGE = "#FF6A00";

for (const name of CHROME_MARKS) {
  const src = CHROME_MARK_SRC[name];
  const disk = `public${src}`;
  assert.ok(existsSync(disk), `${name} missing at ${disk}`);
  const svg = readFileSync(disk, "utf8");
  assert.ok(svg.includes("FlowLine"), `${name} titled FlowLine`);
  if (!src.startsWith("/chrome/")) continue;
  assert.ok(svg.includes(MUTED), `${name} needs muted stroke`);
  assert.ok(svg.includes(ORANGE), `${name} needs orange gesture`);
}

const door = readFileSync("src/components/landing/DoorIcon.tsx", "utf8");
assert.ok(door.includes("ChromeGlyph"), "landing doors use FlowLine marks");
assert.ok(!door.includes("lucide-react"), "landing doors drop Lucide");

const nav = readFileSync("src/components/app/HofThresholdNav.tsx", "utf8");
assert.ok(nav.includes("ChromeGlyph"), "threshold tabs use FlowLine marks");
assert.ok(!nav.includes("from \"lucide-react\""), "threshold tabs drop Lucide");

const discover = readFileSync("src/app/discover/page.tsx", "utf8");
assert.ok(discover.includes('discover-sheet-${id}'), "discover sheet tabs stay");
assert.ok(!discover.includes("Zap"), "discover sheet drops Lucide Zap");
assert.ok(
  discover.includes('["quick", copy.mapSheetNear, "locate"]'),
  "nearby sheet tab is FlowLine locate"
);

const home = readFileSync("src/components/landing/HomePageBody.tsx", "utf8");
assert.ok(home.includes('name="karte"'), "landing website card uses FlowLine karte");
assert.ok(!home.includes("<Map "), "landing does not call JS Map as a glyph");

console.log("chromeMarks.test.ts OK");
