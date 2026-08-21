/// Zeiger: Offline-Pack für die GPS-Region fehlt oder liegt bereit.
class HofPackHint {
  const HofPackHint({
    required this.regionId,
    required this.regionName,
    this.ready = false,
  });

  final String regionId;
  final String regionName;

  /// Graph deckt den Standort. Kein Download-CTA.
  final bool ready;
}

/// Ready Katalog-Pack zuerst. Overlay nur wenn der Katalog nichts liefert.
/// Liegt ein Pack bereit, Statuszeile statt Download.
HofPackHint? hofHintForLocation({
  required String? overlayId,
  required String? overlayName,
  required bool overlayIsEnvelope,
  required String? suggestedId,
  required String? suggestedName,
  required bool packReady,
  String? readyId,
  String? readyName,
}) {
  if (packReady) {
    return hofReadyPack(regionId: readyId, regionName: readyName);
  }
  final fromCatalog = hofMissingPack(
    regionId: suggestedId,
    regionName: suggestedName,
    packReady: false,
  );
  if (fromCatalog != null) return fromCatalog;
  if (overlayIsEnvelope) return null;
  return hofMissingPack(
    regionId: overlayId,
    regionName: overlayName,
    packReady: false,
  );
}

/// Aktiviertes Pack mit Namen — sonst still (kein leerer Chip).
HofPackHint? hofReadyPack({
  required String? regionId,
  required String? regionName,
}) {
  final id = regionId?.trim();
  final name = regionName?.trim();
  if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
  return HofPackHint(regionId: id, regionName: name, ready: true);
}

/// Nur wenn die Region bekannt, kein Envelope-Stub und kein Pack bereitliegt.
HofPackHint? hofMissingPack({
  required String? regionId,
  required String? regionName,
  required bool packReady,
  bool isEnvelope = false,
}) {
  if (packReady || isEnvelope) return null;
  final id = regionId?.trim();
  final name = regionName?.trim();
  if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
  return HofPackHint(regionId: id, regionName: name);
}
