/**
 * Community API — local-first on mobile; cloud when Supabase tables exist.
 */
import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { createAuthedClient } from "@/lib/supabase/authed";

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

export async function GET(req: Request) {
  const url = new URL(req.url);
  const tourId = url.searchParams.get("tourId");
  if (!tourId) {
    return NextResponse.json({ error: "tourId required" }, { status: 400 });
  }
  const client = sb();
  if (client) {
    const [{ data: reviews, error: rErr }, { data: photos, error: pErr }] =
      await Promise.all([
        client
          .from("tour_reviews")
          .select(
            "id, tour_id, author_label, rating, body, status, created_at"
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
    if (!rErr && !pErr) {
      const signed = await signTourPhotoUrls(client, photos ?? []);
      return NextResponse.json({
        tourId,
        reviews: reviews ?? [],
        photos: signed,
        stub: false,
      });
    }
  }
  return NextResponse.json({
    tourId,
    reviews: [],
    photos: [],
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
    };
    const tourId = String(body.tourId || "").trim();
    const rating = Number(body.rating);
    const text = String(body.body || "").trim();
    if (!tourId || !Number.isFinite(rating) || rating < 1 || rating > 5) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }
    const { data, error } = await supabase
      .from("tour_reviews")
      .insert({
        tour_id: tourId,
        author_id: user.id,
        author_label: String(body.authorLabel || "").trim() || "Rider",
        rating: Math.round(rating),
        body: text.slice(0, 2000),
        status: "pending",
      })
      .select("id")
      .maybeSingle();
    if (error) {
      return NextResponse.json(
        { error: "insert_failed", note: error.message },
        { status: 501 }
      );
    }
    return NextResponse.json({ ok: true, id: data?.id, status: "pending" });
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
