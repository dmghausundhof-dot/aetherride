import { NextResponse } from "next/server";
import { createAuthedClient } from "@/lib/supabase/authed";
import { createAdminClient } from "@/lib/supabase/admin";

export function togetherUnauthorized() {
  return NextResponse.json({ error: "unauthorized" }, { status: 401 });
}

export function togetherStub(note: string, status = 501) {
  return NextResponse.json(
    { error: "not_implemented", stub: true, note },
    { status }
  );
}

export async function togetherAuthed(req: Request) {
  const supabase = await createAuthedClient(req);
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return { error: togetherUnauthorized() };
  let admin;
  try {
    admin = createAdminClient();
  } catch {
    return {
      error: togetherStub("Service-Role fehlt — Zusammen bleibt lokal."),
    };
  }
  return { user, admin };
}
