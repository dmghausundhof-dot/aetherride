/// Name hints and honesty for watches / HR straps (Heart Rate 0x180D).
/// Keep tokens tight — `galaxy`/`watch`/`charge` match buds, TVs, Powerbeats.
const kWatchNameHints = <String>[
  'polar',
  'tickr',
  'wahoo tickr',
  'garmin',
  'fenix',
  'venu',
  'forerunner',
  'instinct',
  'epix',
  'vivoactive',
  'amazfit',
  'coros',
  'suunto',
  'ticwatch',
  'galaxy watch',
  'apple watch',
  'fitbit',
  'whoop',
  'ignite',
  'vantage',
  'oh1',
  'verity',
  'h10',
  'h9 ',
  'h7 ',
  'hr-9',
  'hr9',
];

const kNotWatchNameHints = <String>[
  'airpods',
  'galaxy buds',
  'buds pro',
  'headset',
  'headphone',
  'powerbeats',
  'chromecast',
  'tv ',
];

enum WatchHonesty {
  /// Polar / Wahoo TICKR / many straps: standard Heart Rate 0x180D.
  hrBroadcast,
  /// Garmin: HR only if “Broadcast heart rate” (or similar) is on.
  garminNeedsBroadcast,
  /// Apple Watch does not expose standard BLE HR to Android third-party apps.
  appleUnsupported,
  /// Galaxy Watch: typically Samsung Health, not 0x180D.
  galaxyLimited,
  unknown,
}

bool advertisesHeartRateService(Iterable<String> advertisedServiceUuids) {
  return advertisedServiceUuids.any(
    (u) => u.toLowerCase().contains('180d'),
  );
}

bool nameLooksLikeNotWatch(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kNotWatchNameHints.any(n.contains);
}

bool nameLooksLikeWatch(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  if (nameLooksLikeNotWatch(n)) return false;
  return kWatchNameHints.any(n.contains);
}

WatchHonesty watchHonestyForName(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.contains('apple watch')) return WatchHonesty.appleUnsupported;
  if (n.contains('galaxy watch')) return WatchHonesty.galaxyLimited;
  if (n.contains('garmin') ||
      n.contains('fenix') ||
      n.contains('venu') ||
      n.contains('forerunner') ||
      n.contains('instinct') ||
      n.contains('epix') ||
      n.contains('vivoactive')) {
    return WatchHonesty.garminNeedsBroadcast;
  }
  if (n.contains('polar') ||
      n.contains('tickr') ||
      n.contains('h10') ||
      n.contains('wahoo')) {
    return WatchHonesty.hrBroadcast;
  }
  return WatchHonesty.unknown;
}

String watchHonestyLabel(WatchHonesty h) => switch (h) {
      WatchHonesty.hrBroadcast => 'Puls per Standard-BLE',
      WatchHonesty.garminNeedsBroadcast => 'Garmin: Broadcast-HR einschalten',
      WatchHonesty.appleUnsupported => 'Apple Watch: kein Standard-BLE-Puls',
      WatchHonesty.galaxyLimited => 'Galaxy: meist kein Standard-Puls',
      WatchHonesty.unknown => 'Nur mit sichtbarem Puls-Broadcast',
    };

String watchConnectTip(WatchHonesty h) => switch (h) {
      WatchHonesty.hrBroadcast => 'Sensor- oder Broadcast-Modus an, nah halten',
      WatchHonesty.garminNeedsBroadcast =>
        'In der Garmin-Uhr: Herzfrequenz senden / Broadcast',
      WatchHonesty.appleUnsupported =>
        'Kein BLE-Puls zu Android — HealthKit nur auf iPhone',
      WatchHonesty.galaxyLimited =>
        'Nur wenn die Uhr Puls per Bluetooth sendet — sonst Samsung Health',
      WatchHonesty.unknown => 'Puls-Broadcast an der Uhr muss aktiv sein',
    };

bool watchHonestyPairable(WatchHonesty h) => switch (h) {
      WatchHonesty.appleUnsupported => false,
      WatchHonesty.hrBroadcast ||
      WatchHonesty.garminNeedsBroadcast ||
      WatchHonesty.galaxyLimited ||
      WatchHonesty.unknown =>
        true,
    };

class WatchBleConnectNote {
  const WatchBleConnectNote({required this.brand, required this.line});

  final String brand;
  final String line;
}

List<WatchBleConnectNote> watchBleConnectNotes() => const [
      WatchBleConnectNote(
        brand: 'Polar / Gurt',
        line: 'Sensor-Modus an. Standard-Puls — das koppeln wir.',
      ),
      WatchBleConnectNote(
        brand: 'Garmin',
        line: 'Herzfrequenz senden / Broadcast in den Uhr-Einstellungen.',
      ),
      WatchBleConnectNote(
        brand: 'Apple Watch',
        line: 'Kein Standard-BLE-Puls zu Android. Nicht koppeln.',
      ),
      WatchBleConnectNote(
        brand: 'Galaxy',
        line: 'Meist nur Samsung Health. Nur mit sichtbarem Puls-Broadcast.',
      ),
    ];

String watchBlePairLead() =>
    'Puls am Fahrer, nicht am Rad. Nur ein echter Herzfrequenz-Sensor.';

/// True if the advertisement is a Heart Rate device or a watch-like name.
/// CSC/Power boxes are never watches, even if the brand says Garmin.
bool isWatchCandidate({
  required String platformName,
  required Iterable<String> advertisedServiceUuids,
}) {
  if (nameLooksLikeNotWatch(platformName)) return false;
  final uuids = advertisedServiceUuids;
  final hr = advertisesHeartRateService(uuids);
  final csc = uuids.any((u) => u.toLowerCase().contains('1816'));
  final power = uuids.any((u) => u.toLowerCase().contains('1818'));
  if (!hr && (csc || power)) {
    return false;
  }
  if (hr) return true;
  return nameLooksLikeWatch(platformName);
}

class WatchBleScanHit {
  const WatchBleScanHit({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.hasHrService,
    required this.honesty,
    this.connectable = true,
  });

  final String deviceId;
  final String name;
  final int rssi;
  final bool hasHrService;
  final WatchHonesty honesty;
  final bool connectable;

  String get displayName =>
      name.trim().isEmpty ? 'Herzfrequenz-Sensor' : name.trim();

  bool get pairable =>
      hasHrService ||
      (watchHonestyPairable(honesty) &&
          honesty != WatchHonesty.appleUnsupported);
}
