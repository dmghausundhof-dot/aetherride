/**
 * Vision-Slots: Aliase + unbekannte Slots behalten.
 * Ausführen: npx tsx src/lib/catalog/identify.test.ts
 */
import { normalizeVisionSlot, parseVisionParts } from "./identify";

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

assert(normalizeVisionSlot("shock") === "rear_shock", "shock → rear_shock");
assert(normalizeVisionSlot("dropper") === "seatpost", "dropper → seatpost");
assert(normalizeVisionSlot("tyre-front") === "tire_front", "tyre-front → tire_front");

const parts = parseVisionParts([
  { slot: "shock", manufacturer: "Fox", model: "Float X" },
  { slot: "mystery_gizmo", manufacturer: "SRAM", model: "GX" },
  { slot: "fork", manufacturer: "", model: "" },
]);

assert(parts.length === 2, `erwarte 2 Teile, got ${parts.length}`);
assert(parts[0]?.slot === "rear_shock", `shock bleibt als rear_shock, got ${parts[0]?.slot}`);
assert(parts[1]?.slot === "mystery_gizmo", "unbekannter Slot wird nicht verworfen");

console.log("identify.test.ts ok");
