import { createAdminClient } from "@/lib/supabase/admin";
import type { ModerationKind, ModerationResult } from "@/lib/community/moderate";

export async function persistModeration(params: {
  kind: ModerationKind;
  id: string;
  result: ModerationResult;
}) {
  const admin = createAdminClient();
  const table = params.kind === "photo" ? "tour_photos" : "tour_reviews";
  const patch = {
    status: params.result.action,
    moderated_at: params.result.action === "pending" ? null : new Date().toISOString(),
    moderation_source: params.result.source,
    moderation_note: params.result.note,
    ai_labels: params.result.labels,
    ai_confidence: params.result.confidence,
    ai_model: params.result.model ?? null,
    updated_at:
      params.kind === "review" ? new Date().toISOString() : undefined,
  };
  if (params.kind === "photo") {
    delete (patch as { updated_at?: string }).updated_at;
  }
  const { error } = await admin.from(table).update(patch).eq("id", params.id);
  if (error) throw error;
}

export function isModeratorRequest(req: Request): boolean {
  const secret = process.env.COMMUNITY_MODERATION_SECRET?.trim();
  const header =
    req.headers.get("x-moderation-key")?.trim() ||
    (req.headers.get("authorization")?.toLowerCase().startsWith("bearer ")
      ? req.headers.get("authorization")!.slice(7).trim()
      : "");
  if (secret && header && header === secret) return true;
  return false;
}

export function moderatorEmails(): string[] {
  return (process.env.COMMUNITY_MODERATOR_EMAILS || "")
    .split(",")
    .map((s) => s.trim().toLowerCase())
    .filter(Boolean);
}
