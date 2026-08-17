/**
 * Internal product name remains `hof`. On-screen title is the job word
 * by UI language — not country poetry (Velokeller / The Stand / La remise).
 */
export function hofTitleFor(
  _countryCode?: string | null,
  languageCode = "de"
): string {
  const lang = languageCode.trim().toLowerCase();
  if (lang === "fr") return "Accueil";
  if (lang === "it") return "Inizio";
  if (lang === "nl") return "Start";
  return "Start";
}

/** Browser locale → title. Language only; country no longer changes the word. */
export function hofTitleFromNavigator(
  locale = typeof navigator !== "undefined" ? navigator.language : "de-DE"
): string {
  const [lang] = locale.replace("_", "-").split("-");
  return hofTitleFor(null, lang || "de");
}
