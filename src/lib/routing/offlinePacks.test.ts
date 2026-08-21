/**
 * Offline-Pack Katalog: Dist vor Public, Stubs nicht downloadable.
 * npx tsx src/lib/routing/offlinePacks.test.ts
 */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  applyPackCdn,
  catalogPackBytes,
  catalogStatus,
  manifestHasFileEntries,
  mergeCatalogPreferReady,
  mergeCatalogUnion,
  parsePublishedCatalog,
  pickPreferredManifest,
  publicOfflinePackObjectUrl,
  sortCatalogPacks,
  summarizeOfflinePacks,
  type OfflineCatalogPack,
  type OfflinePackManifest,
} from "./offlinePackCatalog";

process.env.NEXT_PUBLIC_SUPABASE_URL ||=
  "https://krmgatsugplouzrhhozn.supabase.co";

const stub: OfflinePackManifest = {
  id: "frankfurt-rhein-main",
  name: "Frankfurt Rhein-Main",
  files: {},
  shipped: { note: "Catalog stub" },
};

const stalePublic: OfflinePackManifest = {
  id: "rhein-neckar",
  name: "Rhein-Neckar (stale public)",
  files: {
    "rhein-neckar.tar.gz": {
      bytes: 2_671_915,
      sha256: "4315b03398a7a91960de4448dc0fca7d26987e2216db5f22fc046b98639d0e42",
    },
  },
};

const distReady: OfflinePackManifest = {
  id: "rhein-neckar",
  name: "Rhein-Neckar / Heidelberg",
  files: {
    "rhein-neckar.tar.gz": {
      bytes: 10_518_381,
      sha256: "a33b1e555670395389f0217e3d0659b5ae34f70bd91a13cae1c99e3675010337",
    },
    "offline_graph.json": {
      bytes: 18_744_201,
      sha256: "bfff4261a9af2e40c4416d744cea886c7be7223005849646fde06f7be01178f2",
    },
  },
};

assert.equal(manifestHasFileEntries(stub), false);
assert.equal(manifestHasFileEntries(distReady), true);
assert.equal(catalogStatus(stub, false), "stub");
assert.equal(
  catalogStatus(
    {
      ...stub,
      cdn: {
        baseUrl:
          "https://krmgatsugplouzrhhozn.supabase.co/storage/v1/object/public/offline-packs/frankfurt-rhein-main",
      },
    },
    false
  ),
  "ready"
);
assert.equal(catalogStatus(distReady, false), "stub");
assert.equal(catalogStatus(distReady, true), "ready");
assert.equal(
  catalogStatus(
    {
      ...distReady,
      cdn: {
        baseUrl:
          "https://example.supabase.co/storage/v1/object/public/offline-packs/rhein-neckar",
      },
    },
    false
  ),
  "ready"
);
assert.equal(
  applyPackCdn("rhein-neckar", distReady).cdn?.baseUrl?.includes(
    "rhein-neckar"
  ),
  true
);
assert.equal(catalogPackBytes(distReady), 10_518_381);

const picked = pickPreferredManifest({
  dist: distReady,
  pub: stalePublic,
  stub,
});
assert.equal(picked?.name, "Rhein-Neckar / Heidelberg");
assert.equal(
  picked?.files?.["rhein-neckar.tar.gz"]?.sha256,
  distReady.files!["rhein-neckar.tar.gz"]!.sha256
);

const pubOnly = pickPreferredManifest({
  dist: null,
  pub: stalePublic,
  stub,
});
assert.equal(pubOnly?.name, "Rhein-Neckar (stale public)");

const stubOnly = pickPreferredManifest({
  dist: null,
  pub: null,
  stub,
});
assert.equal(stubOnly?.id, "frankfurt-rhein-main");

