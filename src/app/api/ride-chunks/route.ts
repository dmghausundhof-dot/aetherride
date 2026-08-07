import { NextResponse } from "next/server";
import { createHash } from "crypto";
import { gunzipSync } from "zlib";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

const MAX_BYTES = 5 * 1024 * 1024;
const BUCKET = "ride-chunks";

/**
 * POST /api/ride-chunks
 * Body JSON: { rideId, seq, encoding?: "gzip-base64"|"raw", payload: string|object }
 * Uploads to Supabase Storage ride-chunks/{userId}/{rideId}/{seq}.json.gz
 * and upserts ride_chunk_uploads meta.
 */
export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }

    const body = await req.json();
    const rideId =
      typeof body?.rideId === "string" ? body.rideId.trim() : "";
    const seq = typeof body?.seq === "number" ? body.seq : Number(body?.seq);
    if (!rideId || !Number.isFinite(seq) || seq < 0) {
      return NextResponse.json(
        { error: "rideId and seq required" },
        { status: 400 }
      );
    }

    let raw: Buffer;
    const encoding = body?.encoding as string | undefined;
    if (encoding === "gzip-base64" && typeof body?.payload === "string") {
      raw = gunzipSync(Buffer.from(body.payload, "base64"));
    } else if (typeof body?.payload === "string") {
      raw = Buffer.from(body.payload, "utf8");
    } else if (body?.payload && typeof body.payload === "object") {
      raw = Buffer.from(JSON.stringify(body.payload), "utf8");
    } else {
      return NextResponse.json({ error: "payload required" }, { status: 400 });
    }

    if (raw.length > MAX_BYTES) {
      return NextResponse.json(
        { error: `payload exceeds ${MAX_BYTES} bytes` },
        { status: 413 }
      );
    }

    // Validate JSON
    JSON.parse(raw.toString("utf8"));

    const { gzipSync } = await import("zlib");
    const gz = gzipSync(raw);
    const sha256 = createHash("sha256").update(raw).digest("hex");
    const storagePath = `${user.id}/${rideId}/${seq}.json.gz`;

    const admin = createAdminClient();
    const { error: upErr } = await admin.storage
      .from(BUCKET)
      .upload(storagePath, gz, {
        contentType: "application/gzip",
        upsert: true,
      });
    if (upErr) {
      return NextResponse.json(
        { error: `storage: ${upErr.message}` },
        { status: 502 }
      );
    }

    const { error: metaErr } = await admin.from("ride_chunk_uploads").upsert(
      {
        user_id: user.id,
        ride_id: rideId,
        seq,
        storage_path: storagePath,
        bytes: raw.length,
        sha256,
      },
      { onConflict: "user_id,ride_id,seq" }
    );
    if (metaErr) {
      // Storage ok — meta may be missing if migration not applied yet
      return NextResponse.json({
        ok: true,
        storagePath,
        bytes: raw.length,
        sha256,
        metaWarning: metaErr.message,
      });
    }

    return NextResponse.json({
      ok: true,
      storagePath,
      bytes: raw.length,
      sha256,
    });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "ride-chunks failed" },
      { status: 500 }
    );
  }
}

/** GET /api/ride-chunks?rideId= — list uploaded chunks for current user. */
export async function GET(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }
    const rideId = new URL(req.url).searchParams.get("rideId");
    const admin = createAdminClient();
    let q = admin
      .from("ride_chunk_uploads")
      .select("ride_id, seq, storage_path, bytes, sha256, created_at")
      .eq("user_id", user.id)
      .order("seq", { ascending: true });
    if (rideId) q = q.eq("ride_id", rideId);
    const { data, error } = await q.limit(500);
    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    return NextResponse.json({ chunks: data ?? [] });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "list failed" },
      { status: 500 }
    );
  }
}
