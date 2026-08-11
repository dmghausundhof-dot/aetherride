import { NextRequest, NextResponse } from "next/server";
import { getCompatGatesRuleset } from "@/lib/compat";

/**
 * GET /api/compat/gates?demo=1
 * Returns Compat Gates v1 version + dimensions + rules (demo pack).
 */
export async function GET(req: NextRequest) {
  const demo = req.nextUrl.searchParams.get("demo");
  if (demo !== "1" && demo !== "true") {
    return NextResponse.json(
      {
        error: "demo_required",
        message:
          "Compat Gates v1 demo pack: call GET /api/compat/gates?demo=1",
      },
      { status: 400 }
    );
  }

  const ruleset = getCompatGatesRuleset();
  return NextResponse.json({
    version: ruleset.version,
    demo_priority: ruleset.demo_priority ?? true,
    evaluation_contract: ruleset.evaluation_contract,
    dimensions: ruleset.dimensions,
    rules: ruleset.rules,
  });
}
