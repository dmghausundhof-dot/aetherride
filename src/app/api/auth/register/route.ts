import { NextRequest, NextResponse } from "next/server";
import { isPlausibleEmail } from "@/lib/auth/session";
import { assertPasswordPolicy } from "@/lib/auth/password";
import { createEmailUser, publicUser } from "@/lib/auth/userStore";
import {
  createSessionToken,
  isAuthSecretHardened,
  setSessionCookie,
} from "@/lib/auth/serverSession";

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
      authSecretHardened: isAuthSecretHardened(),
    });
  } catch (e) {
    if (e instanceof Error && e.message === "EMAIL_TAKEN") {
      return NextResponse.json(
        { error: "E-Mail bereits registriert." },
        { status: 409 }
      );
    }
    console.error("[auth/register]", e);
    return NextResponse.json({ error: "Registrierung fehlgeschlagen." }, { status: 500 });
  }
}
