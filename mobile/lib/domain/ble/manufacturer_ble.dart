import 'bike_ble_kind.dart';
import 'watch_candidate.dart';

/// What an open manufacturer BLE surface can actually do in FlowLine.
enum ManufacturerBleOpenness {
  /// Bluetooth SIG or public spec — we decode live values.
  openDecodable,

  /// Advertisement / name only. No unofficial protocol.
  identityOnly,

  /// Public spec, native path incomplete on this OS.
  openPartial,
}

/// Live metrics we may emit — never invented when the source is missing.
enum ManufacturerBleMetric {
  speed,
  cadence,
  power,
  batterySoc,
  heartRate,
  odometer,
  light,
  lock,
  charger,
}

enum ManufacturerBleId {
  boschLdi,
  boschDisplay,
  shimanoSteps,
  yamaha,
  fazua,
  tq,
  brose,
  specialized,
  giant,
  mahle,
  bafang,
  esmOpen,
  sigCsc,
  sigPower,
  sigHeartRate,
  sigBattery,
}

class ManufacturerBleProfile {
  const ManufacturerBleProfile({
    required this.id,
    required this.brand,
    required this.protocol,
    required this.openness,
    required this.kind,
    required this.metrics,
    required this.androidLive,
    required this.iosLive,
    required this.connectMeaning,
    required this.forgetMeaning,
    required this.proofId,
  });

  final ManufacturerBleId id;
  final String brand;
  final String protocol;
  final ManufacturerBleOpenness openness;
  final BikeBleKind? kind;
  final Set<ManufacturerBleMetric> metrics;
  final bool androidLive;
  final bool iosLive;
  final String connectMeaning;
  final String forgetMeaning;

  /// Stable id referenced by proof tests.
  final String proofId;

  bool get decodesLive =>
      (openness == ManufacturerBleOpenness.openDecodable ||
          openness == ManufacturerBleOpenness.openPartial) &&
      (androidLive || iosLive);

  bool get inventsValues => false;
}

