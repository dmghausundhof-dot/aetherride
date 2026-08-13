/**
 * Internal product name is `hof`. On-screen Home title follows country,
 * not UI language. CH splits by language region.
 */
export function hofTitleFor(
  countryCode?: string | null,
  languageCode = "de"
): string {
  const country = countryCode?.trim().toUpperCase() ?? "";
  const lang = languageCode.trim().toLowerCase();

  if (country === "CH") {
    if (lang === "fr") return "Le local vélo";
    if (lang === "it") return "La rimessa";
    return "Velokeller";
  }
  if (country === "IT") return "La rimessa";
  if (country === "FR") return "La remise";
  if (country === "AT" || country === "DE") return "Der Hof";
  if (
    country === "GB" ||
    country === "UK" ||
    country === "US" ||
    country === "AU" ||
    country === "NZ" ||
    country === "IE"
  ) {
    return "The Stand";
  }
  if (country === "CA") return lang === "fr" ? "La remise" : "The Stand";
  if (!country) {
    if (lang === "fr") return "La remise";
    if (lang === "it") return "La rimessa";
    if (lang === "en") return "The Stand";
    return "Der Hof";
  }
  return "Der Hof";
}

/** Browser locale → title. `de-CH` → Velokeller; `en-DE` → Der Hof. */
export function hofTitleFromNavigator(
  locale = typeof navigator !== "undefined" ? navigator.language : "de-DE"
): string {
  const [lang, region] = locale.replace("_", "-").split("-");
  return hofTitleFor(region ?? null, lang || "de");
}
