import { hofSkyLine } from "./hofSky";

const cases: Array<[string | null, number | null, string]> = [
  ["dry_likely", 14, "14° · eher trocken"],
  ["damp_possible", 11.4, "11° · feucht möglich"],
  ["wet_likely", 8, "8° · Regen · Trails eher nass"],
  [null, null, "Himmel unbekannt"],
  ["dry_likely", null, "Himmel unbekannt"],
];

for (const [hint, temp, want] of cases) {
  const got = hofSkyLine(hint, temp);
  if (got !== want) {
    throw new Error(`hofSkyLine(${hint}, ${temp}) = ${got}, want ${want}`);
  }
}

console.log("hofSky.test.ts ok");
