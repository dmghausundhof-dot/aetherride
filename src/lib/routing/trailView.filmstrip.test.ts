/**
 * npx tsx src/lib/routing/trailView.filmstrip.test.ts
 */
import assert from "node:assert/strict";
import { photosInCorridor, sampleAlongLine, type TrailPhoto } from "./trailView";

const line: [number, number][] = [
  [8.67, 49.4],
  [8.68, 49.4],
  [8.69, 49.4],
];

const shots: TrailPhoto[] = [
  {
    id: "on",
    source: "mapillary",
    imageUrl: "https://example.com/a.jpg",
    lat: 49.4002,
    lng: 8.68,
    headingDeg: 0,
    username: "a",
    title: "on",
    license: "CC BY-SA 4.0",
    attributionHtml: "Mapillary",
  },
  {
    id: "demo",
    source: "mapillary",
    imageUrl: "https://example.com/d.jpg",
    lat: 49.4002,
    lng: 8.68,
    headingDeg: 0,
    username: "d",
    title: "demo",
    license: "CC BY-SA 4.0",
    attributionHtml: "demo",
    demo: true,
  },
  {
    id: "far",
    source: "user",
    imageUrl: "https://example.com/f.jpg",
    lat: 49.5,
    lng: 8.68,
    headingDeg: 0,
    username: "f",
    title: "far",
    license: "CC BY-SA 4.0",
    attributionHtml: "user",
  },
];

const picked = photosInCorridor(shots, line);
assert.equal(picked.length, 1);
assert.equal(picked[0].id, "on");

const samples = sampleAlongLine(line, 3);
assert.equal(samples.length, 3);
assert.deepEqual(samples[0], line[0]);
assert.deepEqual(samples[2], line[2]);

console.log("trailView.filmstrip.test.ts OK");
