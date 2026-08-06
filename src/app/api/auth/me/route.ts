import { NextResponse } from "next/server";
import { findUserById, publicUser } from "@/lib/auth/userStore";
import {
  getSessionFromCookies,
  isAuthSecretHardened,
} from "@/lib/auth/serverSession";

export async function GET() {
  const sessionUser = await getSessionFromCookies();
  if (!sessionUser) {
    return NextResponse.json({
      user: null,
      syncEnabled: false,
      authSecretHardened: isAuthSecretHardened(),
    });
  }
  const stored = await findUserById(sessionUser.id);
  if (!stored) {
    return NextResponse.json({
      user: null,
      syncEnabled: false,
      authSecretHardened: isAuthSecretHardened(),
    });
  }
  return NextResponse.json({
    user: publicUser(stored),
    syncEnabled: true,
    authSecretHardened: isAuthSecretHardened(),
  });
}
