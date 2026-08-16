/**
 * Run: npx tsx src/lib/home/hofCopy.test.ts
 */
import assert from "node:assert/strict";
import { hofCopy, HOF_COPY } from "./hofCopy";

const langs = ["de", "en", "fr", "it"] as const;

function testParity() {
  const keys = Object.keys(HOF_COPY).sort();
  for (const lang of langs) {
    assert.deepEqual(Object.keys(hofCopy(lang)).sort(), keys, lang);
  }
}

function testDeFallback() {
  assert.equal(HOF_COPY.rideOut, "Rausfahren");
  assert.equal(HOF_COPY.emptyStand, "Leerer Stand");
  assert.equal(HOF_COPY.shopTitle, "Der Laden");
  assert.equal(HOF_COPY.libraryMappe, "Die Mappe");
  assert.equal(HOF_COPY.tafelKicker, "Die Tafel");
  assert.equal(HOF_COPY.akteStimmen, "Stimmen");
  assert.equal(HOF_COPY.workshopTabBox, "Die Box");
  assert.equal(HOF_COPY.agoHours(3), "vor 3 Std.");
  assert.equal(HOF_COPY.skyDry("14"), "14° · eher trocken");
  assert.equal(HOF_COPY.communityNotes(3), "3 Stimmen zu dieser Runde");
}

function testChromeLangs() {
  assert.equal(hofCopy("en").rideOut, "Ride out");
  assert.equal(hofCopy("fr").rideOut, "Sortir");
  assert.equal(hofCopy("it").rideOut, "Esci");
  assert.equal(hofCopy("en").libraryMappe, "Die Mappe");
  assert.equal(hofCopy("fr").workshopTabBox, "Die Box");
  assert.equal(hofCopy("it").akteStimmen, "Stimmen");
  assert.ok(hofCopy("en").communityNotes(2).includes("Stimmen"));
}

testParity();
testDeFallback();
testChromeLangs();
console.log("hofCopy.test.ts OK");
