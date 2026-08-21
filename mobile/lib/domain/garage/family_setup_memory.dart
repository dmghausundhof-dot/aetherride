/// Leaving "Ich": remember the live setup so coming back does not keep the kid's.
String? snapshotOwnSetup({
  required String? activeRiderId,
  String? currentSetupId,
}) {
  if (activeRiderId != null) return null;
  return currentSetupId;
}

/// Which setup becomes current after tapping Ich or a family chip.
String? setupToApplyOnFamilySwitch({
  required String? nextRiderId,
  String? rememberedOwnId,
  required List<String> nextRiderSetupIds,
  required Iterable<String> existingSetupIds,
  required Iterable<String> familyOwnedSetupIds,
  String? currentSetupId,
}) {
  final existing = existingSetupIds.toSet();
  if (nextRiderId == null) {
    if (rememberedOwnId != null && existing.contains(rememberedOwnId)) {
      return rememberedOwnId;
    }
    final familyOwned = familyOwnedSetupIds.toSet();
    if (currentSetupId != null &&
        existing.contains(currentSetupId) &&
        !familyOwned.contains(currentSetupId)) {
      return currentSetupId;
    }
    for (final id in existingSetupIds) {
      if (!familyOwned.contains(id)) return id;
    }
    return null;
  }
  for (final id in nextRiderSetupIds) {
    if (existing.contains(id)) return id;
  }
  return null;
}
