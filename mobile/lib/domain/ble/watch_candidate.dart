/// Name hints for watches / HR wearables that may omit 0x180D in advertisements.
const kWatchNameHints = <String>[
  'polar',
  'garmin',
  'samsung',
  'galaxy',
  'ticwatch',
  'amazfit',
  'coros',
  'suunto',
  'apple',
  'watch',
  'fenix',
  'venu',
  'forerunner',
  'ignite',
  'vantage',
  'charge',
  'versa',
  'sense',
];

bool advertisesHeartRateService(Iterable<String> advertisedServiceUuids) {
  return advertisedServiceUuids.any(
    (u) => u.toLowerCase().contains('180d'),
  );
}

bool nameLooksLikeWatch(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kWatchNameHints.any(n.contains);
}

/// True if the advertisement is a Heart Rate device (0x180D) or a watch-like name.
/// Vendor-only UUIDs without a matching name are not candidates — connect may
/// still be attempted from a user-picked saved id.
bool isWatchCandidate({
  required String platformName,
  required Iterable<String> advertisedServiceUuids,
}) {
  if (advertisesHeartRateService(advertisedServiceUuids)) return true;
  return nameLooksLikeWatch(platformName);
}
