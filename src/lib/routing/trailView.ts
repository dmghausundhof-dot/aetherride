/**
 * F-NAV-006 Trail View (P2)
 *
 * Mapillary (CC BY-SA) + nutzergenerierte Fotos mit Geo + Blickrichtung.
 * Token: MAPILLARY_ACCESS_TOKEN / NEXT_PUBLIC_MAPILLARY_ACCESS_TOKEN
 */

export interface TrailPhoto {
  id: string;
  source: "mapillary" | "user";
  imageUrl: string;
  lat: number;
  lng: number;
  headingDeg: number;
  capturedAt?: string;
  username: string;
  title: string;
  license: string;
  attributionHtml: string;
  mapillaryKey?: string;
  demo?: boolean;
}

export interface TrailViewResult {
  photos: TrailPhoto[];
  attribution: string;
  disclaimer: string;
  usingDemo: boolean;
}

function demoPhotos(lat: number, lng: number): TrailPhoto[] {
  return [
    {
      id: "tv-mapillary-1",
      source: "mapillary",
      demo: true,
      imageUrl:
        "data:image/svg+xml," +
        encodeURIComponent(
          `<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360">
            <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#4a7c59"/><stop offset="100%" stop-color="#2d4a35"/>
            </linearGradient></defs>
            <rect width="640" height="360" fill="url(#g)"/>
            <text x="40" y="180" fill="#e8f0e9" font-size="28" font-family="sans-serif">Trail-Foto Beispiel</text>
            <text x="40" y="220" fill="#b8d4bc" font-size="16" font-family="sans-serif">Mapillary nicht konfiguriert</text>
          </svg>`
        ),
      lat: lat + 0.002,
      lng: lng + 0.003,
      headingDeg: 125,
      username: "beispiel",
      title: "Beispiel — Mapillary-Zugang fehlt",
      license: "CC BY-SA 4.0",
      attributionHtml: "Beispiel-Platzhalter · Mapillary CC BY-SA",
      mapillaryKey: "demo",
    },
  ];
}

export function getTrailViewNear(
  lat = 47.45,
  lng = 12.15
): TrailViewResult {
  return {
    photos: demoPhotos(lat, lng),
    attribution:
      "Mapillary imagery © contributors, CC BY-SA 4.0 · mapillary.com",
    disclaimer:
      "Beispielbilder — Live-Trail-View braucht Mapillary-Token.",
    usingDemo: true,
  };
}

/** Server/client fetch Mapillary Graph API when token present */
export async function fetchTrailViewNear(
  lat = 47.45,
  lng = 12.15,
  token?: string
): Promise<TrailViewResult> {
  const t =
    token ||
    process.env.MAPILLARY_ACCESS_TOKEN ||
    process.env.NEXT_PUBLIC_MAPILLARY_ACCESS_TOKEN;

  if (!t) {
    return getTrailViewNear(lat, lng);
  }

  try {
    const url = new URL("https://graph.mapillary.com/images");
    url.searchParams.set("access_token", t);
    url.searchParams.set(
      "fields",
      "id,thumb_1024_url,computed_geometry,compass_angle,captured_at,creator"
    );
    // bbox around point ~0.01 deg
    const d = 0.01;
    url.searchParams.set(
      "bbox",
      `${lng - d},${lat - d},${lng + d},${lat + d}`
    );
    url.searchParams.set("limit", "8");

    const res = await fetch(url.toString());
    if (!res.ok) {
      const fallback = getTrailViewNear(lat, lng);
      return {
        ...fallback,
        disclaimer: `Mapillary API ${res.status} — Demo-Fallback.`,
      };
    }
    const data = await res.json();
    const photos: TrailPhoto[] = (data.data || []).map(
      (img: {
        id: string;
        thumb_1024_url?: string;
        computed_geometry?: { coordinates?: number[] };
        compass_angle?: number;
        captured_at?: string;
        creator?: { username?: string };
      }) => {
        const coords = img.computed_geometry?.coordinates;
        return {
          id: img.id,
          source: "mapillary" as const,
          imageUrl: img.thumb_1024_url || "",
          lat: coords?.[1] ?? lat,
          lng: coords?.[0] ?? lng,
          headingDeg: img.compass_angle ?? 0,
          capturedAt: img.captured_at,
          username: img.creator?.username || "mapillary",
          title: `Mapillary ${img.id}`,
          license: "CC BY-SA 4.0",
          attributionHtml: `Image by ${img.creator?.username || "contributor"} via Mapillary, CC BY-SA`,
          mapillaryKey: img.id,
          demo: false,
        };
      }
    );

    if (photos.length === 0) {
      return {
        ...getTrailViewNear(lat, lng),
        disclaimer: "Keine Mapillary-Bilder in der Nähe — Demo-Fallback.",
      };
    }

    return {
      photos,
      attribution:
        "Mapillary imagery © contributors, CC BY-SA 4.0 · mapillary.com",
      disclaimer:
        "Live Mapillary (CC BY-SA). Attribution Pflicht (Spec F-NAV-006).",
      usingDemo: false,
    };
  } catch {
    return getTrailViewNear(lat, lng);
  }
}
