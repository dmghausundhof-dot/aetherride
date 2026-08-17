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
        'Smart System erkannt. SoC über LDI (Flow → Komponenten, Firmware ≥19) oder Standard-GATT — nichts erfinden.',
      BikeBleKind.shimano =>
        'STEPS / E-TUBE erkannt. Live-Daten nur, wenn das Display Standard-Services anbietet.',
      BikeBleKind.yamaha =>
        'Yamaha PW erkannt. Tempo/Kadenz über CSC, wenn das System sie sendet.',
      BikeBleKind.csc => 'Tempo und Trittfrequenz (CSC 0x1816).',
      BikeBleKind.power => 'Leistung (Cycling Power 0x1818).',
      BikeBleKind.otherDrive =>
        'E-Antrieb erkannt. Kein erfundenes SoC.',
    };

/// One-line action on a scan row — how to connect, not capability legal copy.
String bikeBleConnectTip(BikeBleKind kind) => switch (kind) {
      BikeBleKind.bosch =>
        'Flow: Komponenten → FlowLine hinzufügen · Firmware ≥19',
      BikeBleKind.shimano =>
        'E-TUBE schließen · in 15 s nach Power/Taster tippen',
      BikeBleKind.yamaha =>
        'e-Sync schließen · Tempo über CSC-Sensor',
      BikeBleKind.otherDrive =>
        'Hersteller-App schließen · Display an, nah halten',
      BikeBleKind.csc => 'Sensor am Rad wecken, nah halten',
      BikeBleKind.power => 'Powermeter einschalten, nah halten',
    };

String bikeBlePairLead({required bool isEbike}) => isEbike
    ? 'Display an, Hersteller-App zu, Handy nah — dann antippen.'
    : 'Sensor am Rad wecken, nicht die Uhr am Handgelenk.';

class BikeBleConnectNote {
  const BikeBleConnectNote({required this.brand, required this.line});

  final String brand;
  final String line;
}

/// Compact pairing notes for the sheet. Ebike: makers first, sensor last.
List<BikeBleConnectNote> bikeBleConnectNotes({required bool isEbike}) {
  if (!isEbike) {
    return const [
      BikeBleConnectNote(
        brand: 'Sensor',
        line: 'Magnet oder Kurbel, nah an den Sensor — nicht die Uhr.',
      ),
    ];
  }
  return const [
    BikeBleConnectNote(
      brand: 'Bosch',
      line: 'SoC: Flow öffnen → Komponenten → FlowLine hinzufügen (Steuerung ≥19). CSC weiter über die Liste.',
    ),
    BikeBleConnectNote(
      brand: 'Shimano',
      line: 'E-TUBE schließen. Nach Power oder Taster oft nur 15 s — dann tippen.',
    ),
    BikeBleConnectNote(
      brand: 'Yamaha / TQ',
      line: 'e-Sync bzw. TQ-App zu. Live-Tempo meist nur über CSC-Sensor.',
    ),
    BikeBleConnectNote(
      brand: 'Fazua',
      line: 'Remote an — CSC und Power wie ein normaler Sensor.',
    ),
    BikeBleConnectNote(
      brand: 'Andere',
      line: 'RideControl / Mission Control schließen. Ein Phone, Display an.',
    ),
  ];
}

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
  'shimano steps',
  'shimano',
  'steps e',
  'steps',
  'e-tube',
  'etube',
  'sc-e6100',
  'sc-e7000',
  'sc-e8000',
  'sc-em800',
  'sc-en600',
  'sc-e',
  'sc-en',
  'sc-em',
  'du-e8000',
  'du-ep800',
  'du-ep801',
  'du-ep600',
  'du-e',
  'ep801',
  'ep8',
  'ep6',
  'ew-en100',
  'ew-en101',
  'ew-en',
  'sm-btr1',
  'sm-btr2',
  'sm-btr',
  'sw-e',
];

/// Android GATT_CONN_FAILED_ESTABLISHMENT — often Flow/E-TUBE already holding the link.
const kGattConnFailedEstablishment = 133;

/// Android GATT_CONNECTION_TIMEOUT (0x93). Distinct from supervision timeout 8.
const kGattConnectionTimeout = 147;

/// HCI / Android GATT supervision timeout — Intuvia drops untrusted Centrals ~8 s.
const kGattSupervisionTimeout = 8;

/// GATT_INSUF_AUTHENTICATION — encrypted characteristic without a bond.
const kGattInsufficientAuthentication = 5;

/// HCI Remote User Terminated Connection.
const kGattRemoteUserTerminated = 19;

/// flutter_blue_plus [FbpErrorCode.timeout] — our connect() deadline fired.
const kFbpConnectTimeoutCode = 1;

const kBleReconnectDelaysSec = [5, 15, 30];
const kBleReconnectMaxOutsideRide = 4;
const kBleReconnectMaxDuringRide = 8;

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

