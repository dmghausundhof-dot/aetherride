import { discoverStatus, discoverUi } from "@/lib/i18n/discoverUi";
import { catalogCopy } from "@/lib/i18n/catalogCopy";
import type { ChromeLang } from "@/lib/i18n/chromeLang";
import { routeResultMessage } from "@/lib/routing/planDraft";
import type { RoutingProfile } from "@/lib/routing/profiles";

export type TourLiveMapStatusInput = {
  distanceM: number;
  durationS: number;
  engine?: string;
  warnings?: string[];
  cached?: boolean;
  shape?: string;
  profile?: RoutingProfile;
};

const REMEMBERED: Record<ChromeLang, string> = {
  de: "gemerkt",
  en: "remembered",
  fr: "déjà là",
  it: "già qui",
  nl: "onthouden",
};

const OUT_AND_BACK: Record<ChromeLang, string> = {
  de: "Hin und zurück",
  en: "There and back",
  fr: "Aller-retour",
  it: "Andata e ritorno",
  nl: "Heen en terug",
};

function isTourMetaWarning(w: string): boolean {
  const t = w.toLowerCase();
  return (
    t.includes("forcelive") ||
    t.includes("engine-route") ||
    t.includes("live-engine") ||
    w.startsWith("Kuratierte Tour-Geometrie") ||
    w.startsWith("Tour-Geometrie aus") ||
    w.startsWith("Route ab Standort")
  );
}

function shapeHof(shape: string | undefined, lang: ChromeLang): string | undefined {
  if (!shape) return undefined;
  if (shape === "loop") return catalogCopy(lang).tour.loop;
  if (shape === "point_to_point") return discoverUi(lang).stretch;
  if (shape === "out_and_back") return OUT_AND_BACK[lang];
  return undefined;
}

/** Rider overlay: km · min, honesty, Outdooractive. No raw engine / Cache. */
export function tourLiveMapStatus(
  data: TourLiveMapStatusInput,
  lang: ChromeLang = "de",
): string {
  const warnings = (data.warnings ?? []).filter((w) => !isTourMetaWarning(w));
  const head = routeResultMessage({
    distanceM: data.distanceM,
    durationS: data.durationS,
    geometry: { type: "LineString", coordinates: [] },
    engine: data.engine ?? "tour",
    profile: data.profile ?? "gravel",
    warnings,
  });
  const parts = [discoverStatus(head, lang)];
  const engine = (data.engine ?? "").trim();
  if (/^outdooractive$/i.test(engine)) parts.push("Outdooractive");
  if (data.cached) parts.push(REMEMBERED[lang]);
  const shape = shapeHof(data.shape, lang);
  if (shape) parts.push(shape);
  return parts.join(" · ");
}
