import { buildPostRideAnalysis } from "./setupRecommendation";
import type { Bike, Ride, RideFeedback } from "@/types";
import type { BikeCalibration } from "@/lib/sensor/calibration";
import { G2_SUSPENSION_GATE_PASSED } from "@/lib/sensor/fni";

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
        {
          bikeComponentId: "c1",
          slot: "fork",
          adjusterKey: "sag_pct",
          valueNum: 22,
          unit: "%",
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
  sagFrontMm: 35, // ~22 % of 160 — im Band
  sagRearMm: null,
  travelFrontMm: 160,
  travelRearMm: null,
  calibratedAt: new Date().toISOString(),
};

const feedback: RideFeedback = {
  rideId: "r1",
  overallFeel: 3,
  frontFeel: "rupft",
  smallBump: "rupft",
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
assert(analysis.recommendation!.ruleId === "SR-REB-01", "SR-REB-01 when SAG ok");
assert(analysis.recommendation!.observationOnly === true, "G-2 gated");
assert(!!analysis.recommendation!.workshopLine, "workshop line");
assert(!!analysis.recommendation!.coachLine, "coach line");

// SAG-first: hoher SAG + Bottom-out → Observation C, nicht Druck-Apply
const softCal: BikeCalibration = {
  ...cal,
  sagFrontMm: 48, // 30 % > Enduro-Band
};
const bottomRide: Ride = {
  ...ride,
  summaryMetrics: {
    ...ride.summaryMetrics,
    bottomOutCount: 4,
  },
};
const softFb: RideFeedback = {
  ...feedback,
  frontFeel: "packt_nicht",
  smallBump: "ok",
};
const sagFirst = buildPostRideAnalysis({
  bike,
  ride: bottomRide,
  feedback: softFb,
  calibration: softCal,
});
assert(sagFirst.recommendation?.ruleId === "SR-SAG-02", "SAG/bottom before rebound");
assert(sagFirst.recommendation?.observationOnly === true, "bottom-out observation only");
assert(
  sagFirst.recommendation?.apply["fork.air_pressure_psi"] != null,
  "manual psi suggestion for garage"
);
assert(
  G2_SUSPENSION_GATE_PASSED === false,
  "gate still open — no fake pass"
);

console.log("setupRecommendation tests OK", {
  reb: analysis.recommendation?.ruleId,
  sag: sagFirst.recommendation?.ruleId,
});
