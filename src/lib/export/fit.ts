/**
 * Minimal FIT Activity file writer (FIT Protocol) for F-ACC-003.
 * No third-party SDK — enough for GPX-alternative download in browsers.
 */

import type { Ride } from "@/types";

const CRC_TABLE = (() => {
  const t = new Uint16Array(16);
  for (let i = 0; i < 16; i++) {
    let crc = i;
    for (let j = 0; j < 4; j++) {
      crc = crc & 1 ? 0xcc01 ^ (crc >> 1) : crc >> 1;
    }
    t[i] = crc;
  }
  return t;
})();

function crc16(data: Uint8Array, start = 0, end = data.length): number {
  let crc = 0;
  for (let i = start; i < end; i++) {
    const byte = data[i];
    let tmp = CRC_TABLE[crc & 0xf];
    crc = (crc >> 4) & 0x0fff;
    crc = crc ^ tmp ^ CRC_TABLE[byte & 0xf];
    tmp = CRC_TABLE[crc & 0xf];
    crc = (crc >> 4) & 0x0fff;
    crc = crc ^ tmp ^ CRC_TABLE[(byte >> 4) & 0xf];
  }
  return crc & 0xffff;
}

class FitBuf {
  parts: number[] = [];
  u8(n: number) {
    this.parts.push(n & 0xff);
  }
  u16(n: number) {
    this.parts.push(n & 0xff, (n >> 8) & 0xff);
  }
  u32(n: number) {
    this.parts.push(
      n & 0xff,
      (n >> 8) & 0xff,
      (n >> 16) & 0xff,
      (n >> 24) & 0xff
    );
  }
  i32(n: number) {
    this.u32(n >>> 0);
  }
  bytes(): Uint8Array {
    return new Uint8Array(this.parts);
  }
}

function writeDefinition(
  buf: FitBuf,
  localNum: number,
  globalMsg: number,
  fields: { num: number; size: number; base: number }[]
) {
  buf.u8(0x40 | (localNum & 0x0f));
  buf.u8(0); // reserved
  buf.u8(0); // architecture little
  buf.u16(globalMsg);
  buf.u8(fields.length);
  for (const f of fields) {
    buf.u8(f.num);
    buf.u8(f.size);
    buf.u8(f.base);
  }
}

/** Semi-circles: degrees * (2^31 / 180) */
function toSemi(deg: number): number {
  return Math.round((deg * 0x80000000) / 180);
}

/**
 * Build a minimal FIT activity with record messages from ride.track.
 * Empty track → session/lap only (no synthetic GPS points).
 */
export function rideToFit(ride: Ride): Uint8Array {
  const startMs = new Date(ride.startTime).getTime();
  // FIT epoch = 1989-12-31
  const fitEpoch = Date.UTC(1989, 11, 31, 0, 0, 0);
  const startFit = Math.floor((startMs - fitEpoch) / 1000);

  const pts = ride.track && ride.track.length > 0 ? ride.track : [];

  const records = new FitBuf();
  // file_id definition local 0, global 0
  writeDefinition(records, 0, 0, [
    { num: 0, size: 1, base: 0 }, // type
    { num: 1, size: 2, base: 132 }, // manufacturer
    { num: 2, size: 2, base: 132 }, // product
    { num: 4, size: 4, base: 134 }, // time_created
  ]);
  records.u8(0); // data local 0
  records.u8(4); // activity
  records.u16(255); // development
  records.u16(0);
  records.u32(startFit);

  // record def local 1, global 20
  writeDefinition(records, 1, 20, [
    { num: 253, size: 4, base: 134 }, // timestamp
    { num: 0, size: 4, base: 133 }, // position_lat
    { num: 1, size: 4, base: 133 }, // position_long
    { num: 2, size: 2, base: 132 }, // altitude (scaled)
    { num: 3, size: 1, base: 2 }, // heart_rate
    { num: 4, size: 1, base: 2 }, // cadence
    { num: 7, size: 2, base: 132 }, // power
  ]);

  let written = 0;
  for (let i = 0; i < pts.length; i++) {
    const p = pts[i];
    const lat = typeof p.lat === "number" ? p.lat : null;
    const lng = typeof p.lng === "number" ? p.lng : null;
    // Skip missing / Null Island / out-of-range — never write 0,0.
    if (lat == null || lng == null) continue;
    if (Math.abs(lat) < 1e-6 && Math.abs(lng) < 1e-6) continue;
    if (Math.abs(lat) > 90 || Math.abs(lng) > 180) continue;
    const t =
      typeof p.time === "number"
        ? startFit + Math.floor(p.time)
        : startFit + written * 30;
    records.u8(1);
    records.u32(t);
    records.i32(toSemi(lat));
    records.i32(toSemi(lng));
    const alt = p.elev != null ? Math.round((p.elev + 500) * 5) : 0xffff;
    records.u16(alt);
    const hr = typeof p.hr === "number" && p.hr >= 1 && p.hr <= 239 ? Math.round(p.hr) : 0xff;
    const cad = typeof p.cad === "number" && p.cad >= 1 && p.cad <= 254 ? Math.round(p.cad) : 0xff;
    const power =
      typeof p.power === "number" && p.power >= 1 && p.power <= 2500
        ? Math.round(p.power)
        : 0xffff;
    records.u8(hr);
    records.u8(cad);
    records.u16(power);
    written++;
  }

  // session def local 2, global 18
  writeDefinition(records, 2, 18, [
    { num: 253, size: 4, base: 134 },
    { num: 2, size: 1, base: 0 }, // sport
    { num: 7, size: 4, base: 134 }, // total_elapsed_time (ms/1000 as uint32 * 1000)
    { num: 9, size: 4, base: 134 }, // total_distance (cm)
    { num: 22, size: 2, base: 132 }, // total_ascent
  ]);
  records.u8(2);
  records.u32(startFit + Math.max(1, ride.durationSec));
  records.u8(2); // cycling
  records.u32(Math.round(ride.durationSec * 1000));
  records.u32(Math.round(ride.distanceM * 100));
  records.u16(Math.round(ride.elevationGainM));

  const data = records.bytes();
  const header = new FitBuf();
  header.u8(14); // header size
  header.u8(0x20); // protocol
  header.u16(0x0827); // profile
  header.u32(data.length);
  header.parts.push(...[0x2e, 0x46, 0x49, 0x54]); // .FIT
  const headerBytes = header.bytes();
  const headerCrc = crc16(headerBytes, 0, 12);
  const fullHeader = new Uint8Array(14);
  fullHeader.set(headerBytes.slice(0, 12), 0);
  fullHeader[12] = headerCrc & 0xff;
  fullHeader[13] = (headerCrc >> 8) & 0xff;

  const out = new Uint8Array(14 + data.length + 2);
  out.set(fullHeader, 0);
  out.set(data, 14);
  const fileCrc = crc16(out, 0, 14 + data.length);
  out[14 + data.length] = fileCrc & 0xff;
  out[14 + data.length + 1] = (fileCrc >> 8) & 0xff;
  return out;
}

export function downloadBytes(filename: string, data: Uint8Array, mime: string) {
  if (typeof window === "undefined") return;
  const blob = new Blob([data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength) as ArrayBuffer], {
    type: mime,
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}
