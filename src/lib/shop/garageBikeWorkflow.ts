/**
 * AI-Workflow: Garage-Bike anlegen → Shopify Fit-Hook upserten.
 *
 * Schritte (retrybar, ohne erfundene OEM-SKUs):
 * 1. Identify — Katalog / ehrliche Felder
 * 2. Map — category:/wheel:/ebike/shift_compat:
 * 3. Upsert — productSet per stabilem Handle `ar-garage-{bikeId}`
 *
 * Ohne Admin-Token: ehrlich „Shop nicht verbunden“, keine Fake-Product-ID.
 */

import { findCatalogBike } from "@/lib/catalog/bikes";
import { getComponentModel } from "@/lib/catalog/components";
import { searchCatalogBikes } from "@/lib/catalog/identify";
import type { BikeCategory } from "@/types";
import { isRideableGarageBike } from "@/lib/shop/garageFit";
import {
  mapGarageBikeToShopify,
  type GarageBikeTagInput,
} from "@/lib/shop/garageBikeTags";
import {
  findProductByHandle,
  getShopifyAdminConfig,
  setGarageBikeMetafields,
  upsertProductByHandle,
} from "@/lib/shop/shopifyAdmin";

const BIKE_CATEGORIES = new Set<BikeCategory>([
  "mtb_trail",
  "mtb_am",
  "mtb_enduro",
  "dh",
  "gravel",
  "road",
  "urban",
  "cargo",
  "folding",
  "kids",
  "emtb",
  "etrekking",
  "hiking",
]);

export type GarageBikeWorkflowInput = GarageBikeTagInput;

export type GarageBikeWorkflowResult =
  | {
      ok: true;
      skipped?: false;
      productId: string;
      handle: string;
      sku: string;
      tags: string[];
      created: boolean;
    }
  | {
      ok: true;
      skipped: true;
      reason: "hiking" | "unmapped";
    }
  | {
      ok: false;
      code: "shop_not_connected" | "upsert_failed" | "invalid";
      error: string;
    };

function asCategory(raw: string | undefined): BikeCategory | undefined {
  if (!raw) return undefined;
  return BIKE_CATEGORIES.has(raw as BikeCategory)
    ? (raw as BikeCategory)
    : undefined;
}

export function identifyGarageBike(
  input: GarageBikeWorkflowInput
): GarageBikeTagInput {
  const catalogId = input.catalogBikeId?.trim();
  const found = catalogId ? findCatalogBike(catalogId) : undefined;

  let brand = input.brand?.trim();
  let model = input.model?.trim();
  let category = input.category;
  let isEbike = input.isEbike;
  let wheelSizeFront = input.wheelSizeFront;
  let wheelSizeRear = input.wheelSizeRear;
  const components = [...(input.components ?? [])];

  if (found) {
    brand = brand || found.manufacturer.name;
    model = model || found.bike.name;
    category = category || found.bike.category;
    isEbike = isEbike ?? found.bike.isEbike;
    wheelSizeFront = wheelSizeFront || found.bike.wheelSizeFront;
    wheelSizeRear = wheelSizeRear || found.bike.wheelSizeRear;
    if (components.length === 0) {
      for (const [slot, modelId] of Object.entries(found.bike.oemComponents)) {
        if (!modelId) continue;
        const cm = getComponentModel(modelId);
        components.push({
          slot,
          manufacturer: cm?.manufacturer,
          model: cm?.model,
        });
      }
    }
  } else if ((!brand || !model) && (input.name || brand || model)) {
    const q = [brand, model, input.name].filter(Boolean).join(" ");
    const hit = searchCatalogBikes(q, 1)[0];
    if (hit && hit.score >= 14) {
      const cat = findCatalogBike(hit.id);
      if (cat) {
        brand = brand || cat.manufacturer.name;
        model = model || cat.bike.name;
        if (!input.category) category = cat.bike.category;
        if (isEbike == null) isEbike = cat.bike.isEbike;
        wheelSizeFront = wheelSizeFront || cat.bike.wheelSizeFront;
        wheelSizeRear = wheelSizeRear || cat.bike.wheelSizeRear;
      }
    }
  }

  const resolvedCategory = asCategory(category) ?? input.category;

  return {
    bikeId: input.bikeId.trim(),
    name: input.name.trim() || [brand, model].filter(Boolean).join(" ") || "Bike",
    brand,
    model,
    category: resolvedCategory,
    isEbike,
    wheelSizeFront,
    wheelSizeRear,
    drivetrain: input.drivetrain,
    components,
  };
}

