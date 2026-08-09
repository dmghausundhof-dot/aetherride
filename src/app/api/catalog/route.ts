import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { COMPONENT_CATALOG } from "@/lib/catalog/components";
import imported from "@/lib/catalog/imported.json";

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

function bundledComponents() {
  const extra = (imported as { components?: unknown[] }).components ?? [];
  return [...COMPONENT_CATALOG, ...extra];
}

/**
 * GET /api/catalog?slot=&q=&cursor=&limit=
 * Prefer Postgres component_models; fallback to bundled JSON seed.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const slot = url.searchParams.get("slot");
  const q = (url.searchParams.get("q") || "").toLowerCase();
  const id = url.searchParams.get("id");
  const limit = Math.min(
    parseInt(url.searchParams.get("limit") || "50", 10) || 50,
    200
  );
  const cursor = url.searchParams.get("cursor");

  const sb = admin();
  if (sb) {
    let query = sb
      .from("component_models")
      .select(
        "id, slot, manufacturer, model, year, attributes, interface_complete, source, updated_at"
      )
      .order("id")
      .limit(limit);
    if (id) query = query.eq("id", id);
    if (slot) query = query.eq("slot", slot);
    if (q) {
      query = query.or(
        `manufacturer.ilike.%${q}%,model.ilike.%${q}%,id.ilike.%${q}%`
      );
    }
    if (cursor) query = query.gt("id", cursor);

    const { data, error } = await query;
    if (!error && data && data.length > 0) {
      const { data: meta } = await sb
        .from("catalog_meta")
        .select("model_count, complete_count, catalog_hash, updated_at")
        .eq("id", 1)
        .maybeSingle();
      return NextResponse.json({
        source: "postgres",
        items: data,
        nextCursor: data.length === limit ? data[data.length - 1].id : null,
        meta: meta ?? null,
      });
    }
  }

  // Fallback: bundled seed
  let items = bundledComponents().map((c) => {
    const row = c as {
      id: string;
      slot: string;
      manufacturer: string;
      model: string;
      year?: number;
      attributes?: Record<string, unknown>;
      interface?: unknown;
    };
    return {
      id: row.id,
      slot: row.slot,
      manufacturer: row.manufacturer,
      model: row.model,
      year: row.year ?? null,
      attributes: row.attributes ?? row,
      interface_complete: Boolean(
        row.slot && row.manufacturer && row.model && (row.attributes || row.interface)
      ),
      source: "bundle",
    };
  });
  if (id) items = items.filter((i) => i.id === id);
  if (slot) items = items.filter((i) => i.slot === slot);
  if (q) {
    items = items.filter(
      (i) =>
        String(i.manufacturer).toLowerCase().includes(q) ||
        String(i.model).toLowerCase().includes(q) ||
        String(i.id).toLowerCase().includes(q)
    );
  }
  items.sort((a, b) => String(a.id).localeCompare(String(b.id)));
  let start = 0;
  if (cursor) {
    const idx = items.findIndex((i) => i.id === cursor);
    start = idx >= 0 ? idx + 1 : 0;
  }
  const page = items.slice(start, start + limit);
  const complete = items.filter((i) => i.interface_complete).length;

  return NextResponse.json({
    source: "bundle",
    items: page,
    nextCursor: page.length === limit ? page[page.length - 1].id : null,
    meta: {
      model_count: items.length,
      complete_count: complete,
      catalog_hash: null,
      updated_at: null,
      g4_progress_pct: Math.round((items.length / 3000) * 1000) / 10,
    },
  });
}
