import { chromeLangFrom, chromeLangFromAcceptLanguage, chromeLangFromNavigator, chromeLangOverrideFrom, chromeOgLocale, resolveChromeLang, valhallaLanguage } from "./chromeLang";
import { readFileSync } from "node:fs";

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
if (chromeLangFromAcceptLanguage("en,de") !== "en") {
  throw new Error("equal-q keeps order en");
}
if (chromeLangFromAcceptLanguage("de,en") !== "de") {
  throw new Error("equal-q keeps order de");
}

if (chromeLangFromNavigator({ language: "fr-CH" }) !== "fr") {
  throw new Error("navigator language");
}
if (
  chromeLangFromNavigator({
    language: "pl-PL",
    languages: ["pl-PL", "en-GB"],
  }) !== "en"
) {
  throw new Error("navigator languages skip unknown");
}

if (chromeLangOverrideFrom("en") !== "en") {
  throw new Error("override en");
}
if (chromeLangOverrideFrom("pl") !== null) {
  throw new Error("unknown override is not German");
}
if (resolveChromeLang({ override: "it", acceptLanguage: "en" }) !== "it") {
  throw new Error("override wins");
}
if (resolveChromeLang({ acceptLanguage: "nl-NL,en;q=0.8" }) !== "nl") {
  throw new Error("resolve accept");
}
if (chromeOgLocale("fr") !== "fr_FR") {
  throw new Error("og fr");
}

const request = readFileSync("src/lib/i18n/requestChromeLang.ts", "utf8");
if (!request.includes("accept-language")) {
  throw new Error("requestChromeLang reads Accept-Language");
}
if (!request.includes("CHROME_LANG_COOKIE")) {
  throw new Error("requestChromeLang reads override cookie");
}
const layout = readFileSync("src/app/layout.tsx", "utf8");
if (!layout.includes("requestChromeLang")) {
  throw new Error("root layout uses requestChromeLang");
}
if (!layout.includes("heroLead")) {
  throw new Error("root metadata uses homepage copy");
}
if (!layout.includes("ChromeLang") && !layout.includes("initialLang")) {
  throw new Error("root layout seeds chrome lang");
}
const providers = readFileSync("src/components/Providers.tsx", "utf8");
if (!providers.includes("ChromeLangProvider")) {
  throw new Error("Providers wraps ChromeLangProvider");
}
const profile = readFileSync("src/app/profile/page.tsx", "utf8");
if (!profile.includes("ChromeLangPicker")) {
  throw new Error("profile has language picker");
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
