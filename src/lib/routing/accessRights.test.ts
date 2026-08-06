import {
  evaluateAccessForEdges,
  JURISDICTIONS,
} from "./accessRights";
import type { RouteEdgeDemo } from "./profiles";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const edgesTirol: RouteEdgeDemo[] = [
  {
    id: "ok",
    distanceM: 100,
    highway: "cycleway",
    bicycleAccess: "yes",
    mtbOfficial: true,
    latlng: [
      [47.45, 12.15],
      [47.451, 12.151],
    ],
  },
  {
    id: "forest",
    distanceM: 200,
    highway: "track",
    surface: "gravel",
    bicycleAccess: "unknown",
    latlng: [
      [47.451, 12.151],
      [47.452, 12.152],
    ],
  },
  {
    id: "banned",
    distanceM: 50,
    highway: "path",
    bicycleAccess: "no",
    latlng: [
      [47.452, 12.152],
      [47.453, 12.153],
    ],
  },
];

const tirol = evaluateAccessForEdges(edgesTirol, "AT-7");
assert(tirol.blocked, "tirol blocks bicycle=no");
assert(tirol.blockedEdgeIds.has("banned"), "banned edge blocked");
assert(!tirol.blockedEdgeIds.has("forest"), "forest is warn not block");
assert(
  tirol.findings.some((f) => f.ruleId === "AT-7-forest-unverified"),
  "forest gray zone"
);
assert(tirol.findings.every((f) => f.short && f.more), "short+more");
assert(JURISDICTIONS["AT-7"].legalReviewedAt == null, "G-5 open");
assert(JURISDICTIONS["DE-BY"].legalReviewedAt == null, "G-5 BY open");
assert(tirol.legalGateOpen === true, "legalGateOpen = pending");
assert(
  tirol.legalNoteShort.includes("Legal-Review") ||
    tirol.legalNoteShort.includes("G-5"),
  "legal note mentions G-5"
);
assert(!tirol.legalNoteShort.includes("juristisch geprüft"), "no false claim");

const edgesBy: RouteEdgeDemo[] = [
  {
    id: "narrow",
    distanceM: 80,
    highway: "path",
    widthM: 1.1,
    bicycleAccess: "unknown",
    latlng: [
      [47.5, 11.5],
      [47.501, 11.501],
    ],
  },
  {
    id: "off",
    distanceM: 30,
    highway: "path",
    offTrail: true,
    latlng: [
      [47.501, 11.501],
      [47.502, 11.502],
    ],
  },
  {
    id: "no",
    distanceM: 20,
    highway: "track",
    bicycleAccess: "no",
    latlng: [
      [47.502, 11.502],
      [47.503, 11.503],
    ],
  },
];

const by = evaluateAccessForEdges(edgesBy, "DE-BY");
assert(by.blockedEdgeIds.has("no"), "BY bicycle=no block");
assert(by.blockedEdgeIds.has("off"), "BY offtrail block");
assert(
  by.findings.some((f) => f.ruleId === "DE-BY-suitability-uncertain"),
  "BY suitability warn"
);

console.log("accessRights.test OK", {
  tirolFindings: tirol.findings.length,
  byFindings: by.findings.length,
});
