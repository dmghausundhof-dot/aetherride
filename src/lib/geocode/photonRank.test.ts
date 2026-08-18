/**
 * npx tsx src/lib/geocode/photonRank.test.ts
 */
import assert from "node:assert/strict";
import {
  dropStationJunkHits,
  geocodeHitScore,
  nameMatchesQuery,
  rankGeocodeHits,
  stationFallbackQueries,
} from "./photonRank";

assert.equal(nameMatchesQuery("Berlin", "Berlin"), true);
assert.equal(nameMatchesQuery("Berlin-Mitte", "Berlin"), true);
assert.equal(nameMatchesQuery("Berlingen", "Berlin"), false);
assert.equal(nameMatchesQuery("Berliner Straße", "Berlin"), false);

const ranked = rankGeocodeHits("Berlin", [
  {
    label: "Berlingen, Moselle, Frankreich",
    lat: 49.24,
    lng: 6.67,
    kind: "city",
  },
  {
    label: "Berliner Straße, Sandhausen",
    lat: 49.37,
    lng: 8.66,
    kind: "street",
  },
  {
    label: "Berlin, Deutschland",
    lat: 52.52,
    lng: 13.4,
    kind: "city",
  },
]);
assert.equal(ranked[0].label.startsWith("Berlin,"), true);
assert.ok(
  geocodeHitScore("Berlin", ranked[0]) >
    geocodeHitScore("Berlin", {
      label: "Berlingen, Moselle, Frankreich",
      lat: 49.24,
      lng: 6.67,
      kind: "city",
    })
);

const hbf = rankGeocodeHits("Hauptbahnhof Frankfurt", [
  {
    label: "Frankfurt, Hessen, Deutschland",
    lat: 50.11,
    lng: 8.68,
    kind: "city",
    name: "Frankfurt",
  },
  {
    label: "Frankfurt Hauptbahnhof, Frankfurt, Deutschland",
    lat: 50.107,
    lng: 8.664,
    kind: "station",
    name: "Frankfurt Hauptbahnhof",
  },
]);
assert.equal(hbf[0].kind, "station", "Hbf query prefers the station");
assert.ok(
  geocodeHitScore("Hauptbahnhof Frankfurt", hbf[0]) >
    geocodeHitScore("Hauptbahnhof Frankfurt", {
      label: "Frankfurt, Hessen, Deutschland",
      lat: 50.11,
      lng: 8.68,
      kind: "city",
      name: "Frankfurt",
    })
);

const wiesloch = rankGeocodeHits("Hauptbahnhof Wiesloch", [
  {
    label: "Wiesloch, Baden-Württemberg, Deutschland",
    lat: 49.295,
    lng: 8.698,
    kind: "city",
    name: "Wiesloch",
  },
  {
    label: "Wiesloch-Walldorf Bahnhof, Wiesloch, Deutschland",
    lat: 49.291,
    lng: 8.664,
    kind: "station",
    name: "Wiesloch-Walldorf Bahnhof",
  },
]);
assert.equal(
  wiesloch[0].kind,
  "station",
  "Wiesloch Hbf query prefers the station, not the city"
);

const photonHouse = rankGeocodeHits("Hauptbahnhof Frankfurt", [
  {
    label: "Hauptbahnhof Frankfurt (Oder), Frankfurt (Oder), Deutschland",
    lat: 52.336,
    lng: 14.546,
    kind: "house",
    name: "Hauptbahnhof Frankfurt (Oder)",
  },
  {
    label: "Frankfurt (Main) Hauptbahnhof, Frankfurt am Main, Deutschland",
    lat: 50.107,
    lng: 8.664,
    kind: "house",
    name: "Frankfurt (Main) Hauptbahnhof",
  },
]);
assert.ok(
  photonHouse[0].label.includes("Main"),
  "Photon house-type Hbf: Main before Oder"
);

const cityOnly = rankGeocodeHits("Frankfurt", [
  {
    label: "Frankfurt Hauptbahnhof, Frankfurt, Deutschland",
    lat: 50.107,
    lng: 8.664,
    kind: "station",
    name: "Frankfurt Hauptbahnhof",
  },
  {
    label: "Frankfurt, Hessen, Deutschland",
    lat: 50.11,
    lng: 8.68,
    kind: "city",
    name: "Frankfurt",
  },
]);
assert.equal(cityOnly[0].kind, "city", "plain city query still prefers the city");

assert.deepEqual(stationFallbackQueries("Hauptbahnhof Wiesloch"), [
  "Bahnhof Wiesloch",
  "Wiesloch",
]);
assert.deepEqual(stationFallbackQueries("Wiesloch"), []);

const wieslochLive = rankGeocodeHits("Hauptbahnhof Wiesloch", [
  {
    label: "RadService-Punkt Bahnhof Wiesloch-Walldorf, Wiesloch",
    lat: 49.291,
    lng: 8.664,
    kind: "house",
    name: "RadService-Punkt Bahnhof Wiesloch-Walldorf",
  },
  {
    label: "Wiesloch-Walldorf, Wiesloch, Deutschland",
    lat: 49.2914,
    lng: 8.6641,
    kind: "station",
    name: "Wiesloch-Walldorf",
  },
  {
    label: "Wiesloch-Walldorf Bahnhof Steig A, Wiesloch",
    lat: 49.2912,
    lng: 8.6638,
    kind: "house",
    name: "Wiesloch-Walldorf Bahnhof Steig A",
  },
]);
assert.equal(
  wieslochLive[0].kind,
  "station",
  "railway station beats repair point and bus Steig"
);

const cleaned = dropStationJunkHits("Hauptbahnhof Wiesloch", wieslochLive);
assert.equal(cleaned.length, 1);
assert.equal(cleaned[0].kind, "station");

console.log("photonRank.test.ts OK");
