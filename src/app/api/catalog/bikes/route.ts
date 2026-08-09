import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import {
  catalogStats,
  findCatalogBike,
  listCatalogManufacturers,
} from "@/lib/catalog/bikes";
import type { CatalogManufacturer } from "@/types/garage";

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

type OemMap = Record<string, string>;

function oemFromSeed(raw: unknown): OemMap {
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    const out: OemMap = {};
    for (const [k, v] of Object.entries(raw as Record<string, unknown>)) {
      if (typeof v === "string" && v) out[k] = v;
    }
    return out;
  }
  if (!Array.isArray(raw)) return {};
  const out: OemMap = {};
  for (const e of raw) {
    if (!e || typeof e !== "object") continue;
    const row = e as Record<string, unknown>;
    const slot = row.slot as string | undefined;
    const modelId =
      (row.component_model_id as string | undefined) ||
      (row.componentModelId as string | undefined) ||
      (row.modelId as string | undefined);
    if (slot && modelId) out[slot] = modelId;
  }
  return out;
}

function serializeManufacturers(
  manufacturers: CatalogManufacturer[],
  {
    q,
    manufacturer,
    category,
  }: { q?: string; manufacturer?: string | null; category?: string | null }
) {
  const qLower = (q || "").toLowerCase();
  return manufacturers
    .filter((m) => !manufacturer || m.id === manufacturer || m.name === manufacturer)
    .map((m) => ({
      id: m.id,
      name: m.name,
      bikes: m.bikes
        .filter((b) => {
          if (category && b.category !== category) return false;
          if (!qLower) return true;
          return (
            b.name.toLowerCase().includes(qLower) ||
            m.name.toLowerCase().includes(qLower) ||
            b.id.toLowerCase().includes(qLower)
          );
        })
        .map((b) => ({
          id: b.id,
          name: b.name,
          year: b.year,
          category: b.category,
          frameSizeOptions: b.frameSizeOptions,
          travelFrontMm: b.travelFrontMm ?? null,
          travelRearMm: b.travelRearMm ?? null,
          wheelSizeFront: b.wheelSizeFront,
          wheelSizeRear: b.wheelSizeRear,
          isEbike: b.isEbike,
          weightKgApprox: b.weightKgApprox ?? null,
          oemComponents: b.oemComponents ?? {},
          sourceUrl: b.sourceUrl,
        })),
    }))
    .filter((m) => m.bikes.length > 0);
}

/**
 * GET /api/catalog/bikes?q=&manufacturer=&category=
 * Prefer Postgres catalog_bikes (enriched from BIKE_CATALOG); fallback to bundle.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const q = url.searchParams.get("q") || undefined;
  const manufacturer = url.searchParams.get("manufacturer");
  const category = url.searchParams.get("category");

  const sb = admin();
  if (sb) {
    let query = sb
      .from("catalog_bikes")
      .select(
        "id, manufacturer_id, manufacturer_name, name, category, year, oem_components, updated_at"
      )
      .order("manufacturer_name")
      .order("name")
      .limit(500);
    if (manufacturer) {
      query = query.or(
        `manufacturer_id.eq.${manufacturer},manufacturer_name.eq.${manufacturer}`
      );
    }
    if (category) query = query.eq("category", category);
    if (q) {
      query = query.or(
        `name.ilike.%${q}%,manufacturer_name.ilike.%${q}%,id.ilike.%${q}%`
      );
    }

    const { data, error } = await query;
    if (!error && data && data.length > 0) {
      const byMfr = new Map<
        string,
        {
          id: string;
          name: string;
          bikes: ReturnType<typeof serializeManufacturers>[number]["bikes"];
        }
      >();

      for (const row of data) {
        const found = findCatalogBike(row.id);
        const cat = found?.bike;
        const oem =
          Object.keys(cat?.oemComponents ?? {}).length > 0
            ? (cat!.oemComponents as OemMap)
            : oemFromSeed(row.oem_components);

        const mfrId = row.manufacturer_id || found?.manufacturer.id || "unknown";
        const mfrName =
          row.manufacturer_name || found?.manufacturer.name || "Unbekannt";
        if (!byMfr.has(mfrId)) {
          byMfr.set(mfrId, { id: mfrId, name: mfrName, bikes: [] });
        }
        byMfr.get(mfrId)!.bikes.push({
          id: row.id,
          name: cat?.name ?? row.name,
          year: cat?.year ?? row.year ?? 0,
          category: (cat?.category ?? row.category) as never,
          frameSizeOptions: cat?.frameSizeOptions ?? ["S", "M", "L", "XL"],
          travelFrontMm: cat?.travelFrontMm ?? null,
          travelRearMm: cat?.travelRearMm ?? null,
          wheelSizeFront: cat?.wheelSizeFront ?? "29",
          wheelSizeRear: cat?.wheelSizeRear ?? "29",
          isEbike: cat?.isEbike ?? false,
          weightKgApprox: cat?.weightKgApprox ?? null,
          oemComponents: oem,
          sourceUrl: cat?.sourceUrl ?? "",
        });
      }

      const manufacturers = [...byMfr.values()].filter((m) => m.bikes.length > 0);
      const bikeCount = manufacturers.reduce((n, m) => n + m.bikes.length, 0);
      const oemRefs = manufacturers.reduce(
        (n, m) =>
          n +
          m.bikes.reduce(
            (bn, b) => bn + Object.keys(b.oemComponents ?? {}).length,
            0
          ),
        0
      );

      return NextResponse.json({
        source: "postgres",
        manufacturers,
        meta: {
          manufacturers: manufacturers.length,
          bikes: bikeCount,
          oemRefs,
        },
      });
    }
  }

  const manufacturers = serializeManufacturers(listCatalogManufacturers(), {
    q,
    manufacturer,
    category,
  });
  const stats = catalogStats();

  return NextResponse.json({
    source: "bundle",
    manufacturers,
    meta: stats,
  });
}
