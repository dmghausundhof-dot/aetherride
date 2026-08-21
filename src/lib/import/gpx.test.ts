/**
 * npx tsx src/lib/import/gpx.test.ts
 */
import assert from "node:assert/strict";
import { parseGpx } from "./gpx";

const xml = `
<gpx><trk><name>Testtrail</name><trkseg>
<trkpt lat="47.1" lon="12.2"><ele>800</ele></trkpt>
<trkpt lat="47.11" lon="12.21"><ele>820</ele></trkpt>
</trkseg></trk></gpx>
`;

const t = parseGpx(xml);
assert.ok(t);
assert.equal(t.name, "Testtrail");
assert.equal(t.coordinates.length, 2);
assert.equal(t.coordinates[0]?.length, 3);
assert.equal(t.coordinates[0]?.[2], 800);
assert.ok(t.distanceKm > 0);
assert.ok(t.elevationM > 0);

console.log("gpx.test.ts ok");
