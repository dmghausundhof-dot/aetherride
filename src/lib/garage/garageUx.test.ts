/**
 * Garage-UX Helpers — Ausführen: npx tsx src/lib/garage/garageUx.test.ts
 */
import { readFileSync } from "node:fs";
import { estimateAirPsi } from "../setup/sagGuide";
import { setupConditionLabel } from "../setup/conditionLabels";
import { weeklyRideKm, verdictSummaryDe } from "./readiness";
import { resolveGaragePrimaryAction } from "./primaryCta";
import { planDieBox, listedWorkshopParts, bikeHealthLine, ghostSlotsFor } from "./dieBox";
import { slotLabel } from "../catalog/slots";
import { snapshotOwnSetup, setupToApplyOnFamilySwitch } from "./family";
import { standPhotoIsRemote, standPhotoNeedsCrop, standPhotoSourceRect } from "./standPhoto";
import { schemaHiddenOpenCount, schemaHotspotQuiet, schemaInviteSlots } from "./schema/invites";
import type { Bike } from "../../types/garage";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const e = estimateAirPsi({
  riderWeightKg: 78,
  gearWeightKg: 4,
  category: "mtb_am",
  end: "fork",
  travelMm: 150,
});
assert(e.psiTarget > 50 && e.psiTarget < 140, `psiTarget=${e.psiTarget}`);
assert(e.sag.target >= 20, "sag target");

assert(setupConditionLabel("bikepark") === "Bikepark", "label bikepark");
assert(setupConditionLabel("wet") === "Nass", "label wet");

const now = new Date().toISOString();
const old = new Date(Date.now() - 10 * 86400000).toISOString();
assert(
  weeklyRideKm(
    [
      { startTime: now, distanceM: 20000, bikeId: "a" },
      { startTime: old, distanceM: 50000, bikeId: "a" },
    ],
    "a"
  ) === 20,
  "weekly km"
);

assert(verdictSummaryDe("COMPATIBLE") === "Kompatibel", "verdict");

assert(
  resolveGaragePrimaryAction({ isActive: true, dueCount: 1, partsCount: 0 }) ===
    "viewMaintenance",
  "cta maintenance"
);
assert(
  resolveGaragePrimaryAction({ isActive: false, dueCount: 0, partsCount: 0 }) ===
    "addPart",
  "cta add part"
);
assert(
  resolveGaragePrimaryAction({ isActive: false, dueCount: 0, partsCount: 2 }) ===
    "setActive",
  "cta set active"
);
assert(
  resolveGaragePrimaryAction({ isActive: true, dueCount: 0, partsCount: 2 }) ===
    "openSetup",
  "legacy mehr-tab cta"
);

const cityBike: Bike = {
  id: "c1",
  name: "City",
  category: "urban",
  type: "road",
  isActive: true,
  isEbike: false,
  createdAt: now,
  updatedAt: now,
  components: [],
  setups: [],
  totalOdometerKm: 0,
  totalHours: 0,
};
const city = planDieBox({ bike: cityBike });
assert(!city.sentence.toLowerCase().includes("sag"), "city no sag");
assert(city.addableSlots.includes("light"), "city can add light");
assert(!city.addableSlots.includes("fork"), "city no ghost fork");
assert(city.today.some((t) => t.id === "lightsMissing"), "city lights today");
assert(!city.today.some((t) => t.id === "lockMissing"), "city lock not heute nag");
assert(!city.today.some((t) => t.id === "rackMissing"), "city rack not heute nag");
assert(!city.chips.some((c) => !c.known), "city chips are known facts");
assert(!city.sentence.toLowerCase().includes("nicht"), "city sentence not a deficit");

const cargoBike: Bike = { ...cityBike, id: "cargo1", name: "Lasten", category: "cargo" };
const cargo = planDieBox({ bike: cargoBike });
assert(cargo.kind === "urban", "cargo lives in city box");
assert(!cargo.sentence.toLowerCase().includes("sag"), "cargo no sag");
assert(cargo.addableSlots.includes("light"), "cargo can add light");

const gravelBike: Bike = {
  ...cityBike,
  id: "g1",
  name: "Kora",
  category: "gravel",
};
const gravel = planDieBox({ bike: gravelBike });
assert(!gravel.today.some((t) => t.id === "bagsMissing"), "gravel bags not heute nag");
assert(!gravel.today.some((t) => t.id === "sagUnknown"), "gravel no sag heute");
assert(gravel.addableSlots.includes("bags"), "gravel can add bags");

