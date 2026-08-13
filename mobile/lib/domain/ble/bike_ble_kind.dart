import 'watch_candidate.dart';

/// What we can honestly say about a BLE advertisement from a bike / drive.
enum BikeBleKind {
  bosch,
  shimano,
  yamaha,
  csc,
  power,
  otherDrive,
}

enum BikeBleCap {
  csc,
  power,
  battery,
  heartRate,
  /// Identified proprietary drive (Bosch LDI / Shimano E-TUBE). Not decoded.
  proprietaryDrive,
}

/// Rank for pairing UI: drives first, then wheel sensors.
int bikeBleRank(BikeBleKind kind) => switch (kind) {
      BikeBleKind.bosch => 50,
      BikeBleKind.shimano => 50,
      BikeBleKind.yamaha => 40,
      BikeBleKind.otherDrive => 40,
      BikeBleKind.csc => 30,
      BikeBleKind.power => 20,
    };

String bikeBleKindLabel(BikeBleKind kind) => switch (kind) {
      BikeBleKind.bosch => 'Bosch',
      BikeBleKind.shimano => 'Shimano',
      BikeBleKind.yamaha => 'Yamaha',
      BikeBleKind.csc => 'Radsensor',
      BikeBleKind.power => 'Powermeter',
      BikeBleKind.otherDrive => 'E-Antrieb',
    };

String bikeBleKindHint(BikeBleKind kind) => switch (kind) {
      BikeBleKind.bosch =>
        'Smart System erkannt. Akku/Assist nur mit Standard-GATT oder offiziellem LDI — nichts erfinden.',
      BikeBleKind.shimano =>
        'STEPS / E-TUBE erkannt. Live-Daten nur, wenn das Display Standard-Services anbietet.',
      BikeBleKind.yamaha =>
        'Yamaha PW erkannt. Tempo/Kadenz über CSC, wenn das System sie sendet.',
      BikeBleKind.csc => 'Tempo und Trittfrequenz (CSC 0x1816).',
      BikeBleKind.power => 'Leistung (Cycling Power 0x1818).',
      BikeBleKind.otherDrive =>
        'E-Antrieb erkannt. Kein erfundenes SoC.',
    };

/// Robert Bosch GmbH 16-bit member service UUIDs (Bluetooth SIG Assigned Numbers).
const kBoschMemberServiceNeedles = <String>['fe02', 'fde8'];

/// Bosch eBike 128-bit base used by Smart System / Flow / LDI contract.
const kBoschEbikeUuidNeedle = 'eaa2-11e9-81b4-2a2ae2dbcce4';

const kBoschNameHints = <String>[
  'smart system',
  'bosch',
  'kiox',
  'nyon',
  'purion',
  'intuvia',
  'bes3',
];

const kShimanoNameHints = <String>[
  'shimano',
  'steps',
  'e-tube',
  'etube',
  'sc-e',
  'sc-en',
  'sc-em',
  'ep8',
  'ep801',
  'ep6',
  'du-e',
  'ew-en',
  'sm-btr',
  'sw-e',
];

const kYamahaNameHints = <String>[
  'yamaha',
  'pw-x',
  'pw-st',
  'pwseries',
  'pw series',
];

const kOtherDriveNameHints = <String>[
  'brose',
  'fazua',
  'specialized sl',
  'sl 1.2',
  'giant syncdrive',
  'syncdrive',
  'tq hpr',
  'bafang',
  'e-bike',
];

const kCscNameHints = <String>[
  'cadence',
  'speed',
  'csc',
  'wahoo',
  'magene',
  'coospo',
  'igpsport',
  'bryton',
  'sigma',
  'bontrager',
];

const kPowerNameHints = <String>[
  'stages',
  'quarq',
  'assioma',
  'favero',
  '4iiii',
  'rally',
  'vector',
  'power',
  'kickr',
];

const kNotBikeNameHints = <String>[
  'airpods',
  'galaxy buds',
  'buds pro',
  'headset',
  'headphone',
  'jabra',
  'wh-1000',
  'sony wh',
  'chromecast',
  'mi band',
  'tv ',
];

class BikeBleScanHit {
  const BikeBleScanHit({
    required this.deviceId,
    required this.name,
    required this.kind,
    required this.rssi,
    required this.caps,
    this.connectable = true,
  });

  final String deviceId;
  final String name;
  final BikeBleKind kind;
  final int rssi;
  final Set<BikeBleCap> caps;
  final bool connectable;

  String get displayName =>
      name.trim().isEmpty ? bikeBleKindLabel(kind) : name.trim();

