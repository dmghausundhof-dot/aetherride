/**
 * Offline routing packs vs named envelopes — counts from catalog + registry.
 * Never hardcode “83 packs” on the website.
 *
 * CDN fetch only — do not import offlinePacks.ts (Node fs). Local dist/
 * scanning stays on /api/offline/packs.
 */

import { DACH_ENVELOPE_REGIONS } from "@/lib/coverage/dachRegions";
import {
  fetchPublishedCatalog,
  summarizeOfflinePacks,
} from "@/lib/routing/offlinePackCatalog";

export type OfflineCoverageStats = {
  catalogOk: boolean;
  readyPacks: number | null;
  stubPacks: number | null;
  envelopeRegions: number;
};

export { summarizeOfflinePacks };

/** CDN catalog first; envelopes always from the DACH registry (named holes). */
export async function loadOfflineCoverageStats(): Promise<OfflineCoverageStats> {
  const envelopeRegions = DACH_ENVELOPE_REGIONS.length;
  try {
    const published = await fetchPublishedCatalog();
    if (published?.length) {
      const summary = summarizeOfflinePacks(published);
      return {
        catalogOk: true,
        readyPacks: summary.ready,
        stubPacks: summary.stub,
        envelopeRegions,
      };
    }
    return {
      catalogOk: false,
      readyPacks: null,
      stubPacks: null,
      envelopeRegions,
    };
  } catch {
    return {
      catalogOk: false,
      readyPacks: null,
      stubPacks: null,
      envelopeRegions,
    };
  }
}
