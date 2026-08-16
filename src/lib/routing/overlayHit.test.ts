/**
 * Overlay tap identity + S3+ honesty.
 * npx tsx src/lib/routing/overlayHit.test.ts
 */
import assert from "node:assert/strict";
import {
  overlayFeatureToHit,
  overlayHitToSegment,
  osmTrailToSegment,
  parseOsmWayId,
} from "./overlayHit";
import { parseOsmMtbScale } from "./bikeOverlayClass";
import { normalizeMtbScale } from "../coverage/osmLive";
import { overlayScaleLabels } from "./profiles";

function testParseOsmWayId() {
  assert.equal(parseOsmWayId("12345"), "12345");
  assert.equal(parseOsmWayId("way/12345"), "12345");
  assert.equal(parseOsmWayId("osm-way-12345"), "12345");
  assert.equal(parseOsmWayId("way-999"), "999");
  assert.equal(parseOsmWayId(""), null);
  assert.equal(parseOsmWayId(null), null);
}

function testOverlayHitIdentityAndS3plus() {
  const hit = overlayFeatureToHit({
    properties: {
      osm_id: "way/4242",
      name: "Flow Line",
      mtb_scale: "S3",
      highway: "path",
    },
    geometry: {
      type: "LineString",
      coordinates: [
        [8.4, 48.6],
        [8.41, 48.61],
      ],
    },
  });
  assert.ok(hit);
  assert.equal(hit.id, "osm-way-4242");
  assert.equal(hit.mtbScale, "S3+", "collapsed OSM 3 / tile S3 displays as S3+");
  assert.equal(hit.url, "https://www.openstreetmap.org/way/4242");
  assert.equal(hit.hasOsmName, true);
  const seg = overlayHitToSegment(hit);
  assert.equal(seg.provider, "osm");
  assert.equal(seg.difficulty, "S3+");
}

function testSacScaleNeverBecomesSScale() {
  assert.equal(normalizeMtbScale(undefined), "offen");
  assert.equal(parseOsmMtbScale(undefined, undefined), null);
  const hit = overlayFeatureToHit({
    properties: {
      osm_id: "7",
      highway: "path",
      sac_scale: "mountain_hiking",
    },
    geometry: {
      type: "LineString",
      coordinates: [
        [8.4, 48.6],
        [8.41, 48.61],
      ],
    },
  });
  assert.ok(hit);
  assert.equal(hit.mtbScale, "offen");
  assert.notEqual(hit.mtbScale, "S2");
}

function testOsmTrailToSegmentRejectsSeedsShape() {
  const seg = osmTrailToSegment({
    id: "osm-way-1",
    name: "Waldpfad",
    mtbScale: "S1",
    geometry: [
      [8.4, 48.6],
      [8.41, 48.61],
    ],
    center: [8.405, 48.605],
    hasOsmName: true,
  });
  assert.ok(seg);
  assert.equal(seg.provider, "osm");
  assert.equal(osmTrailToSegment({ id: "x", name: "n", geometry: [] }), null);
}

function testDownhillLegendSaysS3plus() {
  assert.deepEqual(overlayScaleLabels("downhill"), ["S1", "S2", "S3+"]);
}

testParseOsmWayId();
testOverlayHitIdentityAndS3plus();
testSacScaleNeverBecomesSScale();
testOsmTrailToSegmentRejectsSeedsShape();
testDownhillLegendSaysS3plus();
console.log("overlayHit.test.ts OK");
