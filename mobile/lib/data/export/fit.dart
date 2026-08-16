import 'dart:typed_data';

import '../../domain/ride.dart';

/// Minimal FIT Activity writer — Port of `src/lib/export/fit.ts` (F-ACC-003).
Uint8List rideToFit(RideRecord ride) {
  final startMs = ride.startedAt.toUtc().millisecondsSinceEpoch;
  final fitEpoch = DateTime.utc(1989, 12, 31).millisecondsSinceEpoch;
  final startFit = ((startMs - fitEpoch) / 1000).floor();

  // Empty track → session only (no fake GPS path).
  final pts = ride.track;

  final records = _FitBuf();
  _writeDefinition(records, 0, 0, const [
    (0, 1, 0),
    (1, 2, 132),
    (2, 2, 132),
    (4, 4, 134),
  ]);
  records.u8(0);
  records.u8(4);
  records.u16(255);
  records.u16(0);
  records.u32(startFit);

  _writeDefinition(records, 1, 20, const [
    (253, 4, 134),
    (0, 4, 133),
    (1, 4, 133),
    (2, 2, 132),
    (3, 1, 2),
    (4, 1, 2),
    (7, 2, 132),
  ]);

  var written = 0;
  for (var i = 0; i < pts.length; i++) {
    final p = pts[i];
    final lat = (p['lat'] as num?)?.toDouble();
    final lng = (p['lng'] as num?)?.toDouble() ??
        (p['lon'] as num?)?.toDouble();
    // Skip missing / Null Island / out-of-range — never write 0,0.
    if (lat == null || lng == null) continue;
    if (lat.abs() < 1e-6 && lng.abs() < 1e-6) continue;
    if (lat.abs() > 90 || lng.abs() > 180) continue;
    final elev = (p['elev'] as num?)?.toDouble() ??
        (p['elevation'] as num?)?.toDouble();
    final timeRaw = p['time'] ?? p['timeMs'];
    int t;
    if (timeRaw is num) {
      if (timeRaw > 1e12) {
        t = ((timeRaw.toInt() - fitEpoch) / 1000).floor();
      } else if (timeRaw > 1e10) {
        t = ((timeRaw.toInt() - fitEpoch) / 1000).floor();
      } else {
        t = startFit + timeRaw.round();
      }
    } else {
      t = startFit + written * 30;
    }
    records.u8(1);
    records.u32(t);
    records.i32(_toSemi(lat));
    records.i32(_toSemi(lng));
    final alt = elev != null ? ((elev + 500) * 5).round() : 0xffff;
    records.u16(alt.clamp(0, 0xffff));
    records.u8(liveHrFromTrackPoint(p) ?? 0xff);
    records.u8(liveCadFromTrackPoint(p) ?? 0xff);
    records.u16(livePowerFromTrackPoint(p) ?? 0xffff);
    written++;
  }

  _writeDefinition(records, 2, 18, const [
    (253, 4, 134),
    (2, 1, 0),
    (7, 4, 134),
    (9, 4, 134),
    (22, 2, 132),
  ]);
  records.u8(2);
  records.u32(startFit + (ride.movingTimeSec < 1 ? 1 : ride.movingTimeSec));
  records.u8(2);
  records.u32((ride.movingTimeSec * 1000).round());
  records.u32((ride.distanceKm * 1000 * 100).round());
  records.u16(ride.elevationM.round().clamp(0, 0xffff));

  final data = records.bytes();
  final header = _FitBuf();
  header.u8(14);
  header.u8(0x20);
  header.u16(0x0827);
  header.u32(data.length);
  header.parts.addAll([0x2e, 0x46, 0x49, 0x54]);
  final headerBytes = header.bytes();
  final headerCrc = _crc16(headerBytes, 0, 12);
  final fullHeader = Uint8List(14);
  fullHeader.setRange(0, 12, headerBytes);
  fullHeader[12] = headerCrc & 0xff;
  fullHeader[13] = (headerCrc >> 8) & 0xff;

  final out = Uint8List(14 + data.length + 2);
  out.setRange(0, 14, fullHeader);
  out.setRange(14, 14 + data.length, data);
  final fileCrc = _crc16(out, 0, 14 + data.length);
  out[14 + data.length] = fileCrc & 0xff;
  out[14 + data.length + 1] = (fileCrc >> 8) & 0xff;
  return out;
}

int _toSemi(double deg) => ((deg * 0x80000000) / 180).round();

void _writeDefinition(
  _FitBuf buf,
  int localNum,
  int globalMsg,
  List<(int, int, int)> fields,
) {
  buf.u8(0x40 | (localNum & 0x0f));
  buf.u8(0);
  buf.u8(0);
  buf.u16(globalMsg);
  buf.u8(fields.length);
  for (final f in fields) {
    buf.u8(f.$1);
    buf.u8(f.$2);
    buf.u8(f.$3);
  }
}

final _crcTable = () {
  final t = Uint16List(16);
  for (var i = 0; i < 16; i++) {
    var crc = i;
    for (var j = 0; j < 4; j++) {
      crc = (crc & 1) != 0 ? 0xcc01 ^ (crc >> 1) : crc >> 1;
    }
    t[i] = crc;
  }
  return t;
}();

int _crc16(Uint8List data, int start, int end) {
  var crc = 0;
  for (var i = start; i < end; i++) {
    final byte = data[i];
    var tmp = _crcTable[crc & 0xf];
    crc = (crc >> 4) & 0x0fff;
    crc = crc ^ tmp ^ _crcTable[byte & 0xf];
    tmp = _crcTable[crc & 0xf];
    crc = (crc >> 4) & 0x0fff;
    crc = crc ^ tmp ^ _crcTable[(byte >> 4) & 0xf];
  }
  return crc & 0xffff;
}

class _FitBuf {
  final parts = <int>[];
  void u8(int n) => parts.add(n & 0xff);
  void u16(int n) {
    parts.add(n & 0xff);
    parts.add((n >> 8) & 0xff);
  }

  void u32(int n) {
    parts
      ..add(n & 0xff)
      ..add((n >> 8) & 0xff)
      ..add((n >> 16) & 0xff)
      ..add((n >> 24) & 0xff);
  }

  void i32(int n) => u32(n);

  Uint8List bytes() => Uint8List.fromList(parts);
}
