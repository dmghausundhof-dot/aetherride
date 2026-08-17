/**
 * npx tsx src/lib/routing/valhallaRegions.test.ts
 */
import assert from "node:assert/strict";
import {
  publicValhallaTilesObjectUrl,
  publicValhallaTilesUrlForPoint,
} from "./offlinePackCatalog";
import {
  valhallaRegionForPoint,
  valhallaTilesCdnPath,
} from "./valhallaRegions";

process.env.NEXT_PUBLIC_SUPABASE_URL ||=
  "https://krmgatsugplouzrhhozn.supabase.co";

assert.equal(valhallaRegionForPoint(7.85, 47.99)?.id, "schwarzwald-nord");
assert.equal(valhallaRegionForPoint(4.9, 52.37)?.id, "amsterdam");
assert.equal(valhallaRegionForPoint(5.5, 52.5)?.id, "nl-netherlands");
assert.equal(valhallaRegionForPoint(4.35, 50.85)?.id, "be-belgium");
assert.equal(valhallaRegionForPoint(11.5, 48.1)?.id, "de-bayern");
assert.equal(valhallaRegionForPoint(2.35, 48.86)?.id, "fr-ile-de-france");
assert.equal(valhallaRegionForPoint(12.5, 41.9)?.id, "it-centro");
assert.equal(valhallaRegionForPoint(13.405, 52.52)?.id, "de-brandenburg");
assert.equal(valhallaRegionForPoint(-30, 0), null);
assert.equal(
  valhallaTilesCdnPath("nl-netherlands"),
  "nl-netherlands/valhalla_tiles.tar"
);

// Call-site helpers used by offline pack API (CDN redirect for tiles).
assert.ok(
  publicValhallaTilesObjectUrl("nl-netherlands")?.endsWith(
    "/offline-packs/nl-netherlands/valhalla_tiles.tar"
  )
);
assert.ok(
  publicValhallaTilesUrlForPoint(5.5, 52.5)?.includes(
    "/nl-netherlands/valhalla_tiles.tar"
  )
);
assert.equal(publicValhallaTilesUrlForPoint(-30, 0), null);
assert.ok(
  publicValhallaTilesUrlForPoint(7.85, 47.99)?.includes(
    "/schwarzwald-nord/valhalla_tiles.tar"
  )
);

console.log("valhallaRegions.test.ts ok");
