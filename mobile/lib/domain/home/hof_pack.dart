/// Zeiger: Offline-Pack für die GPS-Region fehlt. Kein Download auf dem Hof.
class HofPackHint {
  const HofPackHint({required this.regionId, required this.regionName});

  final String regionId;
  final String regionName;
}

/// Nur wenn die Region bekannt ist und kein Pack bereitliegt.
HofPackHint? hofMissingPack({
  required String? regionId,
  required String? regionName,
  required bool packReady,
}) {
  if (packReady) return null;
  final id = regionId?.trim();
  final name = regionName?.trim();
  if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
  return HofPackHint(regionId: id, regionName: name);
}
