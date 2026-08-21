import { NextRequest, NextResponse } from "next/server";
import {
  evaluateCompat,
  flattenBikeModelToAttrs,
  type BikeEntityModel,
  type CompatAttrMap,
} from "@/lib/compat";

type EvaluateBody = {
  bike?: { attrs?: CompatAttrMap };
  bike_model?: BikeEntityModel;
  part?: { tags?: string[]; attrs?: CompatAttrMap };
  slot?: string;
  serialPresent?: boolean;
  serial_present?: boolean;
};

/**
 * POST /api/compat/evaluate
 *
 * Body (either bike.attrs OR bike_model):
 * {
 *   bike?: { attrs: Record<string,string> },
 *   bike_model?: { brakes?: { fluid_type }, drivetrain?, cockpit?, ebike?, compat_tags? },
 *   part: { tags: string[], attrs?: Record<string,string> },
 *   slot?: string,
 *   serialPresent?: boolean
 * }
 *
 * → { ruleset, result, matched[], missing_attrs[] }
 *
 * Eng Android: prefer bike_model from Garage entity; server flattens via
 * maps_to_compat_dim + value aliases. Part Shopify tags use prefixes from
 * GET /api/compat/gates?demo=1 dimensions.
 */
export async function POST(req: NextRequest) {
  let body: EvaluateBody;
  try {
    body = (await req.json()) as EvaluateBody;
  } catch {
    return NextResponse.json(
      { error: "invalid_json", message: "Body must be JSON" },
      { status: 400 }
    );
  }

  let bikeAttrs: CompatAttrMap | undefined;

  if (body.bike_model && typeof body.bike_model === "object") {
    bikeAttrs = flattenBikeModelToAttrs(body.bike_model);
  } else if (body.bike?.attrs && typeof body.bike.attrs === "object") {
    bikeAttrs = { ...body.bike.attrs };
  }

  if (!bikeAttrs) {
    return NextResponse.json(
      {
        error: "bike_required",
        message:
          "Provide bike: { attrs } or bike_model: <entity> (Bike Entity Schema v1)",
      },
      { status: 400 }
    );
  }

  const part = body.part ?? {};
  const tags = Array.isArray(part.tags) ? part.tags : [];
  const serialPresent =
    body.serialPresent ?? body.serial_present ?? undefined;

  const result = evaluateCompat({
    bikeAttrs,
    partTags: tags,
    partAttrs: part.attrs,
    slot: body.slot,
    serialPresent,
  });

  return NextResponse.json(result);
}
