import { NextRequest, NextResponse } from "next/server";
import { isPlausibleEmail } from "@/lib/auth/session";
import { authenticateEmail, publicUser } from "@/lib/auth/userStore";
import {
  createSessionToken,
  isAuthSecretHardened,
  setSessionCookie,
} from "@/lib/auth/serverSession";
import {
  authBackendLabelDe,
  getAuthBackend,
} from "@/lib/supabase/config";
import { authUserFromSupabase } from "@/lib/auth/supabaseUser";

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as {
      email?: string;
      password?: string;
    };
    const email = body.email?.trim() ?? "";
    const password = body.password ?? "";
    if (!isPlausibleEmail(email) || !password) {
      return NextResponse.json(
        { error: "E-Mail und Passwort erforderlich." },
        { status: 400 }
      );
    }

    if (getAuthBackend() === "supabase") {
      const { createSupabaseServerClient } = await import(
        "@/lib/supabase/server"
      );
      const supabase = await createSupabaseServerClient();
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (error || !data.user) {
        return NextResponse.json(
          { error: error?.message || "E-Mail oder Passwort falsch." },
          { status: 401 }
        );
      }
      const mapped = authUserFromSupabase(data.user);
      const { upsertProfileFromAuth } = await import(
        "@/lib/auth/profileStore"
      );
      await upsertProfileFromAuth({
        id: mapped.id,
        email: mapped.email,
        displayName: mapped.displayName,
      });
      return NextResponse.json({
        user: mapped,
        syncEnabled: true,
        authBackend: "supabase",
        authSecretHardened: isAuthSecretHardened(),
      });
    }

    const user = await authenticateEmail(email, password);
    if (!user) {
      return NextResponse.json(
        { error: "E-Mail oder Passwort falsch." },
        { status: 401 }
      );
    }
    const token = await createSessionToken({
      sub: user.id,
      email: user.email,
      displayName: user.displayName,
      provider: "email",
    });
    await setSessionCookie(token);
    return NextResponse.json({
      user: publicUser(user),
      syncEnabled: true,
      authBackend: "local_file",
      authSecretHardened: isAuthSecretHardened(),
      note: authBackendLabelDe("local_file"),
    });
  } catch (e) {
    console.error("[auth/login]", e);
    return NextResponse.json({ error: "Login fehlgeschlagen." }, { status: 500 });
  }
}
