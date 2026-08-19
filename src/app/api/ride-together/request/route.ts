/**
 * Anfrage: nur wenn beide gerade suchen und in der Zelle liegen.
 */
import { NextResponse } from "next/server";
import { togetherAuthed, togetherStub } from "@/lib/community/rideTogetherRoute";
import {
  expireStaleTogether,
  findOpenSessionForUser,
  isMissingTogetherTable,
  requestExpiresIso,
  resolveTogetherLabel,
  openSessionForUser,
  sessionMemberCount,
} from "@/lib/community/rideTogetherServer";
import {
  canAddSessionMember,
  pickRequestSession,
  togetherBucket,
} from "@/lib/community/rideTogether";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const auth = await togetherAuthed(req);
    if ("error" in auth) return auth.error;
    const { user, admin } = auth;
    const body = (await req.json()) as { toUserId?: string; label?: string };
    const toUserId = String(body.toUserId || "").trim();
    if (!toUserId || toUserId === user.id) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    await expireStaleTogether(admin);
    const nowIso = new Date().toISOString();
    const { data: looks, error: lookErr } = await admin
      .from("ride_together_looks")
      .select("user_id, lat, lng")
      .in("user_id", [user.id, toUserId])
      .gt("looking_until", nowIso);
    if (lookErr) {
      if (isMissingTogetherTable(lookErr)) {
        return togetherStub("Server-Tabelle fehlt — Zusammen nicht bereit.");
      }
      return NextResponse.json(
        { error: "query_failed", note: lookErr.message },
        { status: 501 }
      );
    }
    const self = (looks ?? []).find(
      (r: { user_id: string }) => String(r.user_id) === user.id
    );
    const other = (looks ?? []).find(
      (r: { user_id: string }) => String(r.user_id) === toUserId
    );
    if (!self || !other) {
      return NextResponse.json(
        { error: "not_looking", note: "Beide müssen gerade suchen." },
        { status: 409 }
      );
    }
    const bucket = togetherBucket(self.lat, self.lng, other.lat, other.lng);
    if (!bucket) {
      return NextResponse.json(
        { error: "too_far", note: "Nicht mehr in der Zelle." },
        { status: 409 }
      );
    }

    const { count } = await admin
      .from("ride_together_requests")
      .select("id", { count: "exact", head: true })
      .eq("from_user_id", user.id)
      .eq("status", "pending")
      .gt("expires_at", nowIso);
    if ((count ?? 0) >= 8) {
      return NextResponse.json({ error: "rate_limited" }, { status: 429 });
    }

    const { data: pending } = await admin
      .from("ride_together_requests")
      .select("id, from_user_id, to_user_id, group_id, status")
      .eq("from_user_id", user.id)
      .eq("to_user_id", toUserId)
      .eq("status", "pending")
      .gt("expires_at", nowIso)
      .maybeSingle();
    if (pending) {
      return NextResponse.json({
        me: user.id,
        requestId: pending.id,
        already: true,
        stub: false,
      });
    }

    const { data: profile } = await admin
      .from("public_profiles")
      .select("user_id, enabled, display_name, handle")
      .eq("user_id", user.id)
      .maybeSingle();
    const label = resolveTogetherLabel(profile, body.label);
    const fromGroup = await openSessionForUser(admin, user.id, label);
    const toGroup = await findOpenSessionForUser(admin, toUserId);
    const fromN = await sessionMemberCount(admin, fromGroup.id);
    const toN = toGroup ? await sessionMemberCount(admin, toGroup.id) : 0;
    const pick = pickRequestSession(fromN, toN);
    if (pick === "none") {
      return NextResponse.json(
        {
          error: "two_sessions",
          note: "Zwei geschlossene Gruppen — jede bleibt für sich. Code weitergeben.",
        },
        { status: 409 }
      );
    }
    const group = pick === "to" && toGroup ? toGroup : fromGroup;
    const n = pick === "to" && toGroup ? toN : fromN;
    if (!canAddSessionMember(n)) {
      return NextResponse.json(
        { error: "full", note: "Gruppe ist voll (20)." },
        { status: 409 }
      );
    }

    const { data: inserted, error } = await admin
      .from("ride_together_requests")
      .insert({
        from_user_id: user.id,
        to_user_id: toUserId,
        group_id: group.id,
        status: "pending",
        expires_at: requestExpiresIso(),
      })
      .select("id")
      .maybeSingle();
    if (error) {
      if (isMissingTogetherTable(error)) {
        return togetherStub("Server-Tabelle fehlt — Zusammen nicht bereit.");
      }
      return NextResponse.json(
        { error: "insert_failed", note: error.message },
        { status: 501 }
      );
    }
    return NextResponse.json({
      me: user.id,
      requestId: inserted?.id,
      group,
      stub: false,
    });
  } catch {
    return togetherStub("Zusammen braucht Login.");
  }
}
