import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  formatIdentityDate,
  identityIsEmpty,
  normalizeBikeIdentity,
  normalizeDate,
} from "./bikeIdentity";
import { buildServiceReport } from "./serviceReport";
import type { Bike } from "@/types";

describe("bike identity", () => {
  it("normalizes serial, EU decimals and DE dates", () => {
    const id = normalizeBikeIdentity({
      serialNumber: "  ws 1847 ",
      color: " Graphit ",
      weightKg: Number("14.2"),
      purchasedAt: "12.04.2023",
      purchasePriceEur: 2499,
    });
    assert.equal(id.serialNumber, "ws 1847");
    assert.equal(id.color, "Graphit");
    assert.equal(id.weightKg, 14.2);
    assert.equal(id.purchasedAt, "2023-04-12");
    assert.equal(identityIsEmpty(id), false);
  });

  it("drops junk", () => {
    assert.equal(normalizeDate("1890-01-01"), undefined);
    assert.equal(normalizeBikeIdentity({ weightKg: 2 }).weightKg, undefined);
    assert.equal(identityIsEmpty(normalizeBikeIdentity({})), true);
    assert.equal(formatIdentityDate("2024-06-01"), "01.06.2024");
  });

  it("service report includes Rahmennummer", () => {
    const bike = {
      id: "b1",
      name: "Trail",
      category: "mtb_am",
      type: "all_mountain",
      isActive: true,
      isEbike: false,
      createdAt: "2026-01-01",
      updatedAt: "2026-01-01",
      components: [],
      setups: [],
      totalOdometerKm: 12,
      totalHours: 1,
      serialNumber: "WS-1847",
      insuranceName: "ADAC",
    } as Bike;
    const text = buildServiceReport({ bike, logs: [], rides: [] });
    assert.match(text, /Rahmennummer: WS-1847/);
    assert.match(text, /Versicherung: ADAC/);
  });
});