const gravelForkBike: Bike = {
  ...gravelBike,
  id: "g-fork",
  components: [
    {
      id: "fork1",
      bikeId: "g-fork",
      slot: "fork",
      installedAt: now,
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
};
const gravelFork = planDieBox({ bike: gravelForkBike });
assert(
  gravelFork.today.some((t) => t.id === "sagUnknown" && t.slot === "fork"),
  "gravel fork asks sag on the fork only"
);

const trailHt: Bike = {
  ...cityBike,
  id: "ht1",
  name: "Hard",
  category: "mtb_trail",
  type: "all_mountain",
  travelFrontMm: 130,
};
const htPlan = planDieBox({ bike: trailHt });
assert(
  htPlan.today.some((t) => t.id === "sagUnknown" && t.slot === "fork"),
  "hardtail sag is fork only"
);

const dhBike: Bike = {
  ...cityBike,
  id: "d1",
  name: "Spicy",
  category: "dh",
  type: "enduro",
  travelFrontMm: 200,
  travelRearMm: 200,
};
const dh = planDieBox({ bike: dhBike });
assert(!dh.chips.some((c) => c.label === "Licht"), "dh no lights chip");
assert(!dh.addableSlots.includes("light"), "dh no light slot");
assert(dh.primary?.cta !== "Zum Setup", "box primary not zum setup");

const emtb: Bike = {
  ...cityBike,
  id: "e1",
  name: "Cargo",
  category: "etrekking",
  isEbike: true,
};
const eplan = planDieBox({ bike: emtb, cscPaired: false });
assert(!eplan.today.some((t) => t.id === "pairCsc"), "csc not today hero");
assert(!eplan.chips.some((c) => c.label === "CSC"), "unpaired csc not a chip");

const jam2Parts: Bike["components"] = [
  {
    id: "p-tire",
    bikeId: "j1",
    slot: "tire_front",
    componentModelId: "cm-tire",
    installedAt: now,
    odometerKmAtInstall: 0,
    hoursAtInstall: 0,
    attributes: [],
    currentSettings: {},
  },
  {
    id: "p-headset",
    bikeId: "j1",
    slot: "headset",
    componentModelId: "cm-headset",
    installedAt: now,
    odometerKmAtInstall: 0,
    hoursAtInstall: 0,
    attributes: [],
    currentSettings: {},
  },
  {
    id: "p-lock",
    bikeId: "j1",
    slot: "lock",
    freeText: "Abus",
    installedAt: now,
    odometerKmAtInstall: 0,
    hoursAtInstall: 0,
    attributes: [],
    currentSettings: {},
  },
];
const jam2: Bike = {
  ...cityBike,
  id: "j1",
  name: "JAM² 6.9",
  category: "emtb",
  type: "e_mtb",
  isEbike: true,
  catalogBikeId: "cat-focus-jam2-2024",
  travelFrontMm: 150,
  travelRearMm: 150,
  wheelSizeFront: "29",
  wheelSizeRear: "29",
  components: jam2Parts,
};
const jamPlan = planDieBox({ bike: jam2 });
assert(jamPlan.onBike.some((c) => c.slot === "tire_front"), "jam2 core tire");
assert(!jamPlan.onBike.some((c) => c.slot === "headset"), "jam2 no oem dump");
assert(
  jamPlan.onBike.map((c) => c.id).join() ===
    listedWorkshopParts(jam2Parts, jamPlan.addableSlots).map((c) => c.id).join(),
  "Teile-Tab listing is Am Rad, not OEM dump"
);
assert(jamPlan.onBike.some((c) => c.slot === "lock"), "jam2 explicit lock");
assert(jamPlan.sentence.includes("150/150"), "jam2 travel in sentence");
assert(jamPlan.sentence.includes("E-Antrieb"), "jam2 assist named honestly");
assert(!jamPlan.chips.some((c) => c.label === "Bosch CX"), "no invented motor sku");
assert(!jamPlan.chips.some((c) => c.label === "800 Wh"), "no invented battery");
assert(jamPlan.addableSlots.includes("headset"), "headset addable for front-end fit");
assert(jamPlan.addableSlots.includes("front_hub"), "front hub addable");

const mtbDrivetrain: Bike = {
  ...cityBike,
  id: "k1",
  name: "Konflikt",
  category: "mtb_trail",
  type: "all_mountain",
  travelFrontMm: 140,
  travelRearMm: 140,
  components: [
    {
      id: "k-cass",
      bikeId: "k1",
      slot: "cassette",
      manufacturer: "SRAM",
      model: "XO Eagle",
      installedAt: now,
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
    {
      id: "k-hs",
      bikeId: "k1",
      slot: "headset",
      componentModelId: "cm-headset",
      manufacturer: "Cane Creek",
      model: "Hellbender OEM",
      installedAt: now,
      odometerKmAtInstall: 0,
      hoursAtInstall: 0,
      attributes: [],
      currentSettings: {},
    },
  ],
};
const mtbPlan = planDieBox({ bike: mtbDrivetrain });
assert(mtbPlan.onBike.some((c) => c.slot === "cassette"), "mtb rider cassette");
assert(!mtbPlan.onBike.some((c) => c.slot === "headset"), "mtb no oem headset");

const hike = planDieBox({
  bike: {
    ...cityBike,
    id: "h1",
    name: "Tour-Kit",
    category: "hiking",
    type: "hiking",
  },
});
assert(
  hike.addableSlots.every((s) => s.startsWith("hiking_")),
  "hiking only kit slots"
);
assert(!hike.addableSlots.includes("fork"), "hiking no fork");

assert(slotLabel("chain") === "Kette", "slotLabel Kette");
assert(slotLabel("fork") === "Gabel", "slotLabel Gabel");
assert(slotLabel("chain", "en") === "Chain", "slotLabel chain en");
assert(slotLabel("fork", "fr") === "Fourche", "slotLabel fork fr");
assert(
  slotLabel("chain") !== slotLabel("chain").toUpperCase(),
  "slotLabel stays sentence case"
);

const partsDoor = readFileSync("src/components/garage/GaragePartsCta.tsx", "utf8");
assert(partsDoor.includes("<Link"), "parts door is a full-row link");
assert(
  partsDoor.includes('data-testid={lookupOnly ? "garage-parts-lookup" : "garage-parts-cta"}'),
  "parts door keys match native lookup vs row",
);
assert(partsDoor.includes("shopPartsForBike"), "list door copy");
assert(partsDoor.includes("shopLookupInShop"), "lookup door copy");
assert(!partsDoor.includes("<Hero"), "no shop hero");
assert(!partsDoor.includes("€"), "no euro on the door");
assert(partsDoor.includes("RadGlyph"), "stand door mark");
assert(!partsDoor.includes("lucide-react"), "parts door stays in stand marks");

assert(
  readFileSync("src/components/garage/RadEmpty.tsx", "utf8").includes(
    "RadEmptyStage"
  ),
  "rad empty uses stand stage"
);
const emptyStage = readFileSync(
  "src/components/garage/RadEmptyStage.tsx",
  "utf8"
);
assert(
  emptyStage.includes("strokeDasharray") || emptyStage.includes("RAD_EMPTY_STAND"),
  "empty stage is dashed SVG or shipped stand art"
);
assert(
  !emptyStage.includes("empty-stand-mark"),
  "broken prod asset empty-stand-mark.svg is not referenced"
);
assert(
  readFileSync("src/components/hof/HofEmpty.tsx", "utf8").includes(
    "RadEmptyStage"
  ),
  "hof empty uses stand stage"
);
assert(
  readFileSync("src/components/home/HofStand.tsx", "utf8").includes(
    "RadEmptyStage"
  ),
  "hof stand empty uses stand stage"
);
assert(
  readFileSync("src/components/shop/ShopImageFallback.tsx", "utf8").includes(
    "RAD_STAND_GROUND"
  ),
  "shop empty sits on stand ground"
);
assert(
  readFileSync("src/components/garage/AddBikeWizard.tsx", "utf8").includes(
    'heightClass="h-28"'
  ),
  "add wizard shows type on the stand"
);

const shopDoor = readFileSync("src/components/shop/ShopGateway.tsx", "utf8");
assert(shopDoor.includes("RadNavMark"), "shop bike door uses stand mark");
assert(
  !readFileSync("src/components/shop/ProductVisual.tsx", "utf8").includes(
    "lucide-react"
  ),
  "shop fallbacks stay in stand marks"
);
assert(shopDoor.includes("ShopImageFallback"), "shop merch empty uses stand mark");
assert(!shopDoor.includes("icon={Bike}"), "shop door no lucide Bike");
assert(!shopDoor.includes("typeof Bike"), "shop door no lucide Bike type");

const bikeChip = readFileSync("src/components/BikeChip.tsx", "utf8");
assert(bikeChip.includes("useHofCopy"), "empty chip uses hof copy");
assert(bikeChip.includes("parkBike"), "empty chip CTA is parkBike");
assert(!bikeChip.includes("Rad abstellen"), "empty chip no abstellen");

for (const path of [
  "src/components/shop/FeaturedBikeCard.tsx",
  "src/components/shop/PartsProductCard.tsx",
  "src/components/shop/ShopCatalogPreview.tsx",
  "src/app/shop/p/[handle]/page.tsx",
]) {
  assert(
    readFileSync(path, "utf8").includes("ShopImageFallback"),
    `${path} empty photo uses stand mark`
  );
}

const garagePage = readFileSync("src/app/garage/page.tsx", "utf8");
assert(garagePage.includes("dueSlot"), "maintenance lookup carries due slot");
assert(
  garagePage.includes("getMaintenanceSummary"),
  "due slot comes from intervals, not a guessed SKU",
);

const kickerFiles = [
  "src/components/garage/DieBoxSurface.tsx",
  "src/app/garage/page.tsx",
  "src/components/garage/GarageComponentsTab.tsx",
  "src/components/garage/RadSectionLabel.tsx",
];
for (const path of kickerFiles) {
  const src = readFileSync(path, "utf8");
  assert(
    !src.includes("uppercase tracking"),
    `${path} section kickers stay sentence case`
  );
}
const trackingFiles = [
  "src/components/garage/RadSectionLabel.tsx",
  "src/components/garage/AddBikeWizard.tsx",
  "src/components/garage/GarageComponentsTab.tsx",
];
for (const path of trackingFiles) {
  assert(
    readFileSync(path, "utf8").includes("tracking-wide"),
    `${path} tracking stays`
  );
}
const garagePageSrc = readFileSync("src/app/garage/page.tsx", "utf8");
assert(
  garagePageSrc.includes("RadSectionLabel"),
  "garage page uses the stand section mark"
);
assert(
  garagePageSrc.includes("workshopTabOverview"),
  "mehr-am-rad is the tabs, not a leftover Die-Box hint"
);
assert(
  !garagePageSrc.includes("workshopMoreHint"),
  "overview is the record, not a pointer under Die Box"
);
assert(
  !garagePageSrc.includes("Teile, Setup-Versionen"),
  "mehr-am-rad hint no hardcoded de"
);
assert(
  !garagePageSrc.includes("RAD_STAND_HEADER"),
  "decorative stand header gone from garage page"
);
assert(
  garagePageSrc.includes("BikeSchemaHotspots"),
  "teile tab mounts schema hotspots"
);
assert(
  !garagePageSrc.includes("OdometerImportPanel"),
  "km lives on the value strip, not in setup"
);
assert(
  readFileSync("src/components/garage/BikeStandEditor.tsx", "utf8").includes(
    "workshopStandStravaHint"
  ),
  "stand editor carries the strava hint that lived on the setup panel"
);
assert(
  garagePageSrc.includes("SagGuideForBike"),
  "setup tab mounts sag when travel exists"
);
assert(
  !garagePageSrc.includes("<details"),
  "garage tabs are not hidden in details"
);
assert(
  readFileSync("src/components/home/HofStand.tsx", "utf8").includes(
    "hof-bike-health"
  ),
  "hof shows bike health line"
);

const health = bikeHealthLine({
  readiness: "ready",
  odometerKm: 412.4,
  readyLabel: "Bereit",
  almostLabel: "Fast",
  unknownLabel: "Unklar",
});
assert(health === "Bereit · 412 km", "health line names readiness and km");

const ghosts = ghostSlotsFor({
  addable: ["tire_front", "chain", "headset", "front_hub", "lock"],
  installed: ["tire_front"],
  schemaSlots: ["chain"],
});
assert(ghosts.includes("lock"), "ghost lock");
assert(!ghosts.includes("headset"), "no headset ghost");
assert(!ghosts.includes("front_hub"), "no front hub ghost");
assert(!ghosts.includes("chain"), "schema slot not a ghost");

assert(
  garagePageSrc.includes("FamilyRiderStrip"),
  "garage mounts family rider chips"
);
assert(
  garagePageSrc.includes("overflow-x-auto"),
  "garage tabs scroll on a narrow screen"
);
assert(
  garagePageSrc.includes("FadeEdgeRow"),
  "tab row fades when chips overflow"
);
assert(
  garagePageSrc.includes("workshopTabOverview"),
  "web garage has an Übersicht tab"
);
assert(
  garagePageSrc.includes("BikeRideLog"),
  "overview holds the ride log, not a shop door"
);
assert(
  garagePageSrc.includes("compact"),
  "Die Box on the garage page is compact above the tabs"
);
assert(
  garagePageSrc.includes("workshopTitle"),
  "garage heading is Garage, not Workshop chrome"
);
assert(
  readFileSync("src/components/garage/GarageMaintenanceTab.tsx", "utf8").includes(
    "photoDataUrl"
  ),
  "web receipt stores a photo"
);
assert(
  readFileSync("src/components/garage/GarageMaintenanceTab.tsx", "utf8").includes(
    "workshopWearTitle"
  ),
  "maintenance headings use hof copy"
);
assert(
  readFileSync("src/components/garage/GarageMaintenanceTab.tsx", "utf8").includes(
    "presentWear"
  ),
  "wear cards are presented in chrome language"
);
assert(
  readFileSync("src/components/garage/GarageMaintenanceTab.tsx", "utf8").includes(
    "maintIntervalLabel"
  ),
  "interval titles map off the German engine key"
);
assert(
  readFileSync("src/components/garage/GarageComponentsTab.tsx", "utf8").includes(
    "garageTabCopy"
  ),
  "teile chrome uses tab copy"
);
assert(
  !readFileSync("src/components/garage/GarageComponentsTab.tsx", "utf8").includes(
    "Ersatzteil-Regal"
  ),
  "teile tab has no hardcoded German shelf heading"
);
assert(
  !readFileSync("src/components/garage/GarageMaintenanceTab.tsx", "utf8").includes(
    "Verschleißprognose"
  ),
  "maintenance tab has no hardcoded German heading"
);
assert(
  readFileSync("src/components/garage/BikeSchemaHotspots.tsx", "utf8").includes(
    "workshopSchemaLegendOk"
  ),
  "schema legend is in hof copy"
);

const teileTabSrc = readFileSync(
  "src/components/garage/GarageComponentsTab.tsx",
  "utf8"
);
assert(teileTabSrc.includes("workshopAddPart"), "teile cta uses hof copy");
assert(
  !teileTabSrc.includes("Teil selbst anlegen"),
  "teile cta matches native add part"
);
assert(teileTabSrc.includes("planDieBox"), "Teile-Tab lists via Die Box");
assert(teileTabSrc.includes(".onBike"), "Teile-Tab hides catalog OEM dump");
assert(
  readFileSync("src/components/garage/DieBoxSurface.tsx", "utf8").includes(
    "RadSectionLabel"
  ),
  "Die Box uses the stand section mark"
);

const ownSnap = snapshotOwnSetup({
  activeRiderId: null,
  currentSetupId: "mine",
});
assert(ownSnap === "mine", "leaving Ich snapshots the live setup");
assert(
  snapshotOwnSetup({ activeRiderId: "kid", currentSetupId: "kid-setup" }) ==
    null,
  "leaving a family rider does not overwrite own setup"
);

const restored = setupToApplyOnFamilySwitch({
  nextRiderId: null,
  rememberedOwnId: "mine",
  nextRiderSetupIds: [],
  existingSetupIds: ["mine", "kid-setup"],
  familyOwnedSetupIds: ["kid-setup"],
  currentSetupId: "kid-setup",
});
assert(restored === "mine", "Ich restores the remembered setup");

const kidApply = setupToApplyOnFamilySwitch({
  nextRiderId: "kid",
  rememberedOwnId: "mine",
  nextRiderSetupIds: ["kid-setup"],
  existingSetupIds: ["mine", "kid-setup"],
  familyOwnedSetupIds: ["kid-setup"],
  currentSetupId: "mine",
});
assert(kidApply === "kid-setup", "family chip applies the rider setup");

const tall = standPhotoSourceRect(1200, 1600);
assert(tall.sw === 1200, "tall photo keeps width");
assert(tall.sh < 1600, "tall photo crops height");
assert(tall.sy > 0, "tall photo crop sits toward the ground");
assert(standPhotoNeedsCrop(1200, 1600), "legacy tall photo needs crop");
assert(!standPhotoNeedsCrop(2000, 1000), "stand strip is not recropped");

const wide = standPhotoSourceRect(4000, 1000);
assert(wide.sh === 1000, "wide photo keeps height");
assert(wide.sw < 4000, "wide photo crops sides");
const wideLeft = standPhotoSourceRect(4000, 1000, 2, 0.72, 0);
assert(wideLeft.sx === 0, "wide photo pan can sit on the left");

assert(
  readFileSync("src/components/garage/RadStandFrame.tsx", "utf8").includes(
    "object-center"
  ),
  "stored stand photos fill the 2:1 frame without a second ground bias"
);

assert(
  readFileSync("src/components/garage/RadStandFrame.tsx", "utf8").includes(
    "aspect-[2/1]"
  ),
  "stand stage uses the schema 2:1 ratio"
);

assert(
  readFileSync("src/components/garage/FamilyRiderStrip.tsx", "utf8").includes(
    "workshopFamilyAdd"
  ),
  "stand can add a family rider"
);
assert(
  readFileSync("src/components/garage/FamilyRiderStrip.tsx", "utf8").includes(
    "workshopFamilyHintEmpty"
  ),
  "empty family has its own hint"
);
assert(
  !readFileSync("src/components/garage/FamilyRiderStrip.tsx", "utf8").includes(
    "riders.length === 0 ? ("
  ),
  "add chip stays after the first rider"
);
assert(
  garagePageSrc.includes("garage-bike-scroller"),
  "bike rail fades when chips overflow"
);
assert(
  readFileSync("src/components/garage/BikePhotoControl.tsx", "utf8").includes(
    "standPhotoNeedsCrop"
  ),
  "legacy data-url photos crop once"
);
assert(
  readFileSync("src/lib/sync/payload.ts", "utf8").includes("ownSetupByBikeId"),
  "own setup memory syncs"
);
assert(
  readFileSync("src/components/garage/BikeSchemaHotspots.tsx", "utf8").includes(
    "schemaInviteSlots"
  ),
  "schema chips use invite cap"
);

const invites = schemaInviteSlots({
  hotspotSlots: ["a", "b", "c", "d"],
  installed: [],
});
assert(invites.length === 2, "empty schema invites two slots");
assert(
  schemaHiddenOpenCount({ hotspotSlots: ["a", "b", "c", "d"], installed: [] }) ===
    2,
  "two open slots stay on the dots"
);
assert(
  schemaInviteSlots({
    hotspotSlots: ["stem", "frame", "saddle"],
    installed: [],
  }).join() === "stem,saddle",
  "frame is not an invitation"
);
assert(
  schemaHotspotQuiet("frame", "missing"),
  "missing frame is a quiet anatomy dot"
);
assert(
  !schemaHotspotQuiet("frame", "ok"),
  "installed frame is a normal status dot"
);
assert(
  !schemaHotspotQuiet("fork", "missing"),
  "open fork stays a missing invitation"
);
assert(
  readFileSync("src/components/garage/DieBoxSurface.tsx", "utf8").includes(
    "BikeValueStrip"
  ),
  "Die Box shows km/h/pressure/service under the photo"
);
assert(
  readFileSync("src/components/garage/BikePhotoControl.tsx", "utf8").includes(
    "stand-photo-place"
  ),
  "https photos offer the same stand pan"
);
assert(
  readFileSync("src/components/garage/StandPhotoCrop.tsx", "utf8").includes(
    "workshopPhotoRotate"
  ),
  "stand crop can turn a phone photo 90°"
);
assert(
  readFileSync("src/components/home/HofStand.tsx", "utf8").includes(
    'heightClass="aspect-[2/1]"'
  ),
  "hof parked bike uses the 2:1 stand"
);
assert(
  garagePageSrc.includes("bikes.length > 1"),
  "one bike skips the chip rail"
);
assert(
  readFileSync("src/components/garage/BikeSchemaHotspots.tsx", "utf8").includes(
    "bike.photoUrl"
  ),
  "schema dots sit on the stand photo"
);
assert(
  standPhotoIsRemote("https://cdn.example/bike.jpg"),
  "https photo is remote"
);
assert(!standPhotoIsRemote("data:image/jpeg;base64,xx"), "data url is local");
assert(
  readFileSync("src/components/garage/BikeSchemaHotspots.tsx", "utf8").includes(
    "RAD_STAND_GROUND"
  ),
  "schema paper sits on the stand"
);
assert(
  readFileSync("src/app/garage/page.tsx", "utf8").includes(
    '["maintenance", copy.workshopTabCare]'
  ),
  "web tabs follow Übersicht / Teile / Wartung / Setup"
);
assert(
  readFileSync("src/components/garage/DieBoxSurface.tsx", "utf8").includes(
    "BikeStandEditor"
  ),
  "km tap opens a stand editor, not the setups tab"
);
assert(
  readFileSync("src/components/garage/BikePhotoControl.tsx", "utf8").includes(
    "stand-photo-retake"
  ),
  "https photos offer retake under the stand, not on the bike"
);
assert(
  readFileSync("src/components/garage/BikePhotoControl.tsx", "utf8").includes(
    "StandPhotoCrop"
  ),
  "picked photos open a stand pan before save"
);
assert(
  readFileSync(
    "src/components/garage/GarageMaintenanceTab.tsx",
    "utf8"
  ).includes("bike-next-service"),
  "web maintenance tab holds the workshop date"
);
assert(
  readFileSync("src/lib/home/hofCopy.ts", "utf8").includes(
    'workshopStatCare: "Pflege"'
  ),
  "interval cell is Pflege, appointment stays Termin"
);

assert(
  readFileSync("src/components/garage/InstallComponentSheet.tsx", "utf8").includes(
    "presentCompat"
  ),
  "install sheet presents compat in chrome language"
);
assert(
  !readFileSync("src/components/garage/InstallComponentSheet.tsx", "utf8").includes(
    "r.explainDe"
  ),
  "install sheet does not dump German explainDe"
);
assert(
  readFileSync("src/components/garage/GarageSetupsTab.tsx", "utf8").includes(
    "presentSetupTemplate"
  ),
  "setup tab presents template labels"
);
assert(
  readFileSync("src/components/garage/BracketingPanel.tsx", "utf8").includes(
    "bracketingCopy"
  ),
  "bracketing chrome uses copy"
);
assert(
  readFileSync("src/app/garage/page.tsx", "utf8").includes("lang,"),
  "service report download uses chrome language"
);
assert(
  readFileSync("src/lib/garage/serviceReport.ts", "utf8").includes(
    "serviceReportCopy"
  ),
  "service report body uses copy"
);
assert(
  readFileSync("src/components/garage/SagGuidePanel.tsx", "utf8").includes(
    "sagGuideCopy"
  ),
  "sag helper uses copy"
);
assert(
  !readFileSync("src/components/garage/SagGuidePanel.tsx", "utf8").includes(
    "SAG einstellen"
  ),
  "sag helper has no hardcoded German heading"
);
assert(
  readFileSync("src/components/garage/AddBikeWizard.tsx", "utf8").includes(
    "addBikeCopy"
  ),
  "add-bike wizard uses copy"
);
assert(
  readFileSync("src/components/garage/GarageMaintenanceTab.tsx", "utf8").includes(
    "presentMaintActivity"
  ),
  "maintenance log titles map off German keys"
);
assert(
  !readFileSync("src/components/garage/BracketingPanel.tsx", "utf8").includes(
    "Zwei Varianten testen"
  ),
  "bracketing panel has no hardcoded German heading"
);
assert(
  readFileSync("src/app/profile/page.tsx", "utf8").includes("profileCopy"),
  "profile chrome uses copy"
);
assert(
  readFileSync("src/components/community/PublicProfilePanel.tsx", "utf8").includes(
    "profileCopy"
  ),
  "public profile uses copy"
);

console.log("garageUx.test.ts OK");
