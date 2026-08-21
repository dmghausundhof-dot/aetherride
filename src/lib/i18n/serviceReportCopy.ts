/**
 * Service-report download chrome. Field labels follow bikeIdentityCopy.
 */
import type { ChromeLang } from "./chromeLang";

export type ServiceReportCopy = {
  title: string;
  created: (when: string) => string;
  bike: string;
  category: string;
  odometer: (km: string) => string;
  hours: (h: string) => string;
  rides: (n: number) => string;
  cost: (eur: string) => string;
  parts: string;
  installed: (date: string) => string;
  setup: string;
  setupLine: (label: string, condition: string, version: number) => string;
  log: string;
  logEmpty: string;
  workshop: string;
  self: string;
  disclaimer: string;
};

const DE: ServiceReportCopy = {
  title: "FlowLine — Service-Report",
  created: (when) => `Erstellt: ${when}`,
  bike: "Bike",
  category: "Kategorie",
  odometer: (km) => `Kilometerstand: ${km} km`,
  hours: (h) => `Stunden: ${h} h`,
  rides: (n) => `Rides erfasst: ${n}`,
  cost: (eur) => `Wartungskosten gesamt: ${eur} €`,
  parts: "— Aktive Komponenten —",
  installed: (date) => `Einbau ${date}`,
  setup: "— Aktuelles Setup —",
  setupLine: (label, condition, version) =>
    `„${label}“ · ${condition} · v${version}`,
  log: "— Wartungslog —",
  logEmpty: "(kein Eintrag)",
  workshop: "Werkstatt",
  self: "Eigen",
  disclaimer:
    "Hinweis: Report aus lokalen App-Daten. Keine Garantie gegenüber Werkstatt/Versicherung.",
};

const EN: ServiceReportCopy = {
  title: "FlowLine — service report",
  created: (when) => `Created: ${when}`,
  bike: "Bike",
  category: "Category",
  odometer: (km) => `Odometer: ${km} km`,
  hours: (h) => `Hours: ${h} h`,
  rides: (n) => `Rides logged: ${n}`,
  cost: (eur) => `Maintenance cost total: ${eur} €`,
  parts: "— Active parts —",
  installed: (date) => `Fitted ${date}`,
  setup: "— Current setup —",
  setupLine: (label, condition, version) =>
    `“${label}” · ${condition} · v${version}`,
  log: "— Maintenance log —",
  logEmpty: "(no entry)",
  workshop: "Workshop",
  self: "Own",
  disclaimer:
    "Note: report from local app data. No warranty toward a workshop or insurer.",
};

const FR: ServiceReportCopy = {
  title: "FlowLine — rapport d’entretien",
  created: (when) => `Créé : ${when}`,
  bike: "Vélo",
  category: "Catégorie",
  odometer: (km) => `Compteur : ${km} km`,
  hours: (h) => `Heures : ${h} h`,
  rides: (n) => `Sorties enregistrées : ${n}`,
  cost: (eur) => `Coût d’entretien total : ${eur} €`,
  parts: "— Pièces actives —",
  installed: (date) => `Monté ${date}`,
  setup: "— Setup actuel —",
  setupLine: (label, condition, version) =>
    `« ${label} » · ${condition} · v${version}`,
  log: "— Journal d’entretien —",
  logEmpty: "(aucune entrée)",
  workshop: "Atelier",
  self: "Soi",
  disclaimer:
    "Note : rapport issu des données locales. Aucune garantie vis-à-vis de l’atelier ou de l’assurance.",
};

const IT: ServiceReportCopy = {
  title: "FlowLine — report di servizio",
  created: (when) => `Creato: ${when}`,
  bike: "Bici",
  category: "Categoria",
  odometer: (km) => `Chilometraggio: ${km} km`,
  hours: (h) => `Ore: ${h} h`,
  rides: (n) => `Uscite registrate: ${n}`,
  cost: (eur) => `Costo manutenzione totale: ${eur} €`,
  parts: "— Componenti attivi —",
  installed: (date) => `Montato ${date}`,
  setup: "— Setup attuale —",
  setupLine: (label, condition, version) =>
    `«${label}» · ${condition} · v${version}`,
  log: "— Registro manutenzione —",
  logEmpty: "(nessuna voce)",
  workshop: "Officina",
  self: "Proprio",
  disclaimer:
    "Nota: report dai dati locali. Nessuna garanzia verso officina o assicurazione.",
};

const NL: ServiceReportCopy = {
  title: "FlowLine — servicerapport",
  created: (when) => `Gemaakt: ${when}`,
  bike: "Fiets",
  category: "Categorie",
  odometer: (km) => `Kilometerstand: ${km} km`,
  hours: (h) => `Uren: ${h} u`,
  rides: (n) => `Ritten vastgelegd: ${n}`,
  cost: (eur) => `Onderhoudskosten totaal: ${eur} €`,
  parts: "— Actieve onderdelen —",
  installed: (date) => `Geplaatst ${date}`,
  setup: "— Huidige setup —",
  setupLine: (label, condition, version) =>
    `„${label}” · ${condition} · v${version}`,
  log: "— Onderhoudslog —",
  logEmpty: "(geen regel)",
  workshop: "Werkplaats",
  self: "Zelf",
  disclaimer:
    "Let op: rapport uit lokale app-gegevens. Geen garantie richting werkplaats of verzekering.",
};

const BY: Record<ChromeLang, ServiceReportCopy> = {
  de: DE,
  en: EN,
  fr: FR,
  it: IT,
  nl: NL,
};

export function serviceReportCopy(lang: ChromeLang = "de"): ServiceReportCopy {
  return BY[lang] ?? DE;
}
