import { NextResponse } from "next/server";
import { clearSessionCookie } from "@/lib/auth/serverSession";

export async function POST() {
  await clearSessionCookie();
  return NextResponse.json({ ok: true, syncEnabled: false });
}
