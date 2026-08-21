/**
 * F-NAV-004 for OSM round-trips: exactly three rider-facing reasons.
 * Duration · surface (ORS extras, no engine name) · OSM ways.
 */

import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { loopOsmHonesty } from "@/lib/routing/osmRoundTrip";

const ENGINE_BRAND =
  /openrouteservice|graphhopper|valhalla|\bosrm\b|\bors\b/i;

export function surfaceFromLoopWarnings(warnings: string[]): string | null {
  for (const raw of warnings) {
    const w = raw.replace(ENGINE_BRAND, "").replace(/\s{2,}/g, " ").trim();
    const m =
      /überwiegend\s+(.+)$/i.exec(w) ||
      /predominantly\s+(.+)$/i.exec(w) ||
      /surtout\s+(.+)$/i.exec(w);
    if (m) {
      const s = m[1].replace(/^[\s:—\-–]+/, "").trim();
      if (s.length >= 3 && !ENGINE_BRAND.test(s)) return s;
    }
  }
  return null;
}

export function loopJustificationReasons(opts: {
  durationMin: number;
  targetMin: number;
  surface?: string | null;
  lang?: ChromeLang;
}): [string, string, string] {
  const lang = opts.lang ?? "de";
  const got = Math.max(0, Math.round(opts.durationMin));
  const want = Math.max(0, Math.round(opts.targetMin));
  const duration = (() => {
    switch (lang) {
      case "en":
        return `Duration ${got} min · target ${want} min`;
      case "fr":
        return `Durée ${got} min · visée ${want} min`;
      case "it":
        return `Durata ${got} min · obiettivo ${want} min`;
      case "nl":
        return `Duur ${got} min · doel ${want} min`;
      default:
        return `Dauer ${got} min · Ziel ${want} min`;
    }
  })();
  const surface = opts.surface?.trim();
  const surfaceLine = surface
    ? (() => {
        switch (lang) {
          case "en":
            return `Mostly ${surface}`;
          case "fr":
            return `Surtout ${surface}`;
          case "it":
            return `Prevalentemente ${surface}`;
          case "nl":
            return `Vooral ${surface}`;
          default:
            return `Überwiegend ${surface}`;
        }
      })()
    : (() => {
        switch (lang) {
          case "en":
            return "Surface from OSM tags";
          case "fr":
            return "Surface d’après les tags OSM";
          case "it":
            return "Superficie dai tag OSM";
          case "nl":
            return "Ondergrond volgens OSM-tags";
          default:
            return "Oberfläche nach OSM-Tags";
        }
      })();
  const osm = loopOsmHonesty(lang);
  return [duration, surfaceLine, osm];
}
