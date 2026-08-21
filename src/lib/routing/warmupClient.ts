import type { RoutingProfile } from "@/lib/routing/profiles";
import {
  graphhopperWarmupCell,
  shouldWarmLiveRouting,
} from "@/lib/routing/graphhopperWarmup";

let lastCell = "";

/** Fire-and-forget — never blocks the rider's A–B request. */
export function warmupLiveRouting(
  profile: RoutingProfile,
  near: [number, number],
  opts?: { hasStart?: boolean; hasEnd?: boolean }
): void {
  if (opts && !shouldWarmLiveRouting({
    hasStart: Boolean(opts.hasStart),
    hasEnd: Boolean(opts.hasEnd),
  })) {
    return;
  }
  const [lng, lat] = near;
  if (
    !Number.isFinite(lng) ||
    !Number.isFinite(lat) ||
    Math.abs(lat) > 90 ||
    Math.abs(lng) > 180
  ) {
    return;
  }
  const cell = graphhopperWarmupCell(profile, near);
  if (cell === lastCell) return;
  lastCell = cell;
  const qs = new URLSearchParams({
    profile,
    near: `${lng},${lat}`,
  });
  void fetch(`/api/route/warmup?${qs}`, {
    method: "GET",
    cache: "no-store",
    keepalive: true,
  }).catch(() => {
    /* isolate / GH miss is fine — the real A–B still runs */
  });
}
