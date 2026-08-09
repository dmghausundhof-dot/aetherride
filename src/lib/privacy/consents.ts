/**
 * F-ACC-005 Privatsphärenzonen + F-ACC-006 Granulare Einwilligungen
 * Strava-Lehre: Privacy Zones vor Aggregation (Heatmap).
 */

export interface PrivacyZone {
  id: string;
  label: string;
  lat: number;
  lng: number;
  radiusM: number;
}

export type ConsentPurpose =
  | "raw_data_upload"
  | "heatmap_contribution"
  | "product_recommendations"
  | "analytics"
  | "health_data";

export interface ConsentState {
  purpose: ConsentPurpose;
  granted: boolean;
  updatedAt: string;
  policyVersion: string;
}

export const CONSENT_LABELS: Record<
  ConsentPurpose,
  { title: string; description: string }
> = {
  raw_data_upload: {
    title: "Rohdaten-Upload",
    description:
      "Sensor-Rohdaten nur bei WLAN und Opt-in (Spec F-SEN-006). Widerruf jederzeit.",
  },
  heatmap_contribution: {
    title: "Heatmap-Beitrag",
    description:
      "Anonymisierte Zellen ohne Zeitstempel; Community-Overlay erst ab k≥5 (F-NAV-005).",
  },
  product_recommendations: {
    title: "Produktempfehlungen",
    description:
      "Nur anlassbezogen mit Datenpunkt (F-SHP-002). Kein Tracking-Marketing.",
  },
  analytics: {
    title: "Analytics",
    description: "Produktmetriken ohne Gesundheits-/Rohsensordaten.",
  },
  health_data: {
    title: "Gesundheitsdaten (Art. 9)",
    description:
      "Vorbereitung — keine Health-Connect-Anbindung in dieser Version.",
  },
};

export const DEFAULT_CONSENTS: ConsentState[] = (
  Object.keys(CONSENT_LABELS) as ConsentPurpose[]
).map((purpose) => ({
  purpose,
  granted: purpose === "product_recommendations", // sinnvoller Default für Demo-Shop
  updatedAt: new Date().toISOString(),
  policyVersion: "1.0",
}));

export const DEFAULT_PRIVACY_ZONES: PrivacyZone[] = [
  {
    id: "pz-home",
    label: "Zuhause",
    lat: 47.448,
    lng: 12.148,
    radiusM: 200,
  },
];
