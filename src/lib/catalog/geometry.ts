import type { FrameSizeGeometry } from "@/types/garage";

function g(
  size: string,
  reachMm: number,
  stackMm: number,
  sourceUrl: string,
  extra?: Partial<
    Omit<FrameSizeGeometry, "size" | "reachMm" | "stackMm" | "sourceUrl">
  >
): FrameSizeGeometry {
  return { size, reachMm, stackMm, sourceUrl, ...extra };
}

const PROPAIN_TYEE =
  "https://www.propain-bikes.com/en/product/bikes/enduro/tyee-al/";
const PROPAIN_TYEE_TRAIL =
  "https://www.propain-bikes.com/en/product/bikes/enduro/tyee-al-trail/";
const PROPAIN_HUGENE =
  "https://www.propain-bikes.com/en/product/bikes/trail/hugene-cf/";
const PROPAIN_SPINDRIFT =
  "https://www.propain-bikes.com/en/product/bikes/freeride/spindrift-cf/";
const PROPAIN_RAGE =
  "https://www.propain-bikes.com/en/product/bikes/downhill/rage-cf/";
const PROPAIN_SRESH =
  "https://www.propain-bikes.com/en/product/bikes/trail/sresh-sl/";
const PROPAIN_EKANO = "https://www.propain-bikes.com/en/the-all-new-ekano-2-al/";
const PROPAIN_EKANO_ENDURO =
  "https://www.propain-bikes.com/en/product/bikes/enduro/ekano-al-enduro/";
const PROPAIN_EKANO_TRAIL =
  "https://www.propain-bikes.com/en/product/bikes/trail/ekano-al-trail/";
const PROPAIN_TERREL =
  "https://www.propain-bikes.com/en/product/bikes/gravel/terrel-cf/";
const TREK_SLASH =
  "https://www.trekbikes.com/us/en_US/bikes/mountain-bikes/trail-mountain-bikes/slash/slash-c-gen-6-frameset/p/5307761/";
const TREK_RAIL =
  "https://www.trekbikes.com/us/en_US/bikes/mountain-bikes/electric-mountain-bikes/rail/rail-9-7-gen-4/p/37026/";
const SCOTT_GENIUS = "https://www.scott-sports.com/global/en/genius";
const CENTURION_NUMINIS =
  "https://www.centurion.de/de-de/bike/1213/numinis-r2000";
const CENTURION_BACKFIRE =
  "https://www.centurion.de/de-de/bike/1191/backfire-r2000";
const GHOST_PATH_RIOT =
  "https://ghost-bikes.com/en-int/products/path-riot-advanced-gfat1";
const HAIBIKE_LYKE = "https://haibike.com/de-de/products/lyke-cf-11-hmqt1";
const CANYON_STRIVE =
  "https://www.canyon.com/en-de/productpdf/geometry/?pid=3416";
const CANYON_GRAIL =
  "https://www.canyon.com/en-us/productpdf/geometry/?pid=3577";
const CANYON_SPECTRAL =
  "https://www.canyon.com/en-gb/mountain-bikes/trail-bikes/spectral/cf/spectral-cf-8/4023.html";
const SIMPLON_RAPCON =
  "https://www.simplon.com/en/Bikes/Mountain-Bikes/Rapcon_b_292368";
const SIMPLON_RAPCON_E =
  "https://www.simplon.com/en/Bikes/E-Mountain-Bikes/Rapcon-e_b_1149826";
const CUBE_NUROAD =
  "https://www.cube.eu/de-en/cube-nuroad-c-62-pro-vulcan-n-prism/130200";
const TREK_CHECKPOINT =
  "https://www.trekbikes.com/us/en_US/bikes/bikepacking-touring-bikes/checkpoint/checkpoint-sl/checkpoint-sl-5-gen-2/p/5298080/";

/**
 * OEM-Geometrie je Katalog-Bike. Nur Größen, die auch in `frameSizeOptions` stehen.
 * Kein Eintrag, wenn der Hersteller keine Reach/Stack-Tabelle veröffentlicht.
 */
