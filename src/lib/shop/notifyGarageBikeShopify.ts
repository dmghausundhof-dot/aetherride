"use client";

import type { Bike } from "@/types";
import { findCatalogBike } from "@/lib/catalog/bikes";
import type { GarageBikeTagInput } from "@/lib/shop/garageBikeTags";

export function garageBikeInputFromBike(bike: Bike): GarageBikeTagInput {
  const catalog = bike.catalogBikeId
    ? findCatalogBike(bike.catalogBikeId)
    : undefined;
  return {
    bikeId: bike.id,
    name: bike.name,
    brand: catalog?.manufacturer.name,
    model: catalog?.bike.name,
    category: bike.category,
    isEbike: bike.isEbike,
    wheelSizeFront: bike.wheelSizeFront,
    wheelSizeRear: bike.wheelSizeRear,
    catalogBikeId: bike.catalogBikeId,
    components: bike.components.map((c) => ({
      slot: c.slot,
      manufacturer: c.manufacturer,
      model: c.model,
    })),
  };
}

/** Fire-and-forget nach Bike-Create. Fehler bleiben serverseitig ehrlich. */
export function notifyGarageBikeShopify(input: GarageBikeTagInput): void {
  if (typeof window === "undefined") return;
  void fetch("/api/shop/garage-bike", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  }).catch(() => {});
}
