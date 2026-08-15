/** Einzel-Tour-Freigabe. Geometrie nur wenn includeTrack — nie still. */

export type SharedTourPayload = {
  v: 1;
  kind: "tour";
  id: string;
  name: string;
  distanceKm: number;
  elevationM: number;
  durationMin: number;
  source: string;
  catalogTourId?: string;
  includeTrack: boolean;
  /** LineString-Koordinaten [lng, lat], nur bei includeTrack. */
  track?: [number, number][];
  authorLabel: string;
  createdAt: string;
  /** Zum lokalen Widerruf: Token älter als revoked epoch ist ungültig. */
  epoch?: number;
};