export const BIKE_GEOMETRY: Record<string, FrameSizeGeometry[]> = {
  // 29" empfohlen in Low; XS/S nur 27.5 High.
  "cat-propain-tyee-2024": [
    g("XS", 399, 580, PROPAIN_TYEE, {
      setting: "27.5_high",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 77.3,
      chainstayMm: 430,
      wheelbaseMm: 1151,
    }),
    g("S", 424, 598, PROPAIN_TYEE, {
      setting: "27.5_high",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 77.3,
      chainstayMm: 430,
      wheelbaseMm: 1184,
    }),
    g("M", 449, 626, PROPAIN_TYEE, {
      setting: "29_low",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 76.9,
      chainstayMm: 445,
      wheelbaseMm: 1237,
    }),
    g("L", 473, 635, PROPAIN_TYEE, {
      setting: "29_low",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 76.9,
      chainstayMm: 445,
      wheelbaseMm: 1266,
    }),
    g("XL", 499, 646, PROPAIN_TYEE, {
      setting: "29_low",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 76.9,
      chainstayMm: 445,
      wheelbaseMm: 1296,
    }),
  ],
  "cat-propain-tyee-cf-2025": [
    g("XS", 399, 580, PROPAIN_TYEE, {
      setting: "27.5_high",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 77.3,
      chainstayMm: 430,
      wheelbaseMm: 1151,
    }),
    g("S", 424, 598, PROPAIN_TYEE, {
      setting: "27.5_high",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 77.3,
      chainstayMm: 430,
      wheelbaseMm: 1184,
    }),
    g("M", 449, 626, PROPAIN_TYEE, {
      setting: "29_low",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 76.9,
      chainstayMm: 445,
      wheelbaseMm: 1237,
    }),
    g("L", 473, 635, PROPAIN_TYEE, {
      setting: "29_low",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 76.9,
      chainstayMm: 445,
      wheelbaseMm: 1266,
    }),
    g("XL", 499, 646, PROPAIN_TYEE, {
      setting: "29_low",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 76.9,
      chainstayMm: 445,
      wheelbaseMm: 1296,
    }),
  ],
  "cat-propain-tyee-trail-2025": [
    g("S", 424, 598, PROPAIN_TYEE_TRAIL, {
      setting: "27.5_high",
      headAngleDeg: 64,
      chainstayMm: 430,
      wheelbaseMm: 1182,
    }),
    g("M", 450, 625, PROPAIN_TYEE_TRAIL, {
      setting: "29_low",
      headAngleDeg: 64.2,
      chainstayMm: 446,
      wheelbaseMm: 1233,
    }),
    g("L", 475, 634, PROPAIN_TYEE_TRAIL, {
      setting: "29_low",
      headAngleDeg: 64.2,
      chainstayMm: 446,
      wheelbaseMm: 1263,
    }),
    g("XL", 500, 644, PROPAIN_TYEE_TRAIL, {
      setting: "29_low",
      headAngleDeg: 64.2,
      chainstayMm: 446,
      wheelbaseMm: 1292,
    }),
  ],
  "cat-propain-hugene-2024": [
    g("S", 433, 612, PROPAIN_HUGENE, {
      setting: "140mm_fork",
      headAngleDeg: 64.8,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 445,
      wheelbaseMm: 1197,
    }),
    g("M", 458, 621, PROPAIN_HUGENE, {
      setting: "140mm_fork",
      headAngleDeg: 64.8,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 445,
      wheelbaseMm: 1226,
    }),
    g("L", 483, 632, PROPAIN_HUGENE, {
      setting: "140mm_fork",
      headAngleDeg: 64.8,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 445,
      wheelbaseMm: 1255,
    }),
    g("XL", 508, 639, PROPAIN_HUGENE, {
      setting: "140mm_fork",
      headAngleDeg: 64.8,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 445,
      wheelbaseMm: 1285,
    }),
  ],
  "cat-propain-spindrift-cf-2025": [
    g("S", 435, 613, PROPAIN_SPINDRIFT, {
      setting: "180mm_fork",
      headAngleDeg: 63.5,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1223,
    }),
    g("M", 460, 627, PROPAIN_SPINDRIFT, {
      setting: "180mm_fork",
      headAngleDeg: 63.5,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1254,
    }),
    g("L", 485, 636, PROPAIN_SPINDRIFT, {
      setting: "180mm_fork",
      headAngleDeg: 63.5,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1284,
    }),
    g("XL", 510, 649, PROPAIN_SPINDRIFT, {
      setting: "180mm_fork",
      headAngleDeg: 63.5,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1315,
    }),
  ],
  "cat-propain-rage-cf-2025": [
    g("M", 440, 629, PROPAIN_RAGE, {
      setting: "29_short_cs",
      headAngleDeg: 63,
      seatAngleEffectiveDeg: 79,
      chainstayMm: 445,
      wheelbaseMm: 1246,
    }),
    g("L", 465, 638, PROPAIN_RAGE, {
      setting: "29_short_cs",
      headAngleDeg: 63,
      seatAngleEffectiveDeg: 79,
      chainstayMm: 445,
      wheelbaseMm: 1275,
    }),
    g("XL", 495, 638, PROPAIN_RAGE, {
      setting: "29_short_cs",
      headAngleDeg: 63,
      seatAngleEffectiveDeg: 79,
      chainstayMm: 445,
      wheelbaseMm: 1305,
    }),
  ],
  "cat-propain-sresh-sl-2025": [
    g("S", 428, 616, PROPAIN_SRESH, {
      setting: "29_low_160mm",
      headAngleDeg: 64.3,
      seatAngleEffectiveDeg: 77.8,
      chainstayMm: 452,
      wheelbaseMm: 1213,
    }),
    g("M", 453, 625, PROPAIN_SRESH, {
      setting: "29_low_160mm",
      headAngleDeg: 64.3,
      seatAngleEffectiveDeg: 77.8,
      chainstayMm: 452,
      wheelbaseMm: 1243,
    }),
    g("L", 478, 634, PROPAIN_SRESH, {
      setting: "29_low_160mm",
      headAngleDeg: 64.3,
      seatAngleEffectiveDeg: 77.8,
      chainstayMm: 452,
      wheelbaseMm: 1272,
    }),
    g("XL", 503, 643, PROPAIN_SRESH, {
      setting: "29_low_160mm",
      headAngleDeg: 64.3,
      seatAngleEffectiveDeg: 77.8,
      chainstayMm: 452,
      wheelbaseMm: 1301,
    }),
  ],
  "cat-propain-ekano-enduro-2026": [
    g("S", 435, 633, PROPAIN_EKANO_ENDURO, {
      setting: "170mm_mix",
      headAngleDeg: 63.5,
      chainstayMm: 452,
      wheelbaseMm: 1238,
    }),
    g("M", 450, 638, PROPAIN_EKANO_ENDURO, {
      setting: "170mm_mix",
      headAngleDeg: 63.5,
      chainstayMm: 452,
      wheelbaseMm: 1255,
    }),
    g("L", 475, 642, PROPAIN_EKANO_ENDURO, {
      setting: "170mm_mix",
      headAngleDeg: 63.5,
      chainstayMm: 452,
      wheelbaseMm: 1282,
    }),
    g("XL", 500, 651, PROPAIN_EKANO_ENDURO, {
      setting: "170mm_mix",
      headAngleDeg: 63.5,
      chainstayMm: 452,
      wheelbaseMm: 1312,
    }),
  ],
  "cat-propain-ekano-trail-2026": [
    g("S", 439, 631, PROPAIN_EKANO_TRAIL, {
      setting: "160mm_fork",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 78.4,
    }),
    g("M", 454, 636, PROPAIN_EKANO_TRAIL, {
      setting: "160mm_fork",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 78.4,
    }),
    g("L", 479, 639, PROPAIN_EKANO_TRAIL, {
      setting: "160mm_fork",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 78.4,
    }),
    g("XL", 504, 649, PROPAIN_EKANO_TRAIL, {
      setting: "160mm_fork",
      headAngleDeg: 63.9,
      seatAngleEffectiveDeg: 78.4,
    }),
  ],
  "cat-propain-terrel-cf-2025": [
    g("XS", 382, 554, PROPAIN_TERREL, {
      headAngleDeg: 69.5,
      chainstayMm: 435,
      wheelbaseMm: 1037,
    }),
    g("S", 396, 568, PROPAIN_TERREL, {
      headAngleDeg: 70,
      chainstayMm: 435,
      wheelbaseMm: 1053,
    }),
    g("M", 405, 583, PROPAIN_TERREL, {
      headAngleDeg: 70.5,
      chainstayMm: 435,
      wheelbaseMm: 1062,
    }),
    g("L", 412, 608, PROPAIN_TERREL, {
      headAngleDeg: 71,
      chainstayMm: 435,
      wheelbaseMm: 1073,
    }),
    g("XL", 430, 632, PROPAIN_TERREL, {
      headAngleDeg: 71.5,
      chainstayMm: 435,
      wheelbaseMm: 1094,
    }),
  ],
  "cat-propain-ekano-2025": [
    g( "S", 435, 644, PROPAIN_EKANO, {
      setting: "180mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1231,
    }),
    g( "M", 455, 648, PROPAIN_EKANO, {
      setting: "180mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1253,
    }),
    g( "L", 475, 653, PROPAIN_EKANO, {
      setting: "180mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1275,
    }),
    g( "XL", 495, 662, PROPAIN_EKANO, {
      setting: "180mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 445,
      wheelbaseMm: 1299,
    }),
  ],
  // Neutral-Headset (Serien-Cups). Größen S/M/L/XL — kein M/L im Katalog.
  "cat-trek-slash-8-2024": [
    g( "S", 430, 588, TREK_SLASH, {
      setting: "neutral",
      headAngleDeg: 63.5,
      seatAngleEffectiveDeg: 78.1,
      chainstayMm: 429,
      wheelbaseMm: 1195,
    }),
    g( "M", 448, 623, TREK_SLASH, {
      setting: "neutral",
      headAngleDeg: 63.3,
      seatAngleEffectiveDeg: 77.8,
      chainstayMm: 429,
      wheelbaseMm: 1224,
    }),
    g( "L", 488, 641, TREK_SLASH, {
      setting: "neutral",
      headAngleDeg: 63.3,
      seatAngleEffectiveDeg: 77.1,
      chainstayMm: 434,
      wheelbaseMm: 1278,
    }),
    g( "XL", 513, 659, TREK_SLASH, {
      setting: "neutral",
      headAngleDeg: 63.3,
      seatAngleEffectiveDeg: 76.7,
      chainstayMm: 439,
      wheelbaseMm: 1312,
    }),
  ],
  // Mino-Link High (cm-Tabelle × 10).
  "cat-trek-rail-9-2024": [
    g( "S", 436, 625, TREK_RAIL, {
      setting: "high",
      headAngleDeg: 64.6,
      seatAngleEffectiveDeg: 77.1,
      chainstayMm: 447,
      wheelbaseMm: 1213,
    }),
    g( "M", 456, 629, TREK_RAIL, {
      setting: "high",
      headAngleDeg: 64.6,
      seatAngleEffectiveDeg: 77.1,
      chainstayMm: 447,
      wheelbaseMm: 1236,
    }),
    g( "L", 491, 643, TREK_RAIL, {
      setting: "high",
      headAngleDeg: 64.6,
      seatAngleEffectiveDeg: 77.1,
      chainstayMm: 447,
      wheelbaseMm: 1277,
    }),
    g( "XL", 521, 656, TREK_RAIL, {
      setting: "high",
      headAngleDeg: 64.6,
      seatAngleEffectiveDeg: 77.1,
      chainstayMm: 447,
      wheelbaseMm: 1313,
    }),
  ],
  // Scott Genius Owner's Manual 1990254 / Headset +0.6° (65.1°).
  "cat-scott-genius-910-2024": [
    g( "S", 430, 617, SCOTT_GENIUS, {
      setting: "headset_steep",
      headAngleDeg: 65.1,
      seatAngleEffectiveDeg: 76.8,
      chainstayMm: 440,
      wheelbaseMm: 1182,
    }),
    g( "M", 460, 626.1, SCOTT_GENIUS, {
      setting: "headset_steep",
      headAngleDeg: 65.1,
      seatAngleEffectiveDeg: 77.1,
      chainstayMm: 440,
      wheelbaseMm: 1216,
    }),
    g( "L", 485, 644.2, SCOTT_GENIUS, {
      setting: "headset_steep",
      headAngleDeg: 65.1,
      seatAngleEffectiveDeg: 77.2,
      chainstayMm: 440,
      wheelbaseMm: 1249,
    }),
    g( "XL", 510, 657.8, SCOTT_GENIUS, {
      setting: "headset_steep",
      headAngleDeg: 65.1,
      seatAngleEffectiveDeg: 77.4,
      chainstayMm: 440,
      wheelbaseMm: 1281,
    }),
  ],
  "cat-centurion-numinis-r2000-2026": [
    g( "S", 425, 638, CENTURION_NUMINIS, {
      headAngleDeg: 65.5,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 465,
      wheelbaseMm: 1215,
    }),
    g( "M", 445, 647, CENTURION_NUMINIS, {
      headAngleDeg: 65.5,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 465,
      wheelbaseMm: 1239,
    }),
    g( "L", 465, 656, CENTURION_NUMINIS, {
      headAngleDeg: 65.5,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 465,
      wheelbaseMm: 1264,
    }),
    g( "XL", 485, 665, CENTURION_NUMINIS, {
      headAngleDeg: 65.5,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 465,
      wheelbaseMm: 1288,
    }),
  ],
  "cat-canyon-strive-cfr-2024": [
    g("S", 450, 629, CANYON_STRIVE, {
      setting: "shred",
      headAngleDeg: 63,
      seatAngleEffectiveDeg: 76.5,
      chainstayMm: 435,
      wheelbaseMm: 1234,
    }),
    g("M", 475, 634, CANYON_STRIVE, {
      setting: "shred",
      headAngleDeg: 63,
      seatAngleEffectiveDeg: 76.5,
      chainstayMm: 435,
      wheelbaseMm: 1262,
    }),
    g("L", 500, 642, CANYON_STRIVE, {
      setting: "shred",
      headAngleDeg: 63,
      seatAngleEffectiveDeg: 76.5,
      chainstayMm: 435,
      wheelbaseMm: 1291,
    }),
    g("XL", 525, 660, CANYON_STRIVE, {
      setting: "shred",
      headAngleDeg: 63,
      seatAngleEffectiveDeg: 76.5,
      chainstayMm: 435,
      wheelbaseMm: 1325,
    }),
  ],
  "cat-canyon-grail-2024": [
    g("XS", 385, 556, CANYON_GRAIL, {
      headAngleDeg: 71,
      seatAngleEffectiveDeg: 73.5,
      chainstayMm: 425,
      wheelbaseMm: 1024,
    }),
    g("S", 394, 573, CANYON_GRAIL, {
      headAngleDeg: 71.5,
      seatAngleEffectiveDeg: 73.5,
      chainstayMm: 425,
      wheelbaseMm: 1034,
    }),
    g("M", 411, 591, CANYON_GRAIL, {
      headAngleDeg: 71.5,
      seatAngleEffectiveDeg: 73.5,
      chainstayMm: 425,
      wheelbaseMm: 1057,
    }),
    g("L", 427, 613, CANYON_GRAIL, {
      headAngleDeg: 71.5,
      seatAngleEffectiveDeg: 73.5,
      chainstayMm: 425,
      wheelbaseMm: 1080,
    }),
    g("XL", 435, 633, CANYON_GRAIL, {
      headAngleDeg: 71.8,
      seatAngleEffectiveDeg: 73.5,
      chainstayMm: 425,
      wheelbaseMm: 1092,
    }),
  ],
  "cat-canyon-spectral-cf8-2024": [
    g("S", 450, 621, CANYON_SPECTRAL, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 76.5,
    }),
    g("M", 475, 630, CANYON_SPECTRAL, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 76.5,
    }),
    g("L", 500, 639, CANYON_SPECTRAL, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 76.5,
    }),
    g("XL", 525, 648, CANYON_SPECTRAL, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 76.5,
    }),
  ],
  "cat-simplon-rapcon-2024": [
    g("S", 435, 627, SIMPLON_RAPCON, {
      setting: "170mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 432,
      wheelbaseMm: 1205,
    }),
    g("M", 455, 633, SIMPLON_RAPCON, {
      setting: "170mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 438,
      wheelbaseMm: 1234,
    }),
    g("L", 475, 643, SIMPLON_RAPCON, {
      setting: "170mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 443,
      wheelbaseMm: 1264,
    }),
    g("XL", 495, 650, SIMPLON_RAPCON, {
      setting: "170mm_fork",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 78,
      chainstayMm: 447,
      wheelbaseMm: 1290,
    }),
  ],
  "cat-simplon-rapcon-e-2026": [
    g("S", 438, 627, SIMPLON_RAPCON_E, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 445,
      wheelbaseMm: 1231,
    }),
    g("M", 460, 638, SIMPLON_RAPCON_E, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 445,
      wheelbaseMm: 1253,
    }),
    g("L", 480, 646, SIMPLON_RAPCON_E, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 450,
      wheelbaseMm: 1281,
    }),
    g("XL", 500, 655, SIMPLON_RAPCON_E, {
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77.5,
      chainstayMm: 455,
      wheelbaseMm: 1311,
    }),
  ],
  "cat-cube-nuroad-2024": [
    g("XS", 388, 520, CUBE_NUROAD, {
      headAngleDeg: 69,
      seatAngleEffectiveDeg: 75.5,
      chainstayMm: 440,
      wheelbaseMm: 1043,
    }),
    g("S", 388, 544, CUBE_NUROAD, {
      headAngleDeg: 70,
      seatAngleEffectiveDeg: 74.7,
      chainstayMm: 440,
      wheelbaseMm: 1044,
    }),
    g("M", 393, 579, CUBE_NUROAD, {
      headAngleDeg: 71.5,
      seatAngleEffectiveDeg: 73.9,
      chainstayMm: 440,
      wheelbaseMm: 1046,
    }),
    g("L", 392, 599, CUBE_NUROAD, {
      headAngleDeg: 72,
      seatAngleEffectiveDeg: 73,
      chainstayMm: 442,
      wheelbaseMm: 1048,
    }),
    g("XL", 402, 623, CUBE_NUROAD, {
      headAngleDeg: 72.5,
      seatAngleEffectiveDeg: 73,
      chainstayMm: 442,
      wheelbaseMm: 1060,
    }),
  ],
  "cat-trek-checkpoint-2024": [
    g("49", 393, 538, TREK_CHECKPOINT, {
      headAngleDeg: 71.2,
      seatAngleEffectiveDeg: 74.1,
      chainstayMm: 435,
      wheelbaseMm: 1025,
    }),
    g("52", 399, 553, TREK_CHECKPOINT, {
      headAngleDeg: 71.6,
      seatAngleEffectiveDeg: 73.7,
      chainstayMm: 435,
      wheelbaseMm: 1033,
    }),
    g("54", 403, 571, TREK_CHECKPOINT, {
      headAngleDeg: 71.8,
      seatAngleEffectiveDeg: 73.2,
      chainstayMm: 435,
      wheelbaseMm: 1041,
    }),
    g("56", 407, 592, TREK_CHECKPOINT, {
      headAngleDeg: 72.2,
      seatAngleEffectiveDeg: 72.8,
      chainstayMm: 435,
      wheelbaseMm: 1048,
    }),
    g("58", 411, 609, TREK_CHECKPOINT, {
      headAngleDeg: 72.3,
      seatAngleEffectiveDeg: 72.5,
      chainstayMm: 435,
      wheelbaseMm: 1058,
    }),
  ],
  "cat-ghost-path-riot-advanced-2026": [
    g("S", 440, 604, GHOST_PATH_RIOT, {
      setting: "high",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77,
      chainstayMm: 446,
      wheelbaseMm: 1219,
    }),
    g("M", 470, 622, GHOST_PATH_RIOT, {
      setting: "high",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77,
      chainstayMm: 446,
      wheelbaseMm: 1257,
    }),
    g("L", 497, 644, GHOST_PATH_RIOT, {
      setting: "high",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77,
      chainstayMm: 455,
      wheelbaseMm: 1306,
    }),
    g("XL", 527, 662, GHOST_PATH_RIOT, {
      setting: "high",
      headAngleDeg: 64,
      seatAngleEffectiveDeg: 77,
      chainstayMm: 455,
      wheelbaseMm: 1345,
    }),
  ],
  "cat-haibike-lyke-cf-11-2025": [
    g("S", 424, 611, HAIBIKE_LYKE, {
      setting: "high",
      headAngleDeg: 65,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 450,
      wheelbaseMm: 1195,
    }),
    g("M", 452, 620, HAIBIKE_LYKE, {
      setting: "high",
      headAngleDeg: 65,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 450,
      wheelbaseMm: 1227,
    }),
    g("L", 479, 629, HAIBIKE_LYKE, {
      setting: "high",
      headAngleDeg: 65,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 450,
      wheelbaseMm: 1259,
    }),
    g("XL", 506, 638, HAIBIKE_LYKE, {
      setting: "high",
      headAngleDeg: 65,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 450,
      wheelbaseMm: 1290,
    }),
  ],
  "cat-centurion-backfire-r2000-2026": [
    g("S", 420, 661, CENTURION_BACKFIRE, {
      headAngleDeg: 67.5,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 460,
      wheelbaseMm: 1168,
    }),
    g("M", 440, 679, CENTURION_BACKFIRE, {
      headAngleDeg: 67.5,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 460,
      wheelbaseMm: 1196,
    }),
    g("L", 460, 698, CENTURION_BACKFIRE, {
      headAngleDeg: 67.5,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 460,
      wheelbaseMm: 1223,
    }),
    g("XL", 480, 716, CENTURION_BACKFIRE, {
      headAngleDeg: 67.5,
      seatAngleEffectiveDeg: 74,
      chainstayMm: 460,
      wheelbaseMm: 1251,
    }),
  ],
};

export function geometryForSize(
  rows: FrameSizeGeometry[] | undefined,
  size: string | undefined
): FrameSizeGeometry | undefined {
  if (!rows?.length || !size) return undefined;
  return rows.find((r) => r.size === size);
}
