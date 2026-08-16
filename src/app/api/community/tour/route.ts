/**
 * Community API — local-first on mobile; cloud when Supabase tables exist.
 */
import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";
import { moderateContent } from "@/lib/community/moderate";
import { persistModeration } from "@/lib/community/persistModeration";
import { parseStimmeTags } from "@/lib/community/stimmeTags";

export const dynamic = "force-dynamic";

function sb() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return null;
  return createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

type TourPhotoRow = {
  id?: string;
  tour_id?: string;
  storage_path?: string | null;
  caption?: string | null;
  status?: string | null;
  created_at?: string | null;
};

async function signTourPhotoUrls(
  client: NonNullable<ReturnType<typeof sb>>,
  photos: TourPhotoRow[]
) {
  return Promise.all(
    photos.map(async (p) => {
      const path = String(p.storage_path || "").trim();
      if (!path) return { ...p, url: null as string | null };
      if (path.startsWith("http://") || path.startsWith("https://")) {
        return { ...p, url: path };
      }
      try {
        const { data } = await client.storage
          .from("tour-photos")
          .createSignedUrl(path, 3600);
        return { ...p, url: data?.signedUrl ?? null };
      } catch {
        return { ...p, url: null as string | null };
      }
    })
  );
}

function parseIdList(raw: string | null): string[] {
  if (!raw) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const part of raw.split(",")) {
    const id = part.trim();
    if (!id || seen.has(id)) continue;
    seen.add(id);
    out.push(id);
    if (out.length >= 40) break;
  }
  return out;
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const batchIds = parseIdList(url.searchParams.get("ids"));
  const tourId =
    url.searchParams.get("tourId") || url.searchParams.get("id") || "";
  if (batchIds.length === 0 && !tourId) {
    return NextResponse.json({ error: "tourId required" }, { status: 400 });
  }
  const client = sb();
  if (client && batchIds.length > 0) {
    const [{ data: reviews, error: rErr }, { data: photos, error: pErr }] =
      await Promise.all([
        client
          .from("tour_reviews")
          .select("tour_id")
          .in("tour_id", batchIds)
          .eq("status", "approved"),
        client
          .from("tour_photos")
          .select("tour_id")
          .in("tour_id", batchIds)
          .eq("status", "approved"),
      ]);
    if (!rErr && !pErr) {
      const counts: Record<string, { reviewCount: number; photoCount: number }> =
        {};
      for (const id of batchIds) {
        counts[id] = { reviewCount: 0, photoCount: 0 };
      }
      for (const row of reviews ?? []) {
        const id = String((row as { tour_id?: string }).tour_id || "");
        if (!id || !counts[id]) continue;
        counts[id].reviewCount += 1;
      }
      for (const row of photos ?? []) {
        const id = String((row as { tour_id?: string }).tour_id || "");
        if (!id || !counts[id]) continue;
        counts[id].photoCount += 1;
      }
      return NextResponse.json({ ids: batchIds, counts, stub: false });
    }
    return NextResponse.json({
      ids: batchIds,
      counts: Object.fromEntries(
        batchIds.map((id) => [id, { reviewCount: 0, photoCount: 0 }])
      ),
      stub: true,
    });
  }
  if (client && tourId) {
    const [{ data: taggedReviews, error: taggedErr }, { data: photos, error: pErr }] =
      await Promise.all([
        client
          .from("tour_reviews")
          .select(
            "id, tour_id, author_label, rating, body, status, created_at, tags, pin_lat, pin_lng, along_m"
          )
          .eq("tour_id", tourId)
          .eq("status", "approved")
          .order("created_at", { ascending: false })
          .limit(50),
        client
          .from("tour_photos")
          .select("id, tour_id, storage_path, caption, status, created_at")
          .eq("tour_id", tourId)
          .eq("status", "approved")
          .order("created_at", { ascending: false })
          .limit(40),
      ]);
    let reviews = taggedReviews;
    let rErr = taggedErr;
    if (rErr) {
      const retry = await client
        .from("tour_reviews")
        .select("id, tour_id, author_label, rating, body, status, created_at")
        .eq("tour_id", tourId)
        .eq("status", "approved")
        .order("created_at", { ascending: false })
        .limit(50);
      reviews = retry.data;
      rErr = retry.error;
    }
    if (!rErr && !pErr) {
      const signed = await signTourPhotoUrls(client, photos ?? []);
      return NextResponse.json({
        tourId,
        reviews: reviews ?? [],
        photos: signed,
        reviewCount: (reviews ?? []).length,
        photoCount: signed.length,
        stub: false,
      });
    }
  }
  return NextResponse.json({
    tourId: tourId || batchIds[0] || "",
    reviews: [],
    photos: [],
    reviewCount: 0,
    photoCount: 0,
    stub: true,
  });
}

