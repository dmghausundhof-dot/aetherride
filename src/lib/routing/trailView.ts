/**
 * F-NAV-006 Trail View (P2)
 *
 * Mapillary (CC BY-SA) + nutzergenerierte Fotos mit Geo + Blickrichtung.
 * DARF NICHT proprietäre Bilddienste einbetten, die das untersagen.
 * Attribution Pflicht (Spec 8.4 / Mapillary CC-BY-SA).
 */

export interface TrailPhoto {
  id: string;
  source: "mapillary" | "user";
  /** Demo: Platzhalter-URL / SVG data */
  imageUrl: string;
  lat: number;
  lng: number;
  /** Blickrichtung Grad 0–360 */
  headingDeg: number;
  capturedAt?: string; // nur User; Mapillary-Anzeige ohne Tracking-Zweck
  username: string;
  title: string;
  license: string;
  attributionHtml: string;
  mapillaryKey?: string;
}

export interface TrailViewResult {
  photos: TrailPhoto[];
  attribution: string;
  disclaimer: string;
}

/** Demo-Bilder entlang Alpbachtal — keine echten Mapillary-Blobs, Attribution-Demo */
export function getTrailViewNear(
  lat = 47.45,
  lng = 12.15
): TrailViewResult {
  const photos: TrailPhoto[] = [
    {
      id: "tv-mapillary-1",
      source: "mapillary",
      imageUrl:
        "data:image/svg+xml," +
        encodeURIComponent(
          `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360">
            <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#4a7c59"/><stop offset="100%" stop-color="#2d4a35"/>
            </linearGradient></defs>
            <rect width="640" height="360" fill="url(#g)"/>
            <text x="40" y="180" fill="#e8f0e9" font-size="28" font-family="sans-serif">Trail S2 · Wurzelteppich</text>
            <text x="40" y="220" fill="#b8d4bc" font-size="16" font-family="sans-serif">Mapillary Demo · CC BY-SA</text>
          </svg>`
        ),
      lat: lat + 0.002,
      lng: lng + 0.003,
      headingDeg: 125,
      username: "alpenmapper",
      title: "Flow Trail Söll – Wurzelpassage",
      license: "CC BY-SA 4.0",
      attributionHtml:
        "Flow Trail Soell by alpenmapper, licensed under CC BY-SA · via Mapillary",
      mapillaryKey: "demo-key-001",
    },
    {
      id: "tv-mapillary-2",
      source: "mapillary",
      imageUrl:
        "data:image/svg+xml," +
        encodeURIComponent(
          `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360">
            <rect width="640" height="360" fill="#3d5a80"/>
            <text x="40" y="170" fill="#e0fbfc" font-size="26" font-family="sans-serif">Bergfahrt · Schotter</text>
            <text x="40" y="210" fill="#98c1d9" font-size="16" font-family="sans-serif">Mapillary Demo · CC BY-SA</text>
          </svg>`
        ),
      lat: lat - 0.001,
      lng: lng + 0.005,
      headingDeg: 40,
      username: "tirol_tracks",
      title: "Anstieg Alpbachtal",
      license: "CC BY-SA 4.0",
      attributionHtml:
        "Anstieg Alpbachtal by tirol_tracks, licensed under CC BY-SA · via Mapillary",
      mapillaryKey: "demo-key-002",
    },
    {
      id: "tv-user-1",
      source: "user",
      imageUrl:
        "data:image/svg+xml," +
        encodeURIComponent(
          `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360">
            <rect width="640" height="360" fill="#1a1a2e"/>
            <text x="40" y="170" fill="#eee" font-size="26" font-family="sans-serif">Nutzerfoto · Blick 210°</text>
            <text x="40" y="210" fill="#aaa" font-size="16" font-family="sans-serif">Eigenes Foto mit Geobezug</text>
          </svg>`
        ),
      lat: lat + 0.004,
      lng: lng - 0.002,
      headingDeg: 210,
      capturedAt: "2026-07-12T14:22:00.000Z",
      username: "du",
      title: "Selbst aufgenommen – Kurvenausgang",
      license: "Nutzerinhalte · AetherRide",
      attributionHtml: "Nutzerfoto mit Geobezug und Blickrichtung 210°",
    },
  ];

  return {
    photos,
    attribution:
      "Mapillary imagery © contributors, CC BY-SA 4.0 · Logo/Link zu mapillary.com erforderlich",
    disclaimer:
      "Keine proprietären Street-View-Dienste. Attribution sichtbar (Spec F-NAV-006 / Mapillary Terms).",
  };
}
