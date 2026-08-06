import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { appUrl } from "@/lib/stripe";

/**
 * OAuth start — requires provider enabled in Supabase Auth.
 * Spec F-ACC-001: Apple / Google.
 */
export async function POST(req: Request) {
  try {
    const body = await req.json();
    const provider = body.provider as "google" | "apple";
    if (provider !== "google" && provider !== "apple") {
      return NextResponse.json({ error: "invalid provider" }, { status: 400 });
    }

    const supabase = await createClient();
    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${appUrl()}/auth/callback`,
      },
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ url: data.url });
  } catch (e) {
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "oauth failed" },
      { status: 500 }
    );
  }
}
