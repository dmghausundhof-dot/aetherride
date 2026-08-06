import { buildPostRideAnalysis } from "./setupRecommendation";
import type { Bike, Ride, RideFeedback } from "@/types";
import type { BikeCalibration } from "@/lib/sensor/calibration";

function assert(c: boolean, m: string) {
  if (!c) throw new Error(m);
}

const bike = {
  id: "b1",
  name: "Test",
  category: "mtb_enduro",
  type: "enduro",
  travelFrontMm: 160,
  isActive: true,
  isEbike: false,
  createdAt: "",
  updatedAt: "",
  components: [],
  setups: [
    {
      id: "s1",
      bikeId: "b1",
      version: 1,
      label: "OEM",
      conditions: "general",
      values: [
        {
          bikeComponentId: "c1",
          slot: "fork",
          adjusterKey: "rebound",
          valueNum: 6,
          unit: "clicks",
          outOfSpec: false,
        },
        {
          bikeComponentId: "c1",
          slot: "fork",
          adjusterKey: "air_pressure_psi",
          valueNum: 70,
          unit: "psi",
          outOfSpec: false,
        },
      ],
      createdAt: "",
      createdBy: "user",
      isCurrent: true,
    },
  ],
  totalOdometerKm: 100,
  totalHours: 10,
  currentSetupId: "s1",
} as unknown as Bike;

const ride: Ride = {
  id: "r1",
  bikeId: "b1",
  sportType: "enduro",
  startTime: new Date().toISOString(),
  distanceM: 3200,
  elevationGainM: 400,
  durationSec: 2400,
  summaryMetrics: {
    gForcePeak: 4,
    gForceRms: 1.2,
    leanAngleMax: 28,
    impactCount: 40,
    hardImpactCount: 30,
    flowScore: 72,
    fni: 55,
    bottomOutCount: 0,
  },
};

const cal: BikeCalibration = {
  bikeId: "b1",
  mountMode: "HANDLEBAR",
  mountConfirmed: true,
  quaternion: {
    gDev: [0, 0, 1],
    gBike: [0, 0, -1],
    yawFromGnssPending: true,
  },
  suspension: {
    zeta: 0.21,
    fdHz: 2.4,
    fnHz: 2.5,
    cv: 0.08,
    accepted: true,
    scopeNote: "test",
  },
  sagFrontMm: 40,
  sagRearMm: null,
  travelFrontMm: 160,
  travelRearMm: null,
  calibratedAt: new Date().toISOString(),
};

const feedback: RideFeedback = {
  rideId: "r1",
  overallFeel: 3,
  frontFeel: "too_firm",
  smallBump: "harsh",
  skipped: false,
  createdAt: new Date().toISOString(),
};

const analysis = buildPostRideAnalysis({
  bike,
  ride,
  feedback,
  calibration: cal,
});

assert(analysis.facts.length >= 2, "facts");
assert(analysis.observations.length <= 3, "max 3 observations");
assert(analysis.recommendation != null, "has recommendation");
assert(analysis.recommendation!.ruleId === "SR-REB-01", "SR-REB-01");
// G-2 offen → observationOnly
assert(analysis.recommendation!.observationOnly === true, "gated observation");

console.log("setupRecommendation tests OK");
