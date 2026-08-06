import { NextResponse } from "next/server";
import { getOAuthPublicStatus } from "@/lib/auth/oauthPrep";

/** Öffentlicher OAuth-Status (keine Secrets) */
export async function GET() {
  return NextResponse.json(getOAuthPublicStatus());
}
