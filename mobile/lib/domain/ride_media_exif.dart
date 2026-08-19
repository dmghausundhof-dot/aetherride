import 'dart:typed_data';

/// Best-effort JPEG EXIF GPS. Returns null when the file has no GPS IFD.
({double lat, double lng})? readJpegGps(List<int> bytes) {
  if (bytes.length < 12) return null;
  if (bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  var i = 2;
  while (i + 4 < bytes.length) {
    if (bytes[i] != 0xFF) return null;
    final marker = bytes[i + 1];
    if (marker == 0xDA || marker == 0xD9) return null;
    final len = (bytes[i + 2] << 8) | bytes[i + 3];
    if (len < 2 || i + 2 + len > bytes.length) return null;
    if (marker == 0xE1) {
      final payload = bytes.sublist(i + 4, i + 2 + len);
      final gps = _exifGps(payload);
      if (gps != null) return gps;
    }
    i += 2 + len;
  }
  return null;
}

({double lat, double lng})? _exifGps(List<int> payload) {
  if (payload.length < 14) return null;
  const head = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00]; // Exif\0\0
  for (var k = 0; k < head.length; k++) {
    if (payload[k] != head[k]) return null;
  }
  final tiff = payload.sublist(6);
  if (tiff.length < 8) return null;
  final le = tiff[0] == 0x49 && tiff[1] == 0x49;
  final be = tiff[0] == 0x4D && tiff[1] == 0x4D;
  if (!le && !be) return null;
  final ifd0 = _u32(tiff, 4, le);
  final gpsOff = _ifdTagOffset(tiff, ifd0, 0x8825, le);
  if (gpsOff == null || gpsOff < 0 || gpsOff + 2 > tiff.length) return null;
  final latRef = _ifdAscii(tiff, gpsOff, 0x0001, le);
  final lngRef = _ifdAscii(tiff, gpsOff, 0x0003, le);
  final lat = _ifdGpsCoord(tiff, gpsOff, 0x0002, le);
  final lng = _ifdGpsCoord(tiff, gpsOff, 0x0004, le);
  if (lat == null || lng == null) return null;
  final south = (latRef ?? 'N').toUpperCase().startsWith('S');
  final west = (lngRef ?? 'E').toUpperCase().startsWith('W');
  final outLat = south ? -lat : lat;
  final outLng = west ? -lng : lng;
  if (outLat.abs() > 90 || outLng.abs() > 180) return null;
  return (lat: outLat, lng: outLng);
}

int? _ifdTagOffset(List<int> tiff, int ifd, int tag, bool le) {
  if (ifd < 0 || ifd + 2 > tiff.length) return null;
  final n = _u16(tiff, ifd, le);
  var p = ifd + 2;
  for (var i = 0; i < n; i++) {
    if (p + 12 > tiff.length) return null;
    final t = _u16(tiff, p, le);
    if (t == tag) {
      return _u32(tiff, p + 8, le);
    }
    p += 12;
  }
  return null;
}

String? _ifdAscii(List<int> tiff, int ifd, int tag, bool le) {
  final entry = _ifdEntry(tiff, ifd, tag, le);
  if (entry == null) return null;
  final count = entry.count;
  if (count <= 0) return null;
  if (count <= 4) {
    return String.fromCharCodes(
      [entry.valueOff & 0xFF],
    ).trim();
  }
  final off = entry.valueOff;
  if (off < 0 || off + count > tiff.length) return null;
  return String.fromCharCodes(tiff.sublist(off, off + count))
      .replaceAll('\u0000', '')
      .trim();
}

double? _ifdGpsCoord(List<int> tiff, int ifd, int tag, bool le) {
  final entry = _ifdEntry(tiff, ifd, tag, le);
  if (entry == null) return null;
  final off = entry.valueOff;
  if (off < 0 || off + 24 > tiff.length) return null;
  final deg = _rational(tiff, off, le);
  final min = _rational(tiff, off + 8, le);
  final sec = _rational(tiff, off + 16, le);
  if (deg == null || min == null || sec == null) return null;
  return deg + min / 60.0 + sec / 3600.0;
}

({int type, int count, int valueOff})? _ifdEntry(
  List<int> tiff,
  int ifd,
  int tag,
  bool le,
) {
  if (ifd < 0 || ifd + 2 > tiff.length) return null;
  final n = _u16(tiff, ifd, le);
  var p = ifd + 2;
  for (var i = 0; i < n; i++) {
    if (p + 12 > tiff.length) return null;
    if (_u16(tiff, p, le) == tag) {
      return (
        type: _u16(tiff, p + 2, le),
        count: _u32(tiff, p + 4, le),
        valueOff: _u32(tiff, p + 8, le),
      );
    }
    p += 12;
  }
  return null;
}

double? _rational(List<int> tiff, int off, bool le) {
  if (off + 8 > tiff.length) return null;
  final n = _u32(tiff, off, le);
  final d = _u32(tiff, off + 4, le);
  if (d == 0) return null;
  return n / d;
}

int _u16(List<int> b, int i, bool le) {
  if (i + 2 > b.length) return 0;
  final v = ByteData.sublistView(Uint8List.fromList(b.sublist(i, i + 2)));
  return v.getUint16(0, le ? Endian.little : Endian.big);
}

int _u32(List<int> b, int i, bool le) {
  if (i + 4 > b.length) return 0;
  final v = ByteData.sublistView(Uint8List.fromList(b.sublist(i, i + 4)));
  return v.getUint32(0, le ? Endian.little : Endian.big);
}
