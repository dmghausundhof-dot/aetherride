/**
 * Freeride-Suche: 90 s sichtbar in der GPS-Zelle. Keine Koordinaten der anderen.
 * POST { lat, lng, label?, stop? }
 */
import { NextResponse } from "next/server";
import { quantizeGroupCoord } from "@/lib/community/rideGroup";
import {
  expireStaleTogether,
  isMissingTogetherTable,
  lookBox,
  lookingUntilIso,
  nearbyFromLooks,
  resolveTogetherLabel,
  loadLabels,
  openSessionForUser,
  closeSoloSession,
  memberBundle,
} from "@/lib/community/rideTogetherServer";
import { isMissingRideGroupTable } from "@/lib/community/rideGroupServer";
import { togetherAuthed, togetherStub } from "@/lib/community/rideTogetherRoute";

export const dynamic = "force-dynamic";

export async function POST(req: Request) {
  try {
    const auth = await togetherAuthed(req);
    if ("error" in auth) return auth.error;
    const { user, admin } = auth;
    const body = (await req.json().catch(() => ({}))) as {
      lat?: number;
      lng?: number;
      label?: string;
      stop?: boolean;
    };

    if (body.stop === true) {
      await admin.from("ride_together_looks").delete().eq("user_id", user.id);
      await closeSoloSession(admin, user.id);
      return NextResponse.json({
        me: user.id,
        stopped: true,
        nearby: [],
        inbound: [],
        stub: false,
      });
    }

    const lat = Number(body.lat);
    const lng = Number(body.lng);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return NextResponse.json({ error: "invalid_body" }, { status: 400 });
    }

    const { data: profile } = await admin
      .from("public_profiles")
      .select("user_id, enabled, display_name, handle")
      .eq("user_id", user.id)
      .maybeSingle();
    const label = resolveTogetherLabel(profile, body.label);
    const q = quantizeGroupCoord(lat, lng);
    const until = lookingUntilIso();

    try {
      await expireStaleTogether(admin);
      const group = await openSessionForUser(admin, user.id, label);
      const { error: lookErr } = await admin.from("ride_together_looks").upsert({
        user_id: user.id,
        lat: q.lat,
        lng: q.lng,
        display_label: label,
        looking_until: until,
        updated_at: new Date().toISOString(),
      });
      if (lookErr) {
        if (isMissingTogetherTable(lookErr)) {
          return togetherStub("Server-Tabelle fehlt — Zusammen nicht bereit.");
        }
        return NextResponse.json(
          { error: "look_failed", note: lookErr.message },
          { status: 501 }
        );
      }

      const box = lookBox(q.lat, q.lng).box;
      const { data: looks } = await admin
        .from("ride_together_looks")
        .select("user_id, lat, lng, display_label, looking_until")
        .neq("user_id", user.id)
        .gt("looking_until", new Date().toISOString())
        .gte("lat", box.minLat)
        .lte("lat", box.maxLat)
        .gte("lng", box.minLng)
        .lte("lng", box.maxLng)
        .limit(40);

      const lookRows = (looks ?? []) as Array<{
        user_id: string;
        lat: number;
        lng: number;
        display_label?: string;
      }>;
      const labels = await loadLabels(
        admin,
        lookRows.map((r) => r.user_id)
      );
      const members = await memberBundle(admin, group.id);
      const nearby = nearbyFromLooks({
        selfLat: q.lat,
        selfLng: q.lng,
        selfId: user.id,
        looks: lookRows,
        labels,
        excludeUserIds: members.map((m) => m.userId),
      });

      const { data: inboundRows } = await admin
        .from("ride_together_requests")
        .select("id, from_user_id, status, expires_at")
        .eq("to_user_id", user.id)
        .eq("status", "pending")
        .gt("expires_at", new Date().toISOString());
      const fromIds = (inboundRows ?? []).map((r: { from_user_id: string }) =>
        String(r.from_user_id)
      );
      const inboundLabels = await loadLabels(admin, fromIds);
      const inbound = (inboundRows ?? []).map(
        (r: { id: string; from_user_id: string }) => ({
          id: String(r.id),
          fromUserId: String(r.from_user_id),
          label: inboundLabels.get(String(r.from_user_id)) ?? "",
        })
      );

      const { data: outboundRows } = await admin
        .from("ride_together_requests")
        .select("id, to_user_id, status, expires_at")
        .eq("from_user_id", user.id)
        .in("status", ["pending", "accepted", "declined"])
        .gt("expires_at", new Date().toISOString())
        .order("expires_at", { ascending: false })
        .limit(6);
      const toIds = (outboundRows ?? []).map((r: { to_user_id: string }) =>
        String(r.to_user_id)
      );
      const outboundLabels = await loadLabels(admin, toIds);
      const outbound = (outboundRows ?? []).map(
        (r: { id: string; to_user_id: string; status: string }) => ({
          id: String(r.id),
          toUserId: String(r.to_user_id),
          status: String(r.status),
          label: outboundLabels.get(String(r.to_user_id)) ?? "",
        })
      );

      return NextResponse.json({
        me: user.id,
        group,
        members,
        joinCode: group.joinCode,
        lookingUntil: until,
        nearby,
        inbound,
        outbound,
        stub: false,
      });
    } catch (err) {
      const e = err as { code?: string; message?: string };
      if (isMissingTogetherTable(e) || isMissingRideGroupTable(e)) {
        return togetherStub("Server-Tabelle fehlt — Zusammen nicht bereit.");
      }
      return NextResponse.json(
        { error: "look_failed", note: e.message },
        { status: 501 }
      );
    }
  } catch {
    return togetherStub("Zusammen braucht Login.");
  }
}