const rows: OfflineCatalogPack[] = [
  {
    id: "berlin",
    name: "Berlin",
    bbox: null,
    builtAt: null,
    engines: null,
    hasManifest: true,
    downloadable: false,
    status: "stub",
    bytes: null,
    graphBytes: null,
    cdn: null,
  },
  {
    id: "rhein-neckar",
    name: "Rhein-Neckar / Heidelberg",
    bbox: null,
    builtAt: null,
    engines: null,
    hasManifest: true,
    downloadable: true,
    status: "ready",
    bytes: 10_518_381,
    graphBytes: null,
    cdn: null,
  },
];
const sorted = sortCatalogPacks(rows);
assert.equal(sorted[0]!.id, "rhein-neckar");
assert.equal(sorted[1]!.id, "berlin");

assert.equal(manifestHasFileEntries(stub), false);
assert.equal(catalogStatus(stub, false), "stub");

const published = parsePublishedCatalog({
  packs: [
    {
      id: "aachen",
      name: "Aachen / Dreiländereck",
      downloadable: true,
      status: "ready",
      bytes: 2595914,
      bbox: [6, 50.72, 6.2, 50.85],
    },
  ],
});
assert.equal(published.length, 1);
assert.equal(published[0]!.downloadable, true);
const merged = mergeCatalogPreferReady(
  [
    {
      id: "aachen",
      name: "Aachen / Dreiländereck",
      bbox: [6, 50.72, 6.2, 50.85],
      builtAt: null,
      engines: null,
      hasManifest: true,
      downloadable: false,
      status: "stub",
      bytes: null,
      graphBytes: null,
      cdn: null,
    },
  ],
  published
);
assert.equal(merged[0]!.downloadable, true);
assert.equal(merged[0]!.bytes, 2595914);

{
  const unioned = mergeCatalogUnion(
    [
      {
        id: "berlin",
        name: "Berlin",
        bbox: null,
        builtAt: null,
        engines: null,
        hasManifest: true,
        downloadable: true,
        status: "ready",
        bytes: 2_666_289,
        graphBytes: 19_765_590,
        cdn: null,
      },
    ],
    [
      {
        id: "de-saarland",
        name: "Saarland",
        bbox: null,
        builtAt: null,
        engines: null,
        hasManifest: true,
        downloadable: true,
        status: "ready",
        bytes: 54_209_122,
        graphBytes: null,
        cdn: null,
      },
    ]
  );
  assert.equal(unioned.length, 2);
  assert.ok(unioned.some((p) => p.id === "berlin" && p.downloadable));
  assert.ok(unioned.some((p) => p.id === "de-saarland"));
}
assert.ok(
  applyPackCdn("aachen", stub).cdn?.baseUrl?.includes(
    "/storage/v1/object/public/offline-packs/aachen"
  )
);
assert.ok(
  publicOfflinePackObjectUrl("vosges", "bike-overlay.geojson")?.includes(
    "/offline-packs/vosges/bike-overlay.geojson"
  )
);
// Footgun: invented Storage URLs look "ready" to catalogStatus. toCatalogRow
// must evaluate status on the raw stub before applyPackCdn.
assert.equal(catalogStatus(applyPackCdn("aachen", stub), false), "ready");
assert.equal(catalogStatus(stub, false), "stub");

{
  const summary = summarizeOfflinePacks([
    {
      id: "aachen",
      name: "Aachen",
      bbox: null,
      builtAt: null,
      engines: null,
      hasManifest: true,
      downloadable: true,
      status: "ready",
      bytes: 100,
      graphBytes: null,
      cdn: null,
    },
    {
      id: "de-bayern",
      name: "Bayern",
      bbox: null,
      builtAt: null,
      engines: null,
      hasManifest: true,
      downloadable: false,
      status: "stub",
      bytes: null,
      graphBytes: null,
      cdn: null,
    },
  ]);
  assert.equal(summary.ready, 1);
  assert.equal(summary.stub, 1);
  assert.equal(summary.total, 2);
}

try {
  const distRaw = JSON.parse(
    readFileSync("data/routing/dist/rhein-neckar/manifest.json", "utf8")
  ) as OfflinePackManifest;
  assert.equal(manifestHasFileEntries(distRaw), true);
  assert.ok((catalogPackBytes(distRaw) ?? 0) > 1_000_000);
} catch {
  /* dist/ is gitignored — skip on CI without local packs */
}

console.log("offlinePacks.test.ts OK");
