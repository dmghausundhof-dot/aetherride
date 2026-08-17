/// Decoder for Bosch LDI `LiveData` protobuf (Spec V1.0, Apache-2.0).
/// Sparse notifications merge in the native plugin; this parses one frame.
class BoschLdiFrame {
  const BoschLdiFrame({
    this.speedKmh,
    this.cadenceRpm,
    this.riderPowerW,
    this.ambientBrightnessLux,
    this.batterySocPercent,
    this.timeUnixS,
    this.odometerKm,
    this.lightOn,
    this.systemLock,
    this.chargerConnected,
    this.lightReserve,
    this.diagnosisActive,
    this.bikeNotDriving,
  });

  final double? speedKmh;
  final double? cadenceRpm;
  final double? riderPowerW;
  final double? ambientBrightnessLux;
  final double? batterySocPercent;
  final int? timeUnixS;
  final double? odometerKm;
  final bool? lightOn;
  final bool? systemLock;
  final bool? chargerConnected;
  final bool? lightReserve;
  final bool? diagnosisActive;
  final bool? bikeNotDriving;

  bool get hasLiveMetrics =>
      speedKmh != null ||
      cadenceRpm != null ||
      riderPowerW != null ||
      batterySocPercent != null;
}

class _Reader {
  _Reader(this.bytes);
  final List<int> bytes;
  int i = 0;

  bool get done => i >= bytes.length;

  int u8() {
    if (i >= bytes.length) throw const FormatException('truncated');
    return bytes[i++];
  }

  int varint() {
    var shift = 0;
    var n = 0;
    while (true) {
      final b = u8();
      n |= (b & 0x7f) << shift;
      if ((b & 0x80) == 0) return n;
      shift += 7;
      if (shift > 63) throw const FormatException('varint overflow');
    }
  }

  List<int> skip(int wire) {
    switch (wire) {
      case 0:
        varint();
        return const [];
      case 1:
        i += 8;
        return const [];
      case 2:
        final n = varint();
        i += n;
        return const [];
      case 5:
        i += 4;
        return const [];
      default:
        throw FormatException('wire $wire');
    }
  }
}

int _sint32FromVarint(int n) {
  final u = n & 0xffffffff;
  if (u <= 0x7fffffff) return u;
  return u - 0x100000000;
}

/// Parse one `com.bosch.ebike.LiveData` payload. Unknown fields ignored.
BoschLdiFrame decodeBoschLdiFrame(List<int> bytes) {
  final r = _Reader(bytes);
  double? speedKmh;
  double? cadenceRpm;
  double? riderPowerW;
  double? ambientBrightnessLux;
  double? batterySocPercent;
  int? timeUnixS;
  double? odometerKm;
  bool? lightOn;
  bool? systemLock;
  bool? chargerConnected;
  bool? lightReserve;
  bool? diagnosisActive;
  bool? bikeNotDriving;

  while (!r.done) {
    final tag = r.varint();
    final field = tag >> 3;
    final wire = tag & 7;
    if (wire != 0) {
      r.skip(wire);
      continue;
    }
    final n = r.varint();
    switch (field) {
      case 1:
        speedKmh = n / 100.0;
      case 2:
        cadenceRpm = _sint32FromVarint(n).toDouble();
      case 5:
        riderPowerW = n.toDouble();
      case 9:
        ambientBrightnessLux = n / 1000.0;
      case 10:
        batterySocPercent = n.clamp(0, 100).toDouble();
      case 11:
        timeUnixS = n;
      case 12:
        odometerKm = n / 1000.0;
      case 17:
        lightOn = n == 2;
      case 21:
        systemLock = n != 0;
      case 22:
        chargerConnected = n != 0;
      case 23:
        lightReserve = n != 0;
      case 24:
        diagnosisActive = n != 0;
      case 25:
        bikeNotDriving = n != 0;
    }
  }

  return BoschLdiFrame(
    speedKmh: speedKmh,
    cadenceRpm: cadenceRpm,
    riderPowerW: riderPowerW,
    ambientBrightnessLux: ambientBrightnessLux,
    batterySocPercent: batterySocPercent,
    timeUnixS: timeUnixS,
    odometerKm: odometerKm,
    lightOn: lightOn,
    systemLock: systemLock,
    chargerConnected: chargerConnected,
    lightReserve: lightReserve,
    diagnosisActive: diagnosisActive,
    bikeNotDriving: bikeNotDriving,
  );
}

/// Encode a few fields for tests (proto3 varint).
List<int> encodeBoschLdiTestFrame({
  int? speedHundredths,
  int? cadenceRpm,
  int? riderPowerW,
  int? batterySoc,
  int? odometerM,
}) {
  final out = <int>[];
  void field(int id, int value) {
    var tag = (id << 3);
    while (tag > 0x7f) {
      out.add((tag & 0x7f) | 0x80);
      tag >>= 7;
    }
    out.add(tag);
    var n = value;
    if (n < 0) n = n & 0xffffffff;
    while (n > 0x7f) {
      out.add((n & 0x7f) | 0x80);
      n >>= 7;
    }
    out.add(n);
  }

  if (speedHundredths != null) field(1, speedHundredths);
  if (cadenceRpm != null) field(2, cadenceRpm);
  if (riderPowerW != null) field(5, riderPowerW);
  if (batterySoc != null) field(10, batterySoc);
  if (odometerM != null) field(12, odometerM);
  return out;
}
