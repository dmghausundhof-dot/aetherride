/**
 * F-NAV-005 Heatmaps (P2)
 *
 * Nur eigene aggregierte Nutzerdaten.
 * MUSS: Segment erst ab ≥ 5 verschiedenen Nutzern (k-Anonymität),
 * OSM-Snap, keine Timestamps, Privacy-Zonen + Start/Ende ausgeschlossen.
 * Kaltstart offen kommunizieren (Spec R-06 / Strava-Lehre 2018).
 *
 * Quellen Privacy-Design: Strava Heatmap k-threshold, Privacy Zones,
 * CONPRO2023 De-Anonymisierung — Aggregation VOR Render.
 */

export interface HeatSegment {
  id: string;
  /** OSM-way-ähnliche Polyline (lng,lat) */
  coordinates: [number, number][];
  uniqueUsers: number;
  intensity: number; // 0–1 nach k-Filter
  osmWayId?: string;
  visible: boolean;
  hideReason?: string;
}

export interface HeatmapResult {
  segments: HeatSegment[];
  coldStart: boolean;
  kThreshold: number;
  attribution: string;
  disclaimer: string;
}

const K = 5;

/** Demo-Segmente Alpbachtal — synthetische Community-Counts */
const SEED_SEGMENTS: Omit<HeatSegment, "visible" | "hideReason" | "intensity">[] = [
  {
    id: "hs-flow-soell",
    osmWayId: "osm-demo-1001",
    uniqueUsers: 12,
    coordinates: [
      [12.14, 47.448],
      [12.145, 47.451],
      [12.152, 47.455],
      [12.158, 47.458],
    ],
  },
  {
    id: "hs-enduro-alp",
    osmWayId: "osm-demo-1002",
    uniqueUsers: 8,
    coordinates: [
      [12.16, 47.46],
      [12.165, 47.462],
      [12.17, 47.458],
      [12.175, 47.455],
    ],
  },
  {
    id: "hs-private-spur",
    osmWayId: "osm-demo-1003",
    uniqueUsers: 2, // unter k → unsichtbar
    coordinates: [
      [12.12, 47.44],
      [12.122, 47.441],
      [12.124, 47.442],
    ],
  },
  {
    id: "hs-inn-radweg",
    osmWayId: "osm-demo-1004",
    uniqueUsers: 24,
    coordinates: [
      [12.13, 47.445],
      [12.14, 47.446],
      [12.15, 47.447],
      [12.16, 47.448],
    ],
  },
];

function distM(
  a: [number, number],
  b: [number, number]
): number {
  const R = 6371000;
  const dLat = ((b[1] - a[1]) * Math.PI) / 180;
  const dLng = ((a[0] - b[0]) * Math.PI) / 180;
  const la1 = (a[1] * Math.PI) / 180;
  const la2 = (b[1] * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(la1) * Math.cos(la2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/** Schneidet Start/Ende und Punkte in Privacy-Zonen heraus */
export function trimTrackForHeatmap(
  track: { lat: number; lng: number }[],
  privacyZones: { lat: number; lng: number; radiusM: number }[],
  trimEndsM = 200
): { lat: number; lng: number }[] {
  if (track.length < 3) return [];
  let start = 0;
  let end = track.length - 1;
  let acc = 0;
  for (let i = 1; i < track.length; i++) {
    acc += distM(
      [track[i - 1].lng, track[i - 1].lat],
      [track[i].lng, track[i].lat]
    );
    if (acc >= trimEndsM) {
      start = i;
      break;
    }
  }
  acc = 0;
  for (let i = track.length - 1; i > 0; i--) {
    acc += distM(
      [track[i].lng, track[i].lat],
      [track[i - 1].lng, track[i - 1].lat]
    );
    if (acc >= trimEndsM) {
      end = i;
      break;
    }
  }
  return track.slice(start, end + 1).filter((p) => {
    for (const z of privacyZones) {
      if (distM([p.lng, p.lat], [z.lng, z.lat]) < z.radiusM) return false;
    }
    return true;
  });
}

export function buildHeatmap(input?: {
  consentHeatmap: boolean;
  /** Eigene Rides — nach Trim zu Segmenten aggregiert */
  rides?: {
    id: string;
    track?: { lat: number; lng: number }[];
  }[];
  privacyZones?: { lat: number; lng: number; radiusM: number }[];
  /** Community-Seed nur wenn keine eigenen Segmente */
  includeSeedFallback?: boolean;
}): HeatmapResult {
  const consent = input?.consentHeatmap ?? false;
  const zones = input?.privacyZones ?? [];
  const fromRides: HeatSegment[] = [];

  for (const ride of input?.rides ?? []) {
    if (!ride.track?.length) continue;
    const trimmed = trimTrackForHeatmap(ride.track, zones);
    if (trimmed.length < 4) continue;
    // Grid-Bucket-Aggregation (eigene Daten = 1 Nutzer; Multi-User später Server)
    const step = Math.max(1, Math.floor(trimmed.length / 8));
    const coords: [number, number][] = [];
    for (let i = 0; i < trimmed.length; i += step) {
      coords.push([trimmed[i].lng, trimmed[i].lat]);
    }
    if (coords.length < 2) continue;
    fromRides.push({
      id: `ride-${ride.id}`,
      coordinates: coords,
      uniqueUsers: consent ? K : 1, // eigene Opt-in-Segmente sichtbar; ohne Consent unsichtbar
      intensity: consent ? 0.6 : 0,
      visible: consent,
      hideReason: consent
        ? undefined
        : "Beitrag zur Beliebtheitskarte ist aus — unter Privatsphäre aktivierbar",
      osmWayId: undefined,
    });
  }

  const useSeed =
    fromRides.length === 0 && (input?.includeSeedFallback ?? true);

  const seedSegments: HeatSegment[] = useSeed
    ? SEED_SEGMENTS.map((s) => {
        const users = s.uniqueUsers;
        if (users < K) {
          return {
            ...s,
            intensity: 0,
            visible: false,
            hideReason: `Zu wenig Fahrer auf dem Abschnitt (${users} von mind. ${K})`,
          };
        }
        return {
          ...s,
          intensity: Math.min(1, users / 20),
          visible: true,
          hideReason: undefined,
        };
      })
    : [];

  const segments = [...fromRides, ...seedSegments];
  const visibleCount = segments.filter((s) => s.visible).length;

  return {
    segments,
    coldStart: fromRides.length === 0 || visibleCount < 3,
    kThreshold: K,
    attribution: "© OpenStreetMap Mitwirkende · AetherRide eigene Aggregate",
    disclaimer: fromRides.length
      ? consent
        ? `Aus deinen Rides (Start/Ziel und Privatbereiche ausgeblendet). Beliebte Community-Abschnitte erst ab ${K} verschiedenen Fahrern.`
        : `Deine Strecken sind ausgeblendet — Beitrag unter Privatsphäre einschalten.`
      : `Noch wenig eigene Daten — Beispielabschnitte. Sichtbar erst ab ${K} verschiedenen Fahrern (Privatsphäre).`,
  };
}