/// Single source of truth: what “connect” means per manufacturer.
///
/// Open = public spec or Bluetooth SIG. Closed OEM apps (E-TUBE, e-Sync,
/// Mission Control) are never reverse-engineered. ESM has no public e-bike
/// GATT spec — devices are handled as SIG services when they advertise them.
const kManufacturerBleProfiles = <ManufacturerBleProfile>[
  ManufacturerBleProfile(
    id: ManufacturerBleId.boschLdi,
    brand: 'Bosch',
    protocol: 'LDI V1.0 LiveData (eb20/eb21)',
    openness: ManufacturerBleOpenness.openDecodable,
    kind: BikeBleKind.bosch,
    metrics: {
      ManufacturerBleMetric.speed,
      ManufacturerBleMetric.cadence,
      ManufacturerBleMetric.power,
      ManufacturerBleMetric.batterySoc,
      ManufacturerBleMetric.odometer,
      ManufacturerBleMetric.light,
      ManufacturerBleMetric.lock,
      ManufacturerBleMetric.charger,
    },
    androidLive: true,
    iosLive: true,
    connectMeaning:
        'Phone is BLE accessory. Flow → Komponenten → FlowLine. '
        'Bike (firmware ≥19) connects as central; we subscribe to eb21.',
    forgetMeaning:
        'Drop ldi:bosch binding, stop accessory advertise, delete last id.',
    proofId: 'bosch-ldi-v1',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.boschDisplay,
    brand: 'Bosch',
    protocol: 'Intuvia / Kiox / Nyon advertisement',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.bosch,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning:
        'Display GATT without LDI is identity + optional 0x180F. '
        'SoC only after OS-bond. Speed still needs CSC or LDI.',
    forgetMeaning: 'Clear drive slot. Do not invent remaining SoC.',
    proofId: 'bosch-display-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.shimanoSteps,
    brand: 'Shimano',
    protocol: 'STEPS / E-TUBE name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.shimano,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning:
        'Name match (SC-E…, EP8, E-TUBE). Close E-TUBE. No unofficial '
        'E-TUBE decode. Tempo only via a wheel CSC.',
    forgetMeaning: 'Clear drive identity. Never stored Shimano motor frames.',
    proofId: 'shimano-identity-only',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.yamaha,
    brand: 'Yamaha',
    protocol: 'PW / e-Sync name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.yamaha,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning: 'PW series seen. e-Sync closed. Live speed via CSC.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'yamaha-identity-only',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.fazua,
    brand: 'Fazua',
    protocol: 'Ride 60 / name + SIG sensors',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.otherDrive,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning:
        'Drive identity. Tempo/power only if the remote exposes CSC/Power.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'fazua-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.tq,
    brand: 'TQ',
    protocol: 'HPR name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.otherDrive,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning: 'TQ-App closed. Live speed via CSC.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'tq-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.brose,
    brand: 'Brose',
    protocol: 'Name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.otherDrive,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning: 'Hersteller-App closed. Live speed via CSC.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'brose-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.specialized,
    brand: 'Specialized',
    protocol: 'SL / Mission Control name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.otherDrive,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning: 'Mission Control closed. Live speed via CSC.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'specialized-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.giant,
    brand: 'Giant',
    protocol: 'SyncDrive / RideControl name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.otherDrive,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning: 'RideControl closed. Live speed via CSC.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'giant-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.mahle,
    brand: 'Mahle',
    protocol: 'X20 / ebikemotion name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.otherDrive,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning: 'Hersteller-App closed. Live speed via CSC.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'mahle-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.bafang,
    brand: 'Bafang',
    protocol: 'Name detection',
    openness: ManufacturerBleOpenness.identityOnly,
    kind: BikeBleKind.otherDrive,
    metrics: {},
    androidLive: false,
    iosLive: false,
    connectMeaning: 'Display an. Live speed via CSC if advertised.',
    forgetMeaning: 'Clear drive identity.',
    proofId: 'bafang-identity',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.esmOpen,
    brand: 'ESM / andere offene OEM',
    protocol: 'Bluetooth SIG 0x1816 / 0x1818 / 0x180D / 0x180F',
    openness: ManufacturerBleOpenness.openDecodable,
    kind: null,
    metrics: {
      ManufacturerBleMetric.speed,
      ManufacturerBleMetric.cadence,
      ManufacturerBleMetric.power,
      ManufacturerBleMetric.batterySoc,
      ManufacturerBleMetric.heartRate,
    },
    androidLive: true,
    iosLive: true,
    connectMeaning:
        'Kein öffentliches ESM-Antriebsprotokoll. Gerät wird gekoppelt, '
        'wenn es Standard-GATT sendet — gleiche Parser wie CSC/Power/HR.',
    forgetMeaning: 'Clear wheel/watch ids. No OEM frame store.',
    proofId: 'esm-open-sig',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.sigCsc,
    brand: 'SIG CSC',
    protocol: '0x1816 / 0x2A5B',
    openness: ManufacturerBleOpenness.openDecodable,
    kind: BikeBleKind.csc,
    metrics: {
      ManufacturerBleMetric.speed,
      ManufacturerBleMetric.cadence,
    },
    androidLive: true,
    iosLive: true,
    connectMeaning:
        'Werkstatt-Picker oder Ride auto-connect. Wheel → speed, crank → RPM.',
    forgetMeaning: 'Remove wheel slot + ble_last_csc_id.txt.',
    proofId: 'sig-csc',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.sigPower,
    brand: 'SIG Cycling Power',
    protocol: '0x1818 / 0x2A63',
    openness: ManufacturerBleOpenness.openDecodable,
    kind: BikeBleKind.power,
    metrics: {ManufacturerBleMetric.power},
    androidLive: true,
    iosLive: true,
    connectMeaning: 'Powermeter notify. Watts never synthesized from cadence.',
    forgetMeaning: 'Remove wheel/power slot.',
    proofId: 'sig-power',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.sigHeartRate,
    brand: 'SIG Heart Rate',
    protocol: '0x180D / 0x2A37',
    openness: ManufacturerBleOpenness.openDecodable,
    kind: null,
    metrics: {ManufacturerBleMetric.heartRate},
    androidLive: true,
    iosLive: true,
    connectMeaning:
        'Hof-Picker. Nur echtes HR-Notify. Apple Watch ohne 180D blockiert.',
    forgetMeaning: 'Delete watch_ble_device.json + ble_last_watch_id.txt.',
    proofId: 'sig-hr',
  ),
  ManufacturerBleProfile(
    id: ManufacturerBleId.sigBattery,
    brand: 'SIG Battery',
    protocol: '0x180F / 0x2A19',
    openness: ManufacturerBleOpenness.openDecodable,
    kind: null,
    metrics: {ManufacturerBleMetric.batterySoc},
    androidLive: true,
    iosLive: true,
    connectMeaning:
        'Read/notify 0–100 %. Watch battery never copied onto bike SoC.',
    forgetMeaning: 'SoC cleared on disconnect. Not persisted as OEM dump.',
    proofId: 'sig-battery',
  ),
];

ManufacturerBleProfile? manufacturerBleByProofId(String proofId) {
  for (final p in kManufacturerBleProfiles) {
    if (p.proofId == proofId) return p;
  }
  return null;
}

List<ManufacturerBleProfile> manufacturerBleForKind(BikeBleKind kind) {
  return [
    for (final p in kManufacturerBleProfiles)
      if (p.kind == kind) p,
  ];
}

/// Drive kinds that must never invent SoC / watts / assist from a name match.
bool manufacturerBleForbidsInventedDriveMetrics(BikeBleKind? kind) {
  if (kind == null) return true;
  return bikeBleKindIsDrive(kind);
}

/// Local files that hold manufacturer pairing — not ride telemetry.
const kBikeBleDevicesFile = 'bike_ble_devices.json';
const kWatchBleDeviceFile = 'watch_ble_device.json';
const kBleLastCscIdFile = 'ble_last_csc_id.txt';
const kBleLastWatchIdFile = 'ble_last_watch_id.txt';

const kManufacturerBleLocalFiles = <String>[
  kBikeBleDevicesFile,
  kWatchBleDeviceFile,
  kBleLastCscIdFile,
  kBleLastWatchIdFile,
];

WatchHonesty watchHonestyProof(String platformName) =>
    watchHonestyForName(platformName);
