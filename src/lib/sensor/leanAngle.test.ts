import { computeLeanAngle, G, LEAN_MIN_SPEED_KMH } from "./leanAngle";
import { computeFlowScore } from "./flowScore";
import { estimateZetaFromPeaks, combineBounceTrials } from "./calibration";
import { matchReferenceSegment } from "@/lib/setup/bracketingMatch";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

// θ = atan(v·ω/g) — 10 m/s, ω = 0.5 rad/s → atan(5/g) ≈ 27°
{
  const v = 10;
  const w = 0.5;
  const expected = (Math.atan((v * w) / G) * 180) / Math.PI;
  const r = computeLeanAngle({ speedMs: v, yawRateRadS: w });
  assert(r.available, "lean available");
  assert(Math.abs((r.leanDeg ?? 0) - expected) < 0.2, `lean ≈ ${expected}`);
}

{
  const r = computeLeanAngle({
    speedMs: (LEAN_MIN_SPEED_KMH - 1) / 3.6,
    yawRateRadS: 0.4,
  });
  assert(!r.available, "lean unavailable under 8 km/h");
}

{
  const flow = computeFlowScore({
    durationSec: 200,
    terrainClass: "s2",
    speedsMs: Array.from({ length: 40 }, (_, i) => 5 + Math.sin(i) * 0.2),
    jerkRms: 12,
    brakesPerKm: 3,
    hardBrakeShare: 0.2,
    yawVariance: 0.2,
  });
  assert(flow.available && flow.parts != null, "flow parts visible");
  assert(flow.total != null && flow.total >= 0 && flow.total <= 100, "flow 0-100");
}

{
  const flow = computeFlowScore({
    durationSec: 200,
    terrainClass: "unknown",
    speedsMs: [5, 5, 5],
    jerkRms: 10,
    brakesPerKm: 1,
    hardBrakeShare: 0,
    yawVariance: 0.1,
  });
  assert(!flow.available, "no flow without terrain class");
}

{
  // Stärkere Dämpfung → höheres ζ (log. Dekrement)
  const t = estimateZetaFromPeaks([1, 0.45, 0.2, 0.09], 2.4);
  assert(t.zeta > 0.05 && t.zeta < 0.8, `zeta plausible got ${t.zeta}`);
  const c = combineBounceTrials([t, t, t]);
  assert(c.accepted, "three identical trials accepted");
}

{
  const ref = Array.from({ length: 20 }, (_, i) => ({
    lat: 47.45 + i * 0.0001,
    lng: 12.15 + i * 0.0001,
  }));
  const cand = ref.map((p) => ({
    lat: p.lat + 0.00001,
    lng: p.lng + 0.00001,
  }));
  const m = matchReferenceSegment(ref, cand);
  assert(m.matched, "geometry match");
}

console.log("leanAngle/flow/calibration/bracketingMatch tests OK");