export async function POST(req: Request) {
  try {
    const supabase = await createAuthedClient(req);
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ error: "unauthorized" }, { status: 401 });
    }
    const body = (await req.json()) as {
      tourId?: string;
      rating?: number;
      body?: string;
      authorLabel?: string;
      tags?: unknown;
      alongM?: unknown;
      pin?: { lat?: unknown; lng?: unknown; alongM?: unknown };
      rideId?: unknown;
      difficultyDelta?: unknown;
      photos?: { storagePath?: string; caption?: string }[];
    };
    const tourId = String(body.tourId || "").trim();
    const rating = Number(body.rating);
    const text = String(body.body || "").trim();
    const tags = parseStimmeTags(body.tags);
    const pinLat = Number(body.pin?.lat);
    const pinLng = Number(body.pin?.lng);
    const alongM = Number(body.pin?.alongM ?? body.alongM);
    const hasPin = Number.isFinite(pinLat) && Number.isFinite(pinLng);
    const deltaRaw = Number(body.difficultyDelta);
    const difficultyDelta =
      Number.isFinite(deltaRaw) && deltaRaw >= -2 && deltaRaw <= 2
        ? Math.round(deltaRaw)
        : null;
    const rideId = String(body.rideId || "").trim() || null;
    if (!tourId || !Number.isFinite(rating) || rating < 1 || rating > 5) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }
    const extra: Record<string, unknown> = {};
    if (tags.length > 0) extra.tags = tags;
    if (hasPin) {
      extra.pin_lat = pinLat;
      extra.pin_lng = pinLng;
    }
    if (Number.isFinite(alongM)) extra.along_m = alongM;
    if (difficultyDelta != null) extra.difficulty_delta = difficultyDelta;
    if (rideId) extra.ride_id = rideId;
    const baseRow = {
      tour_id: tourId,
      author_id: user.id,
      author_label: String(body.authorLabel || "").trim() || "Rider",
      rating: Math.round(rating),
      body: text.slice(0, 2000),
      status: "pending" as const,
    };
    let insert = await supabase
      .from("tour_reviews")
      .insert({ ...baseRow, ...extra })
      .select("id")
      .maybeSingle();
    if (insert.error && Object.keys(extra).length > 0) {
      insert = await supabase
        .from("tour_reviews")
        .insert(baseRow)
        .select("id")
        .maybeSingle();
    }
    const { data, error } = insert;
    if (error || !data?.id) {
      return NextResponse.json(
        { error: "insert_failed", note: error?.message },
        { status: 501 }
      );
    }

    const reviewMod = await moderateContent({
      kind: "review",
      text,
      rating: Math.round(rating),
    });
    try {
      await persistModeration({
        kind: "review",
        id: data.id,
        result: reviewMod,
      });
    } catch (e) {
      console.error("[community/tour] persist review", e);
    }

    const photoRows: { id: string; status: string }[] = [];
    const incoming = Array.isArray(body.photos) ? body.photos.slice(0, 4) : [];
    for (const p of incoming) {
      const storagePath = String(p.storagePath || "").trim();
      if (!storagePath) continue;
      if (!storagePath.startsWith(`${user.id}/`)) {
        continue;
      }
      const { data: photo, error: pErr } = await supabase
        .from("tour_photos")
        .insert({
          tour_id: tourId,
          author_id: user.id,
          storage_path: storagePath.slice(0, 500),
          caption: String(p.caption || "").slice(0, 200),
          status: "pending",
          review_id: data.id,
        })
        .select("id, storage_path, caption")
        .maybeSingle();
      if (pErr || !photo?.id) continue;
      let imageUrl: string | null = null;
      try {
        const admin = createAdminClient();
        const { data: signed } = await admin.storage
          .from("tour-photos")
          .createSignedUrl(photo.storage_path, 300);
        imageUrl = signed?.signedUrl ?? null;
      } catch {
        imageUrl = null;
      }
      const photoMod = await moderateContent({
        kind: "photo",
        text: String(photo.caption || ""),
        imageUrl,
      });
      try {
        await persistModeration({
          kind: "photo",
          id: photo.id,
          result: photoMod,
        });
      } catch (e) {
        console.error("[community/tour] persist photo", e);
      }
      photoRows.push({ id: photo.id, status: photoMod.action });
    }

    return NextResponse.json({
      ok: true,
      id: data.id,
      status: reviewMod.action,
      moderation: {
        source: reviewMod.source,
        confidence: reviewMod.confidence,
        labels: reviewMod.labels,
      },
      photos: photoRows,
    });
  } catch {
    return NextResponse.json(
      {
        error: "not_implemented",
        note: "Cloud submit needs login + tour_reviews table.",
      },
      { status: 501 }
    );
  }
}
