import { NextResponse } from "next/server";
import { runGarageBikeShopifyWorkflow } from "@/lib/shop/garageBikeWorkflow";
import type { BikeCategory } from "@/types";

export const dynamic = "force-dynamic";

const CATEGORIES = new Set<BikeCategory>([
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

type Body = {
  bikeId?: string;
  name?: string;
  brand?: string;
  model?: string;
  category?: string;
  isEbike?: boolean;
  wheelSizeFront?: string;
  wheelSizeRear?: string;
  drivetrain?: string[];
  catalogBikeId?: string;
  components?: {
    slot?: string;
    manufacturer?: string;
    model?: string;
  }[];
};

/**
 * POST /api/shop/garage-bike
 * Startet den Garage→Shopify Fit-Hook Workflow (idempotent per bikeId).
 */
export async function POST(req: Request) {
  let body: Body;
  try {
    body = (await req.json()) as Body;
  } catch {
    return NextResponse.json(
      { ok: false, code: "invalid", error: "invalid_json" },
      { status: 400 }
    );
  }

  const bikeId = String(body.bikeId || "").trim();
  const category = body.category as BikeCategory | undefined;
  if (!bikeId || !category || !CATEGORIES.has(category)) {
    return NextResponse.json(
      { ok: false, code: "invalid", error: "bikeId und category erforderlich" },
      { status: 400 }
    );
  }

  const result = await runGarageBikeShopifyWorkflow({
    bikeId,
    name: String(body.name || "").trim() || "Bike",
    brand: body.brand,
    model: body.model,
    category,
    isEbike: body.isEbike,
    wheelSizeFront: body.wheelSizeFront,
    wheelSizeRear: body.wheelSizeRear,
    drivetrain: Array.isArray(body.drivetrain) ? body.drivetrain : undefined,
    catalogBikeId: body.catalogBikeId,
    components: Array.isArray(body.components) ? body.components : undefined,
  });

  if (!result.ok) {
    const status = result.code === "shop_not_connected" ? 503 : 502;
    return NextResponse.json(result, { status });
  }

  return NextResponse.json(result);
}
