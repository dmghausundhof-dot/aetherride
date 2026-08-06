/**
 * F-ACC-007 Familien-/Mehrfahrer-Garage
 * Ein Bike, mehrere Fahrer mit eigenen Setups.
 */

export interface FamilyRider {
  id: string;
  displayName: string;
  weightKg: number;
  /** Setup-IDs die diesem Fahrer gehören */
  setupIds: string[];
  notes?: string;
}

export function createFamilyRider(
  name: string,
  weightKg: number
): FamilyRider {
  return {
    id: `rider-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    displayName: name,
    weightKg,
    setupIds: [],
  };
}