async function enrichWithAi(
  identified: GarageBikeTagInput
): Promise<GarageBikeTagInput> {
  const key = (process.env.XAI_API_KEY || "").trim();
  if (!key) return identified;
  const missingWheel = !identified.wheelSizeFront && !identified.wheelSizeRear;
  const missingDrive =
    (identified.drivetrain?.length ?? 0) === 0 &&
    (identified.components?.length ?? 0) === 0;
  if (!missingWheel && !missingDrive) return identified;

  const model = process.env.XAI_MODEL || "grok-3-mini";
  try {
    const res = await fetch("https://api.x.ai/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model,
        temperature: 0,
        max_tokens: 200,
        messages: [
          {
            role: "system",
            content:
              "Du ergänzt nur ehrliche Fahrrad-Felder. Antworte NUR JSON: " +
              '{"wheel":"29"|"27.5"|"700c"|"650b"|null,"drivetrain":["shimano"|"sram"|"rohloff"|"enviolo"|"campagnolo"]}. ' +
              "Keine Teilenummern, keine Bosch-SKUs, keine Preise. Unklar → null / [].",
          },
          {
            role: "user",
            content: JSON.stringify({
              name: identified.name,
              brand: identified.brand,
              model: identified.model,
              category: identified.category,
            }),
          },
        ],
      }),
    });
    if (!res.ok) return identified;
    const data = (await res.json()) as {
      choices?: { message?: { content?: string } }[];
    };
    const raw = data?.choices?.[0]?.message?.content?.trim() ?? "";
    const start = raw.indexOf("{");
    const end = raw.lastIndexOf("}");
    if (start < 0 || end <= start) return identified;
    const parsed = JSON.parse(raw.slice(start, end + 1)) as {
      wheel?: unknown;
      drivetrain?: unknown;
    };
    const wheel =
      typeof parsed.wheel === "string" ? parsed.wheel : undefined;
    const allowedWheel = new Set(["29", "27.5", "700c", "650b"]);
    const next = { ...identified };
    if (missingWheel && wheel && allowedWheel.has(wheel)) {
      next.wheelSizeFront = wheel;
      next.wheelSizeRear = wheel;
    }
    const allowedDrive = new Set([
      "shimano",
      "sram",
      "rohloff",
      "enviolo",
      "campagnolo",
    ]);
    if (missingDrive && Array.isArray(parsed.drivetrain)) {
      next.drivetrain = parsed.drivetrain
        .filter((t): t is string => typeof t === "string")
        .map((t) => t.toLowerCase())
        .filter((t) => allowedDrive.has(t));
    }
    return next;
  } catch {
    return identified;
  }
}

export async function runGarageBikeShopifyWorkflow(
  input: GarageBikeWorkflowInput
): Promise<GarageBikeWorkflowResult> {
  const bikeId = String(input.bikeId || "").trim();
  if (!bikeId) {
    return { ok: false, code: "invalid", error: "bikeId fehlt" };
  }

  let identified = identifyGarageBike({ ...input, bikeId });
  if (!isRideableGarageBike(identified.category)) {
    return { ok: true, skipped: true, reason: "hiking" };
  }

  identified = await enrichWithAi(identified);
  const mapped = mapGarageBikeToShopify(identified);
  if (!mapped) {
    return { ok: true, skipped: true, reason: "unmapped" };
  }

  const admin = getShopifyAdminConfig();
  if (!admin) {
    return {
      ok: false,
      code: "shop_not_connected",
      error: "Shop nicht verbunden",
    };
  }

  try {
    const existing = await findProductByHandle(mapped.handle, admin);
    const product = await upsertProductByHandle({
      handle: mapped.handle,
      includeVariants: !existing,
      config: admin,
      input: {
        title: mapped.title,
        handle: mapped.handle,
        descriptionHtml: mapped.descriptionHtml,
        vendor: mapped.vendor,
        productType: mapped.productType,
        status: "DRAFT",
        tags: mapped.tags,
        productOptions: [
          { name: "Title", values: [{ name: "Default Title" }] },
        ],
        variants: [
          {
            sku: mapped.sku,
            price: "0.00",
            inventoryPolicy: "DENY",
            optionValues: [
              { optionName: "Title", name: "Default Title" },
            ],
          },
        ],
      },
    });

    try {
      await setGarageBikeMetafields({
        productId: product.id,
        bikeId,
        config: admin,
        fitJson: JSON.stringify({
          bikeId,
          families: mapped.families,
          wheelSizes: mapped.wheelSizes,
          isEbike: mapped.isEbike,
          drivetrain: mapped.drivetrain,
        }),
      });
    } catch (metaErr) {
      console.warn("[garage-bike] metafields", metaErr);
    }

    return {
      ok: true,
      productId: product.id,
      handle: product.handle || mapped.handle,
      sku: mapped.sku,
      tags: mapped.tags,
      created: !existing,
    };
  } catch (err) {
    const message = err instanceof Error ? err.message : "Shopify-Upsert fehlgeschlagen";
    if (/nicht verbunden/i.test(message)) {
      return { ok: false, code: "shop_not_connected", error: "Shop nicht verbunden" };
    }
    return { ok: false, code: "upsert_failed", error: message };
  }
}