  BikeBleScanHit copyWith({int? rssi, Set<BikeBleCap>? caps}) => BikeBleScanHit(
        deviceId: deviceId,
        name: name,
        kind: kind,
        rssi: rssi ?? this.rssi,
        caps: caps ?? this.caps,
        connectable: connectable,
      );
}

bool _uuidHas(Iterable<String> uuids, String needle) {
  final n = needle.toLowerCase();
  return uuids.any((u) => u.toLowerCase().contains(n));
}

bool advertisesCsc(Iterable<String> uuids) => _uuidHas(uuids, '1816');

bool advertisesPower(Iterable<String> uuids) => _uuidHas(uuids, '1818');

bool advertisesBattery(Iterable<String> uuids) => _uuidHas(uuids, '180f');

bool advertisesBoschEbike(Iterable<String> uuids) {
  return uuids.any((u) {
    final s = u.toLowerCase();
    if (s.contains(kBoschEbikeUuidNeedle)) return true;
    return kBoschMemberServiceNeedles.any(s.contains);
  });
}

bool nameLooksLikeBosch(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kBoschNameHints.any(n.contains);
}

bool nameLooksLikeShimano(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kShimanoNameHints.any(n.contains);
}

bool nameLooksLikeYamaha(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kYamahaNameHints.any(n.contains);
}

bool nameLooksLikeOtherDrive(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kOtherDriveNameHints.any(n.contains);
}

bool nameLooksLikeCsc(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kCscNameHints.any(n.contains);
}

bool nameLooksLikePower(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kPowerNameHints.any(n.contains);
}

bool nameLooksLikeNotBike(String platformName) {
  final n = platformName.trim().toLowerCase();
  if (n.isEmpty) return false;
  return kNotBikeNameHints.any(n.contains);
}

Set<BikeBleCap> bikeBleCapsFromUuids(Iterable<String> uuids) {
  return {
    if (advertisesCsc(uuids)) BikeBleCap.csc,
    if (advertisesPower(uuids)) BikeBleCap.power,
    if (advertisesBattery(uuids)) BikeBleCap.battery,
    if (advertisesHeartRateService(uuids)) BikeBleCap.heartRate,
    if (advertisesBoschEbike(uuids)) BikeBleCap.proprietaryDrive,
  };
}

/// Classify a BLE advertisement. Null = not a bike / drive / wheel sensor.
BikeBleKind? classifyBikeBle({
  required String platformName,
  required Iterable<String> advertisedServiceUuids,
}) {
  if (nameLooksLikeNotBike(platformName)) return null;

  final uuids = advertisedServiceUuids;
  final bosch = nameLooksLikeBosch(platformName) || advertisesBoschEbike(uuids);
  if (bosch) return BikeBleKind.bosch;
  if (nameLooksLikeShimano(platformName)) return BikeBleKind.shimano;
  if (nameLooksLikeYamaha(platformName)) return BikeBleKind.yamaha;
  if (nameLooksLikeOtherDrive(platformName)) return BikeBleKind.otherDrive;

  if (advertisesCsc(uuids) || nameLooksLikeCsc(platformName)) {
    return BikeBleKind.csc;
  }
  if (advertisesPower(uuids) || nameLooksLikePower(platformName)) {
    return BikeBleKind.power;
  }

  final n = platformName.trim().toLowerCase();
  if (n == 'ebike' || n.startsWith('ebike ')) {
    return BikeBleKind.otherDrive;
  }

  if (isWatchCandidate(
    platformName: platformName,
    advertisedServiceUuids: uuids,
  )) {
    return null;
  }

  return null;
}

bool isBikeBleCandidate({
  required String platformName,
  required Iterable<String> advertisedServiceUuids,
}) {
  return classifyBikeBle(
        platformName: platformName,
        advertisedServiceUuids: advertisedServiceUuids,
      ) !=
      null;
}

BikeBleKind? bikeBleKindFromStorage(String? raw) {
  switch (raw) {
    case 'bosch':
      return BikeBleKind.bosch;
    case 'shimano':
      return BikeBleKind.shimano;
    case 'yamaha':
      return BikeBleKind.yamaha;
    case 'csc':
      return BikeBleKind.csc;
    case 'power':
      return BikeBleKind.power;
    case 'otherDrive':
      return BikeBleKind.otherDrive;
    default:
      return null;
  }
}

String bikeBleKindToStorage(BikeBleKind kind) => kind.name;

bool bikeBleKindIsDrive(BikeBleKind kind) => switch (kind) {
      BikeBleKind.bosch ||
      BikeBleKind.shimano ||
      BikeBleKind.yamaha ||
      BikeBleKind.otherDrive =>
        true,
      BikeBleKind.csc || BikeBleKind.power => false,
    };
