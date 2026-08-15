import { hofTitleFor } from "./hofTitle";

const cases: Array<[string | null, string, string]> = [
  ["DE", "de", "Der Hof"],
  ["DE", "en", "Der Hof"],
  ["AT", "de", "Der Hof"],
  ["CH", "de", "Velokeller"],
  ["CH", "fr", "Le local vélo"],
  ["CH", "it", "La rimessa"],
  ["FR", "fr", "La remise"],
  ["IT", "it", "La rimessa"],
  ["US", "en", "The Stand"],
  ["US", "de", "The Stand"],
  [null, "de", "Der Hof"],
];

for (const [country, lang, want] of cases) {
  const got = hofTitleFor(country, lang);
  if (got !== want) {
    throw new Error(`hofTitleFor(${country}, ${lang}) = ${got}, want ${want}`);
  }
}

console.log("hofTitle.test.ts ok");
