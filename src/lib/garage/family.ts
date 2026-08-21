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

/** Leaving "Ich": remember the live setup so coming back does not keep the kid's. */
export function snapshotOwnSetup(input: {
  activeRiderId: string | null;
  currentSetupId?: string;
}): string | undefined {
  if (input.activeRiderId) return undefined;
  return input.currentSetupId;
}

/** Which setup becomes current after tapping Ich or a family chip. */
export function setupToApplyOnFamilySwitch(input: {
  nextRiderId: string | null;
  rememberedOwnId?: string;
  nextRiderSetupIds: string[];
  existingSetupIds: string[];
  familyOwnedSetupIds: string[];
  currentSetupId?: string;
}): string | undefined {
  const existing = new Set(input.existingSetupIds);
  if (input.nextRiderId == null) {
    if (input.rememberedOwnId && existing.has(input.rememberedOwnId)) {
      return input.rememberedOwnId;
    }
    const familyOwned = new Set(input.familyOwnedSetupIds);
    if (
      input.currentSetupId &&
      existing.has(input.currentSetupId) &&
      !familyOwned.has(input.currentSetupId)
    ) {
      return input.currentSetupId;
    }
    return input.existingSetupIds.find((id) => !familyOwned.has(id));
  }
  return input.nextRiderSetupIds.find((id) => existing.has(id));
}
