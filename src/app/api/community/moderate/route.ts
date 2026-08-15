/**
 * GET pending queue / POST human or AI drain.
 * Auth: x-moderation-key = COMMUNITY_MODERATION_SECRET
 *    or logged-in email in COMMUNITY_MODERATOR_EMAILS
 */
import { NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";
import { createAuthedClient } from "@/lib/supabase/authed";
import { moderateContent } from "@/lib/community/moderate";
import {
  isModeratorRequest,
  moderatorEmails,
  persistModeration,
} from "@/lib/community/persistModeration";

export const dynamic = "force-dynamic";

async function requireModerator(req: Request): Promise<NextResponse | null> {
  if (isModeratorRequest(req)) return null;
  const emails = moderatorEmails();
  if (emails.length) {
    try {
      const sb = await createAuthedClient(req);
      const {
        data: { user },
      } = await sb.auth.getUser();
      if (user?.email && emails.includes(user.email.toLowerCase())) {
        return null;
      }
    } catch {
      /* fall through */
    }
  }
  return NextResponse.json({ error: "unauthorized" }, { status: 401 });
}

export async function GET(req: Request) {
  const denied = await requireModerator(req);
  if (denied) return denied;
  const url = new URL(req.url);
  const status = url.searchParams.get("status") || "pending";
  const admin = createAdminClient();
  const [{ data: reviews, error: rErr }, { data: photos, error: pErr }] =
    await Promise.all([
      admin
        .from("tour_reviews")
        .select(
          "id, tour_id, author_label, rating, body, status, created_at, moderation_source, moderation_note, ai_labels, ai_confidence, ai_model"
        )
        .eq("status", status)
        .order("created_at", { ascending: true })
        .limit(50),
      admin
        .from("tour_photos")
        .select(
          "id, tour_id, storage_path, caption, status, created_at, moderation_source, moderation_note, ai_labels, ai_confidence, ai_model"
        )
        .eq("status", status)
        .order("created_at", { ascending: true })
        .limit(40),
    ]);
  if (rErr || pErr) {
    return NextResponse.json(
      { error: "query_failed", note: rErr?.message || pErr?.message },
      { status: 500 }
    );
  }
  const signed = await Promise.all(
    (photos ?? []).map(async (p) => {
      const path = String(p.storage_path || "");
      if (!path || path.startsWith("http")) return { ...p, url: path || null };
      const { data } = await admin.storage
        .from("tour-photos")
        .createSignedUrl(path, 600);
      return { ...p, url: data?.signedUrl ?? null };
    })
  );
  return NextResponse.json({
    status,
    reviews: reviews ?? [],
    photos: signed,
  });
}

export async function POST(req: Request) {
  const denied = await requireModerator(req);
  if (denied) return denied;
  const body = (await req.json()) as {
    kind?: "review" | "photo";
    id?: string;
    action?: "approved" | "rejected" | "hidden" | "pending";
    note?: string;
    drainAi?: boolean;
  };

  if (body.drainAi) {
    const admin = createAdminClient();
    const [{ data: reviews }, { data: photos }] = await Promise.all([
      admin
        .from("tour_reviews")
        .select("id, body, rating")
        .eq("status", "pending")
        .limit(15),
      admin
        .from("tour_photos")
        .select("id, caption, storage_path")
        .eq("status", "pending")
        .limit(8),
    ]);
    const out: { id: string; kind: string; action: string }[] = [];
    for (const r of reviews ?? []) {
      const result = await moderateContent({
        kind: "review",
        text: String(r.body || ""),
        rating: Number(r.rating) || undefined,
      });
      await persistModeration({ kind: "review", id: r.id, result });
      out.push({ id: r.id, kind: "review", action: result.action });
    }
    for (const p of photos ?? []) {
      let imageUrl: string | null = null;
      const path = String(p.storage_path || "");
      if (path.startsWith("http")) imageUrl = path;
      else if (path) {
        const { data } = await admin.storage
          .from("tour-photos")
          .createSignedUrl(path, 300);
        imageUrl = data?.signedUrl ?? null;
      }
      const result = await moderateContent({
        kind: "photo",
        text: String(p.caption || ""),
        imageUrl,
      });
      await persistModeration({ kind: "photo", id: p.id, result });
      out.push({ id: p.id, kind: "photo", action: result.action });
    }
    return NextResponse.json({ ok: true, processed: out });
  }

  const kind = body.kind;
  const id = String(body.id || "").trim();
  const action = body.action;
  if (
    (kind !== "review" && kind !== "photo") ||
    !id ||
    (action !== "approved" &&
      action !== "rejected" &&
      action !== "hidden" &&
      action !== "pending")
  ) {
    return NextResponse.json({ error: "invalid_body" }, { status: 400 });
  }
  await persistModeration({
    kind,
    id,
    result: {
      action: action === "hidden" ? "rejected" : action,
      source: "human",
      confidence: 1,
      labels: action === "hidden" ? ["hidden"] : ["human"],
      note: String(body.note || "").slice(0, 400) || `human ${action}`,
    },
  });
  if (action === "hidden") {
    const admin = createAdminClient();
    const table = kind === "photo" ? "tour_photos" : "tour_reviews";
    await admin.from(table).update({ status: "hidden" }).eq("id", id);
  }
  return NextResponse.json({ ok: true, id, action });
}
