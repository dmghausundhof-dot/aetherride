import { chromeLangFrom, chromeLangFromAcceptLanguage, valhallaLanguage } from "./chromeLang";

const cases: Array<[string | null, string]> = [
  [null, "de"],
  ["de", "de"],
  ["de-CH", "de"],
  ["en", "en"],
  ["en-US", "en"],
  ["en_GB", "en"],
  ["fr-CH", "fr"],
  ["fr", "fr"],
  ["it-IT", "it"],
  ["it-CH", "it"],
  ["nl-NL", "nl"],
  ["nl", "nl"],
  ["nl-BE", "nl"],
];

for (const [raw, want] of cases) {
  const got = chromeLangFrom(raw);
  if (got !== want) {
    throw new Error(`chromeLangFrom(${raw}) = ${got}, want ${want}`);
  }
}

if (chromeLangFromAcceptLanguage(null) !== "de") {
  throw new Error("accept empty");
}
if (chromeLangFromAcceptLanguage("nl-NL,en;q=0.9") !== "nl") {
  throw new Error("accept nl");
}
if (chromeLangFromAcceptLanguage("pl-PL,en;q=0.9") !== "en") {
  throw new Error("accept skip unknown");
}
if (chromeLangFromAcceptLanguage("fr-CH,fr;q=0.9") !== "fr") {
  throw new Error("accept fr-CH");
}
if (chromeLangFromAcceptLanguage("it;q=0.8,de;q=0.9") !== "de") {
  throw new Error("accept q-order");
}

if (valhallaLanguage("en") !== "en-US") {
  throw new Error("valhalla en");
}
if (valhallaLanguage("de") !== "de-DE") {
  throw new Error("valhalla de");
}
if (valhallaLanguage("fr") !== "fr-FR") {
  throw new Error("valhalla fr");
}
if (valhallaLanguage("it") !== "it-IT") {
  throw new Error("valhalla it");
}
if (valhallaLanguage("nl") !== "nl-NL") {
  throw new Error("valhalla nl");
}

console.log("chromeLang.test.ts ok");
