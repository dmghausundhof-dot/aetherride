import { NextResponse } from "next/server";
import { getBikeSchemaSummary } from "@/lib/compat";

/**
 * GET /api/compat/bike-schema
 * Thin field-contract summary (version bike-entity-schema-v1).
 * Geometry is never required for Compat Gates.
 */
export async function GET() {
  return NextResponse.json(getBikeSchemaSummary());
}
