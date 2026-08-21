/// Zeiger: Offline-Pack für die GPS-Region fehlt, liegt bereit, oder
/// der Graph ist da — GPS aber außerhalb der Occupancy.
class HofPackHint {
  const HofPackHint({
    required this.regionId,
    required this.regionName,
    this.ready = false,
    this.outside = false,
  });

  final String regionId;
  final String regionName;

  /// Graph deckt den Standort. Kein Download-CTA.
  final bool ready;

  /// Pack liegt auf der Platte, GPS nicht im Graph-Ring. Kein Download.
  final bool outside;
}

/// Ready Katalog-Pack zuerst. Overlay nur wenn der Katalog nichts liefert.
/// Liegt ein Pack bereit, Statuszeile statt Download. Ist dasselbe Pack
/// schon installiert, aber GPS außerhalb der Occupancy: „Außerhalb“, nicht
/// noch einmal laden.
HofPackHint? hofHintForLocation({
  required String? overlayId,
  required String? overlayName,
  required bool overlayIsEnvelope,
  required String? suggestedId,
  required String? suggestedName,
  required bool packReady,
  String? readyId,
  String? readyName,
  Set<String> installedIds = const {},
}) {
  if (packReady) {
    return hofReadyPack(regionId: readyId, regionName: readyName);
  }
  final sugId = suggestedId?.trim();
  if (sugId != null && sugId.isNotEmpty && installedIds.contains(sugId)) {
    return hofOutsidePack(
      regionId: sugId,
      regionName: suggestedName ?? readyName ?? sugId,
    );
  }
  final fromCatalog = hofMissingPack(
    regionId: suggestedId,
    regionName: suggestedName,
    packReady: false,
  );
  if (fromCatalog != null) return fromCatalog;
  final act = readyId?.trim();
  if (act != null && act.isNotEmpty) {
    return hofOutsidePack(
      regionId: act,
      regionName: readyName,
    );
  }
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

/// Graph auf der Platte, Standort nicht in der Occupancy.
HofPackHint? hofOutsidePack({
  required String? regionId,
  required String? regionName,
}) {
  final id = regionId?.trim();
  final name = regionName?.trim();
  if (id == null || id.isEmpty || name == null || name.isEmpty) return null;
  return HofPackHint(regionId: id, regionName: name, outside: true);
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
