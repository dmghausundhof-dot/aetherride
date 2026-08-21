export type ReceiptScanReason =
  | "ok"
  | "no_key"
  | "quota"
  | "failed"
  | "unreadable";

export type ReceiptScanKind = "workshop" | "parts" | "warranty" | "other";

export type ReceiptScanResult = {
  scanned: boolean;
  reason: ReceiptScanReason;
  merchant: string | null;
  date: string | null;
  amountEur: number | null;
  title: string | null;
  kind: ReceiptScanKind;
  items: string[];
};

export function emptyReceiptScan(reason: ReceiptScanReason): ReceiptScanResult {
  return {
    scanned: false,
    reason,
    merchant: null,
    date: null,
    amountEur: null,
    title: null,
    kind: "other",
    items: [],
  };
}

export function parseReceiptScanContent(raw: string): ReceiptScanResult {
  const jsonStart = raw.indexOf("{");
  const jsonEnd = raw.lastIndexOf("}");
  if (jsonStart < 0 || jsonEnd <= jsonStart) {
    return emptyReceiptScan("unreadable");
  }
  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(raw.slice(jsonStart, jsonEnd + 1)) as Record<
      string,
      unknown
    >;
  } catch {
    return emptyReceiptScan("unreadable");
  }
  const kindRaw = parsed.kind;
  const kind: ReceiptScanKind =
    kindRaw === "workshop" ||
    kindRaw === "parts" ||
    kindRaw === "warranty" ||
    kindRaw === "other"
      ? kindRaw
      : "other";
  const amount =
    typeof parsed.amountEur === "number"
      ? parsed.amountEur
      : Number(String(parsed.amountEur ?? "").replace(",", "."));
  const items = Array.isArray(parsed.items)
    ? parsed.items.filter(
        (e): e is string => typeof e === "string" && e.trim().length > 0
      )
    : [];
  const merchant =
    typeof parsed.merchant === "string" ? parsed.merchant.trim() : "";
  const title = typeof parsed.title === "string" ? parsed.title.trim() : "";
  const date = typeof parsed.date === "string" ? parsed.date.trim() : "";
  const scanned = Boolean(
    merchant || title || (Number.isFinite(amount) && amount > 0) || date
  );
  return {
    scanned,
    reason: scanned ? "ok" : "unreadable",
    merchant: merchant || null,
    date: date || null,
    amountEur: Number.isFinite(amount) && amount > 0 ? amount : null,
    title: title || null,
    kind,
    items: items.slice(0, 8),
  };
}
