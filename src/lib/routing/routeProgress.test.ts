import { describe, expect, it } from "vitest";
import {
  projectOntoRoute,
  updateOffRouteState,
} from "./routeProgress";
import { parseGpx } from "../import/gpx";

describe("routeProgress", () => {
  it("projects onto polyline", () => {
    const coords: [number, number][] = [
      [12, 47],
      [12.01, 47],
      [12.02, 47],
    ];
    const mid = projectOntoRoute(coords, 47, 12.01);
    expect(mid.crossTrackM).toBeLessThan(5);
    expect(mid.distanceAlongM).toBeGreaterThan(100);
  });

  it("off-route hysteresis", () => {
    expect(updateOffRouteState(false, 45)).toBe(true);
    expect(updateOffRouteState(true, 30)).toBe(true);
    expect(updateOffRouteState(true, 20)).toBe(false);
  });
});

describe("parseGpx", () => {
  it("reads track points", () => {
    const xml = `<gpx><trk><name>Testtrail</name><trkseg>
<trkpt lat="47.1" lon="12.2"><ele>800</ele></trkpt>
<trkpt lat="47.11" lon="12.21"><ele>820</ele></trkpt>
</trkseg></trk></gpx>`;
    const t = parseGpx(xml);
    expect(t?.name).toBe("Testtrail");
    expect(t?.coordinates.length).toBe(2);
  });
});