Set<BikeBleCap> bikeBleCapsFromUuids(
  Iterable<String> uuids, {
  String platformName = '',
}) {
  return {
    if (advertisesCsc(uuids)) BikeBleCap.csc,
    if (advertisesPower(uuids)) BikeBleCap.power,
    if (advertisesBattery(uuids)) BikeBleCap.battery,
    if (advertisesHeartRateService(uuids)) BikeBleCap.heartRate,
    if (advertisesBoschEbike(uuids) ||
        nameLooksLikeBosch(platformName) ||
        nameLooksLikeShimano(platformName))
      BikeBleCap.proprietaryDrive,
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

/// Identität darf gemerkt werden (Drive ohne GATT, opt-in „Trotzdem merken“).
/// Das Pair-Sheet poppt damit NICHT — dafür [blePairSheetSuccess] / `ok`.
bool blePairAccepted({
  required bool connected,
  required BikeBleKind kind,
}) {
  if (connected) return true;
  return bikeBleKindIsDrive(kind);
}

/// CSC/Power brauchen GATT. Drive darf Identität ohne GATT merken (nicht default).
bool blePairGattRequired(BikeBleKind kind) => !bikeBleKindIsDrive(kind);

/// Ride auto-connect (`scanIfMissing`): Drive-MAC nicht 2×14 s GATT-retrien.
/// Pair-Sheet nutzt `scanIfMissing: false` und darf Display-GATT weiter versuchen.
bool bleSkipPreferredDriveGatt({
  required bool scanIfMissing,
  BikeBleKind? kindHint,
}) {
  if (!scanIfMissing) return false;
  return kindHint != null && bikeBleKindIsDrive(kindHint);
}

/// Pair-Sheet schließt nur bei echter GATT-Verbindung.
bool blePairSheetSuccess({required bool connected}) => connected;

/// CSC, Power oder echter SoC — nicht bloß eine Drive-MAC im GATT.
bool bleHasLiveBikeMetrics({
  required bool hasCscNotify,
  required bool hasPowerNotify,
  required bool hasSoc,
  bool ldiConnected = false,
}) {
  return hasCscNotify || hasPowerNotify || hasSoc || ldiConnected;
}

/// Display erkannt, aber kein Tempo/Watt/Akku. Nicht als „Sensor wach“ zeigen.
bool bleDriveWithoutLiveMetrics({
  required bool connected,
  required BikeBleKind? kind,
  required bool hasCscNotify,
  required bool hasPowerNotify,
  required bool hasSoc,
  bool ldiConnected = false,
}) {
  if (!connected) return false;
  if (kind == null || !bikeBleKindIsDrive(kind)) return false;
  return !bleHasLiveBikeMetrics(
    hasCscNotify: hasCscNotify,
    hasPowerNotify: hasPowerNotify,
    hasSoc: hasSoc,
    ldiConnected: ldiConnected,
  );
}

bool bleIsUntrustedDrop(int? code) {
  if (code == null) return false;
  return code == kGattSupervisionTimeout ||
      code == kGattInsufficientAuthentication ||
      code == kGattRemoteUserTerminated;
}

/// Drive without OS-bond: status 8 is the Intuvia “untrusted client” drop.
/// Reconnecting spams the radio and never yields SoC. CSC still reconnects.
bool bleShouldReconnectAfterDrop({
  required BikeBleKind? kind,
  required int? disconnectCode,
  required bool bonded,
}) {
  if (kind != null &&
      bikeBleKindIsDrive(kind) &&
      bleIsUntrustedDrop(disconnectCode) &&
      !bonded) {
    return false;
  }
  return true;
}

bool isTransientGattError(int? code) {
  if (code == null) return false;
  return code == kGattConnFailedEstablishment ||
      code == kGattConnectionTimeout ||
      code == kFbpConnectTimeoutCode;
}

String bleGattStatusHint(int? code) {
  if (code == kGattConnFailedEstablishment) {
    return 'Verbindung abgelehnt — Bosch Flow / Shimano E-TUBE schließen, '
        'Display an, nah halten.';
  }
  if (code == kGattConnectionTimeout || code == kFbpConnectTimeoutCode) {
    return 'Timeout — Display wecken, 15s-Fenster (Shimano), näher rangehen.';
  }
  if (bleIsUntrustedDrop(code)) {
    return 'Display braucht Bluetooth-Kopplung für den Akku.';
  }
  return 'Verbindung fehlgeschlagen';
}

int? parseGattErrorCode(Object error) {
  if (error is int) return error;
  final m = RegExp(r'(?:android-code|fbp-code|code):\s*(-?\d+)').firstMatch('$error');
  return m == null ? null : int.tryParse(m.group(1)!);
}

Duration bleReconnectDelay(int attemptIndex) {
  final i = attemptIndex.clamp(0, kBleReconnectDelaysSec.length - 1);
  return Duration(seconds: kBleReconnectDelaysSec[i]);
}

String blePairDeviceId({
  String? lastRemoteId,
  required String scanDeviceId,
}) {
  if (lastRemoteId != null && lastRemoteId.isNotEmpty) return lastRemoteId;
  return scanDeviceId;
}
