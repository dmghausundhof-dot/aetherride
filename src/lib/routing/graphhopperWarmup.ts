/**
 * Dummy A–B used to compile GraphHopper `custom_model` before the rider
 * pins destination. Does not change engine policy — only hides cold start.
 */

export const GH_WARMUP_OFFSET_M = 380;

/** ~5–11 km cells so pan/GPS jitter does not burn extra GH credits. */
export function graphhopperWarmupCell(
  profile: string,
  near: [number, number]
): string {
  return `${profile}:${near[0].toFixed(1)}:${near[1].toFixed(1)}`;
}

/** Point ~380 m east of [near] — stays on the same GH tile in DACH. */
export function graphhopperWarmupTo(near: [number, number]): [number, number] {
  const [lng, lat] = near;
  const metersPerDegLng = 111320 * Math.cos((lat * Math.PI) / 180);
  const dLng =
    Number.isFinite(metersPerDegLng) && Math.abs(metersPerDegLng) > 40
      ? GH_WARMUP_OFFSET_M / metersPerDegLng
      : 0.004;
  return [lng + dLng, lat];
}

/** Real A–B is the warmup — a second dummy request would steal the isolate. */
export function shouldWarmLiveRouting(opts: {
  hasStart: boolean;
  hasEnd: boolean;
}): boolean {
  return !(opts.hasStart && opts.hasEnd);
}
