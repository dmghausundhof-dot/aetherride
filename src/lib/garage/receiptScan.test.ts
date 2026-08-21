import {
  emptyReceiptScan,
  parseReceiptScanContent,
} from "./receiptScan";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

const emptyKey = emptyReceiptScan("no_key");
assert(emptyKey.scanned === false, "no_key not scanned");
assert(emptyKey.reason === "no_key", "no_key reason");

const ok = parseReceiptScanContent(
  'Hier: {"merchant":"Bike Shop","date":"2026-08-01","amountEur":89.5,"title":"Inspektion","kind":"workshop","items":["Kette"]}'
);
assert(ok.scanned === true, "happy path scanned");
assert(ok.reason === "ok", "happy path reason");
assert(ok.merchant === "Bike Shop", "merchant");
assert(ok.amountEur === 89.5, "amount");
assert(ok.kind === "workshop", "kind");
assert(ok.items[0] === "Kette", "items");

const bad = parseReceiptScanContent("kein json");
assert(bad.scanned === false, "unreadable scanned");
assert(bad.reason === "unreadable", "unreadable reason");

console.log("receiptScan.test.ts OK");
