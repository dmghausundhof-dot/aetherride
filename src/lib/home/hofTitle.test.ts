import { hofTitleFor } from "./hofTitle";

const cases: Array<[string | null, string, string]> = [
  ["DE", "de", "Start"],
  ["DE", "en", "Start"],
  ["AT", "de", "Start"],
  ["CH", "de", "Start"],
  ["CH", "fr", "Accueil"],
  ["CH", "it", "Inizio"],
  ["CA", "fr", "Accueil"],
  ["CA", "en", "Start"],
  ["FR", "fr", "Accueil"],
  ["IT", "it", "Inizio"],
  ["US", "en", "Start"],
  ["US", "de", "Start"],
  [null, "de", "Start"],
];

for (const [country, lang, want] of cases) {
  const got = hofTitleFor(country, lang);
  if (got !== want) {
    throw new Error(`hofTitleFor(${country}, ${lang}) = ${got}, want ${want}`);
  }
}

console.log("hofTitle.test.ts ok");
