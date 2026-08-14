/**
 * GPS-first DACH coverage + Google Places (mock / no key).
 * Run: npx tsx src/lib/coverage/coverage.test.ts
 */
import assert from "node:assert/strict";
import { assembleCoverageLocal, parseBikeClass } from "./assemble";
import { seedLooksLikeHeidelberg } from "./seeds";
import { overlayRegionForPoint } from "./regions";
import { pointInDach } from "./dach";
import { fetchGooglePlacesNearby } from "./google";
import { clampBbox } from "./osmLive";

async function main() {
  function nearestTitle(lat: number, lng: number): string {
    const c = assembleCoverageLocal({ lat, lng });
    assert.ok(c.seeds.length >= 1, `seeds at ${lat},${lng}`);
    return `${c.seeds[0].id} ${c.seeds[0].title}`;
  }

  const wien = assembleCoverageLocal({ lat: 48.208, lng: 16.373, bikeClass: "mtb" });
  assert.equal(wien.inDach, true);
  assert.notEqual(wien.honesty, "outside_dach");
  assert.ok(wien.nearbySeedCount >= 1, "Wien has nearby seeds");
  assert.ok(
    /vienna|wien|prater|wienerwald/i.test(nearestTitle(48.208, 16.373)),
    `Wien nearest should be Vienna, got ${nearestTitle(48.208, 16.373)}`
  );
  assert.equal(
    seedLooksLikeHeidelberg(wien.seeds[0].id, wien.seeds[0].title),
    false,
    "Wien must not rank Heidelberg first"
  );
  assert.equal(overlayRegionForPoint(16.373, 48.208)?.id, "wien");

  const muc = assembleCoverageLocal({ lat: 48.137, lng: 11.575 });
  assert.ok(
    /munich|muenchen|fröttmaning|froettmaning|isar/i.test(
      nearestTitle(48.137, 11.575)
    ),
    `München nearest: ${nearestTitle(48.137, 11.575)}`
  );
  assert.equal(
    seedLooksLikeHeidelberg(muc.seeds[0].id, muc.seeds[0].title),
    false
  );
  assert.equal(overlayRegionForPoint(11.575, 48.137)?.id, "muenchen");

  const zh = assembleCoverageLocal({ lat: 47.376, lng: 8.541 });
  assert.ok(
    /zurich|zürich|seefeld|uetliberg/i.test(nearestTitle(47.376, 8.541)),
    `Zürich nearest: ${nearestTitle(47.376, 8.541)}`
  );
  assert.equal(seedLooksLikeHeidelberg(zh.seeds[0].id, zh.seeds[0].title), false);
  assert.equal(overlayRegionForPoint(8.541, 47.376)?.id, "zuerich");

  const hh = assembleCoverageLocal({ lat: 53.551, lng: 9.993 });
  assert.ok(
    /hamburg|alster|harburg/i.test(nearestTitle(53.551, 9.993)),
    `Hamburg nearest: ${nearestTitle(53.551, 9.993)}`
  );
  assert.equal(seedLooksLikeHeidelberg(hh.seeds[0].id, hh.seeds[0].title), false);
  assert.equal(overlayRegionForPoint(9.993, 53.551)?.id, "hamburg");

  const ocean = assembleCoverageLocal({ lat: 0, lng: -30 });
  assert.equal(ocean.inDach, false);
  assert.equal(ocean.honesty, "outside_dach");
  assert.ok(Array.isArray(ocean.seeds));
  assert.ok(Array.isArray(ocean.trails));
  assert.equal(ocean.trails.length, 0);
  assert.equal(ocean.google.configured, false);

  assert.equal(pointInDach(48.208, 16.373), true);
  assert.equal(pointInDach(0, 0), false);

  const huge = clampBbox({ west: 5, south: 47, east: 15, north: 55 });
  assert.ok(huge.east - huge.west <= 0.41, "bbox must stay viewport-sized");

  const noKey = await fetchGooglePlacesNearby({
    lat: 48.208,
    lng: 16.373,
    key: "",
  });
  assert.equal(noKey.configured, false);
  assert.equal(noKey.places.length, 0);
  assert.match(noKey.warning ?? "", /nicht konfiguriert/i);

  const mockFetch: typeof fetch = async (input) => {
    const url = String(input);
    if (url.includes("places.googleapis.com")) {
      return new Response(
        JSON.stringify({
          places: [
            {
              id: "ChIJmockBike",
              displayName: { text: "Radladen Wien" },
              location: { latitude: 48.209, longitude: 16.372 },
              types: ["bicycle_store"],
              googleMapsUri: "https://maps.google.com/?cid=1",
            },
          ],
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }
    return new Response("nope", { status: 404 });
  };

  const mocked = await fetchGooglePlacesNearby({
    lat: 48.208,
    lng: 16.373,
    key: "test-key-abcdefgh",
    fetchImpl: mockFetch,
  });
  assert.equal(mocked.configured, true);
  assert.equal(mocked.places.length, 1);
  assert.equal(mocked.places[0].name, "Radladen Wien");
  assert.equal(mocked.places[0].kind, "bike_shop");
  assert.equal(mocked.places[0].source, "google_places");
  assert.ok(mocked.places[0].mapsUrl.includes("http"));

  assert.equal(parseBikeClass("downhill"), "mtb");
  assert.equal(parseBikeClass("dh"), "mtb");
  assert.equal(parseBikeClass("mtb_enduro"), "mtb");
  assert.equal(parseBikeClass("gravel"), "gravel");
  assert.equal(parseBikeClass("ebike"), "gravel");
  assert.equal(parseBikeClass("urban"), "urban");
  assert.equal(parseBikeClass("road"), "road");
  assert.equal(parseBikeClass("unknown"), "road");

  console.log("coverage.test.ts OK");
}

void main();
