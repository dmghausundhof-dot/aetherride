import { NextRequest, NextResponse } from "next/server";
import { isPlausibleEmail } from "@/lib/auth/session";
import { authenticateEmail, publicUser } from "@/lib/auth/userStore";
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
    };
    const email = body.email?.trim() ?? "";
    const password = body.password ?? "";
    if (!isPlausibleEmail(email) || !password) {
      return NextResponse.json(
        { error: "E-Mail und Passwort erforderlich." },
        { status: 400 }
      );
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
      authSecretHardened: isAuthSecretHardened(),
    });
  } catch (e) {
    console.error("[auth/login]", e);
    return NextResponse.json({ error: "Login fehlgeschlagen." }, { status: 500 });
  }
}
