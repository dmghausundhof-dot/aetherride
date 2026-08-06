import { NextRequest, NextResponse } from "next/server";
import { isPlausibleEmail } from "@/lib/auth/session";
import { assertPasswordPolicy } from "@/lib/auth/password";
import { createEmailUser, publicUser } from "@/lib/auth/userStore";
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
      displayName?: string;
    };
    const email = body.email?.trim() ?? "";
    const password = body.password ?? "";
    if (!isPlausibleEmail(email)) {
      return NextResponse.json(
        { error: "Ungültige E-Mail." },
        { status: 400 }
      );
    }
    const policy = assertPasswordPolicy(password);
    if (policy) {
      return NextResponse.json({ error: policy }, { status: 400 });
    }

    if (getAuthBackend() === "supabase") {
      const { createSupabaseServerClient } = await import(
        "@/lib/supabase/server"
      );
      const supabase = await createSupabaseServerClient();
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            display_name:
              body.displayName?.trim() || email.split("@")[0] || "Fahrer",
          },
        },
      });
      if (error) {
        const msg = error.message.toLowerCase();
        if (msg.includes("already") || msg.includes("registered")) {
          return NextResponse.json(
            { error: "E-Mail bereits registriert." },
            { status: 409 }
          );
        }
        return NextResponse.json({ error: error.message }, { status: 400 });
      }
      if (!data.user) {
        return NextResponse.json(
          { error: "Registrierung fehlgeschlagen." },
          { status: 500 }
        );
      }
      // E-Mail-Confirm ggf. ohne Session
      const mapped = authUserFromSupabase(data.user);
      if (data.session) {
        const { upsertProfileFromAuth } = await import(
          "@/lib/auth/profileStore"
        );
        await upsertProfileFromAuth({
          id: mapped.id,
          email: mapped.email,
          displayName: mapped.displayName,
        });
      }
      if (!data.session) {
        return NextResponse.json({
          user: mapped,
          syncEnabled: false,
          pendingEmailConfirmation: true,
          authBackend: "supabase",
          authSecretHardened: isAuthSecretHardened(),
          note: "Bitte E-Mail bestätigen (falls in Supabase aktiviert), dann anmelden.",
        });
      }
      return NextResponse.json({
        user: mapped,
        syncEnabled: true,
        pendingEmailConfirmation: false,
        authBackend: "supabase",
        authSecretHardened: isAuthSecretHardened(),
      });
    }

    // Fallback: lokaler File-Store
    const user = await createEmailUser({
      email,
      password,
      displayName: body.displayName,
    });
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
    if (e instanceof Error && e.message === "EMAIL_TAKEN") {
      return NextResponse.json(
        { error: "E-Mail bereits registriert." },
        { status: 409 }
      );
    }
    console.error("[auth/register]", e);
    return NextResponse.json(
      { error: "Registrierung fehlgeschlagen." },
      { status: 500 }
    );
  }
}
