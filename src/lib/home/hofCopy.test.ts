/**
 * Run: npx tsx src/lib/home/hofCopy.test.ts
 */
import assert from "node:assert/strict";
import { hofCopy, HOF_COPY } from "./hofCopy";

const langs = ["de", "en", "fr", "it", "nl"] as const;

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
  assert.equal(hofCopy("en").shopTitle, "The shop");
  assert.equal(hofCopy("fr").shopTitle, "Le magasin");
  assert.equal(hofCopy("it").shopTitle, "Il negozio");
  assert.equal(hofCopy("nl").shopTitle, "De winkel");
  assert.equal(HOF_COPY.shopKicker, "Über den Hof");
  assert.equal(HOF_COPY.shopPartsForBike, "Teile für dein Rad");
  assert.equal(HOF_COPY.shopLookupInShop, "Im Laden nachschlagen");
  assert.equal(HOF_COPY.workshopEmpty, "Noch kein Rad hier");
  assert.equal(
    HOF_COPY.workshopEmptyHint,
    "Name und Typ reichen. Der Katalog ist Suche — Serienteile nur wenn du sie übernimmst.",
  );
  assert.notEqual(HOF_COPY.shopKicker, HOF_COPY.shopKicker.toUpperCase());
  assert.equal(HOF_COPY.ridePlannedKicker, "Geplante Tour");
  assert.notEqual(
    HOF_COPY.ridePlannedKicker,
    HOF_COPY.ridePlannedKicker.toUpperCase(),
  );
  assert.equal(HOF_COPY.libraryMappe, "Die Mappe");
  assert.equal(HOF_COPY.tafelKicker, "Die Tafel");
  assert.ok(HOF_COPY.tafelHint.includes("kein Feed"));
  assert.equal(HOF_COPY.togetherOut, "Zusammen raus");
  assert.notEqual(HOF_COPY.togetherOut, HOF_COPY.togetherOut.toUpperCase());
  assert.equal(HOF_COPY.akteStimmen, "Stimmen");
  assert.equal(HOF_COPY.akteMein, "Freigeben");
  assert.equal(HOF_COPY.workshopTabBox, "Die Box");
  assert.equal(HOF_COPY.workshopZoneToday, "Heute");
  assert.equal(HOF_COPY.workshopZoneOnBike, "Am Rad");
  assert.equal(HOF_COPY.workshopBikes, "Deine Räder");
  assert.notEqual(
    HOF_COPY.workshopZoneToday,
    HOF_COPY.workshopZoneToday.toUpperCase(),
  );
  assert.notEqual(
    HOF_COPY.workshopZoneOnBike,
    HOF_COPY.workshopZoneOnBike.toUpperCase(),
  );
  assert.notEqual(HOF_COPY.workshopBikes, HOF_COPY.workshopBikes.toUpperCase());
  assert.equal(HOF_COPY.agoHours(3), "vor 3 Std.");
  assert.equal(HOF_COPY.skyDry("14"), "14° · eher trocken");
  assert.equal(
    HOF_COPY.gpsUnknown,
    "Kein Standort — Himmel und Tor warten auf GPS."
  );
  assert.equal(
    HOF_COPY.gateWetClosed,
    "Trails nass — kein ehrlicher Asphalt-Rundkurs in der Nähe"
  );
  assert.equal(HOF_COPY.communityNotes(3), "3 Stimmen zu dieser Runde");
}

function testChromeLangs() {
  assert.equal(hofCopy("en").rideOut, "Ride out");
  assert.equal(hofCopy("fr").rideOut, "Sortir");
  assert.equal(hofCopy("it").rideOut, "Esci");
  assert.equal(hofCopy("nl").rideOut, "Eruit");
  assert.equal(hofCopy("en").libraryMappe, "Die Mappe");
  assert.equal(hofCopy("fr").workshopTabBox, "Die Box");
  assert.equal(hofCopy("it").akteStimmen, "Stimmen");
  assert.equal(hofCopy("nl").akteStimmen, "Stimmen");
  assert.equal(HOF_COPY.shopNoImage, "Kein Bild");
  assert.equal(HOF_COPY.shopGuideHow, "Wie der Laden funktioniert");
  assert.equal(hofCopy("en").shopNoImage, "No image");
  assert.equal(hofCopy("fr").shopCancel, "Retour");
  assert.equal(hofCopy("it").shopProductUnavailable, "Prodotto non disponibile");
  assert.equal(HOF_COPY.shopCyclingParts, "Teile");
  assert.equal(hofCopy("en").shopCyclingParts, "Parts");
  assert.equal(hofCopy("fr").shopCyclingParts, "Pièces");
  assert.equal(hofCopy("it").shopCyclingParts, "Pezzi");
  assert.equal(hofCopy("nl").shopCyclingParts, "Onderdelen");
  for (const lang of langs) {
    const c = hofCopy(lang);
    assert.notEqual(c.shopCyclingParts, "Cycling Parts", lang);
    assert.notEqual(c.shopTitle, c.shopCyclingParts, lang);
    assert.notEqual(c.workshopZoneToday, c.workshopZoneToday.toUpperCase(), lang);
    assert.notEqual(
      c.workshopZoneOnBike,
      c.workshopZoneOnBike.toUpperCase(),
      lang,
    );
    assert.notEqual(c.workshopBikes, c.workshopBikes.toUpperCase(), lang);
    assert.notEqual(c.shopKicker, c.shopKicker.toUpperCase(), lang);
    assert.notEqual(
      c.ridePlannedKicker,
      c.ridePlannedKicker.toUpperCase(),
      lang,
    );
  }
}

testParity();
testDeFallback();
testChromeLangs();
console.log("hofCopy.test.ts OK");
