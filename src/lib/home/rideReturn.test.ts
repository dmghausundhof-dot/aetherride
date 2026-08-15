import { formatMovingTime, residentMeta, rideReturnForBike } from "./rideReturn";
import type { Ride } from "@/types";

function ride(partial: Partial<Ride> & { id: string; bikeId: string }): Ride {
  return {
    sportType: "gravel",
    startTime: "2026-08-12T10:00:00.000Z",
    distanceM: 18200,
    elevationGainM: 120,
    durationSec: 4320,
    summaryMetrics: {
      gForcePeak: 0,
      gForceRms: 0,
      leanAngleMax: 0,
      impactCount: 0,
      flowScore: 0,
    },
    ...partial,
  };
}

const now = new Date("2026-08-13T12:00:00.000Z");

const never = rideReturnForBike({
  bikeId: "luna",
  rides: [],
  now,
});
if (never.kind !== "neverOut") {
  throw new Error(`empty rides should be neverOut, got ${never.kind}`);
}

const just = rideReturnForBike({
  bikeId: "luna",
  rides: [
    ride({
      id: "r1",
      bikeId: "luna",
      endTime: "2026-08-13T10:00:00.000Z",
    }),
  ],
  now,
});
if (just.kind !== "justBack") {
  throw new Error(`recent ride should be justBack, got ${just.kind}`);
}

const atHof = rideReturnForBike({
  bikeId: "luna",
  rides: [
    ride({
      id: "r2",
      bikeId: "luna",
      endTime: "2026-08-10T10:00:00.000Z",
    }),
  ],
  now,
});
if (atHof.kind !== "atHof" || atHof.daysSince !== 3) {
  throw new Error(`expected atHof 3 days, got ${JSON.stringify(atHof)}`);
}

const otherBike = rideReturnForBike({
  bikeId: "luna",
  rides: [
    ride({
      id: "r3",
      bikeId: "kora",
      endTime: "2026-08-13T10:00:00.000Z",
    }),
  ],
  now,
});
if (otherBike.kind !== "neverOut") {
  throw new Error("rides on another bike must not fill this stand");
}

if (formatMovingTime(4320) !== "1:12") {
  throw new Error(`formatMovingTime 4320 = ${formatMovingTime(4320)}`);
}

const meta = residentMeta({
  sport: "Trail",
  ret: { kind: "neverOut" },
});
if (!meta.includes("noch nicht draußen")) {
  throw new Error(`meta ${meta}`);
}

console.log("rideReturn.test.ts ok");
