/** Private owner facts for one bike. Local + own-device sync only. */

export type BikeIdentity = {
  serialNumber?: string;
  color?: string;
  weightKg?: number;
  notes?: string;
  purchasedAt?: string;
  purchasedFrom?: string;
  purchasePriceEur?: number;
  insuranceName?: string;
  insurancePolicy?: string;
  keyNumber?: string;
};

const EMPTY: BikeIdentity = {};

function asString(v: unknown): string | undefined {
  if (v == null) return undefined;
  const t = String(v).trim();
  return t ? t : undefined;
}

function asNumber(v: unknown): number | undefined {
  if (v == null || v === "") return undefined;
  if (typeof v === "number") return Number.isFinite(v) ? v : undefined;
  const n = Number(String(v).trim().replace(",", "."));
  return Number.isFinite(n) ? n : undefined;
}

function clamp(v: number | undefined, min: number, max: number): number | undefined {
  if (v == null || Number.isNaN(v)) return undefined;
  if (v < min || v > max) return undefined;
  return v;
}

function cleanText(raw: unknown, max = 48): string | undefined {
  const t = asString(raw)?.replace(/\s+/g, " ");
  if (!t) return undefined;
  return t.length > max ? t.slice(0, max) : t;
}

function cleanSerial(raw: unknown): string | undefined {
  const t = asString(raw)?.replace(/\s+/g, " ");
  if (!t) return undefined;
  return t.length > 48 ? t.slice(0, 48) : t;
}

export function normalizeDate(raw?: string | null): string | undefined {
  const t = (raw ?? "").trim();
  if (!t) return undefined;
  const iso = /^(\d{4})-(\d{2})-(\d{2})$/.exec(t);
  if (iso) return validYmd(iso[1], iso[2], iso[3]);
  const de = /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/.exec(t);
  if (de) return validYmd(de[3], de[2].padStart(2, "0"), de[1].padStart(2, "0"));
  const parsed = new Date(t);
  if (Number.isNaN(parsed.getTime())) return undefined;
  return validYmd(
    String(parsed.getFullYear()),
    String(parsed.getMonth() + 1).padStart(2, "0"),
    String(parsed.getDate()).padStart(2, "0")
  );
}

function validYmd(y: string, mo: string, d: string): string | undefined {
  const year = Number(y);
  const month = Number(mo);
  const day = Number(d);
  if (!year || !month || !day) return undefined;
  const nowY = new Date().getFullYear();
  if (year < 1980 || year > nowY + 1) return undefined;
  if (month < 1 || month > 12 || day < 1 || day > 31) return undefined;
  const dt = new Date(year, month - 1, day);
  if (dt.getFullYear() !== year || dt.getMonth() + 1 !== month || dt.getDate() !== day) {
    return undefined;
  }
  return `${y.padStart(4, "0")}-${mo.padStart(2, "0")}-${d.padStart(2, "0")}`;
}

export function normalizeBikeIdentity(input: Partial<BikeIdentity>): BikeIdentity {
  return {
    serialNumber: cleanSerial(input.serialNumber),
    color: cleanText(input.color),
    weightKg: clamp(asNumber(input.weightKg), 4, 80),
    notes: cleanText(input.notes, 800),
    purchasedAt: normalizeDate(input.purchasedAt),
    purchasedFrom: cleanText(input.purchasedFrom, 80),
    purchasePriceEur: clamp(asNumber(input.purchasePriceEur), 0, 100000),
    insuranceName: cleanText(input.insuranceName, 80),
    insurancePolicy: cleanText(input.insurancePolicy, 80),
    keyNumber: cleanText(input.keyNumber, 40),
  };
}

export function identityIsEmpty(id: BikeIdentity): boolean {
  return !id.serialNumber &&
    !id.color &&
    id.weightKg == null &&
    !id.notes &&
    !id.purchasedAt &&
    !id.purchasedFrom &&
    id.purchasePriceEur == null &&
    !id.insuranceName &&
    !id.insurancePolicy &&
    !id.keyNumber;
}

export function formatIdentityDate(iso?: string): string {
  if (!iso) return "";
  const p = iso.split("-");
  if (p.length !== 3) return iso;
  return `${p[2]}.${p[1]}.${p[0]}`;
}

export { EMPTY as emptyBikeIdentity };
