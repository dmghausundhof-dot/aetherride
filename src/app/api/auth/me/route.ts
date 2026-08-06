import { NextResponse } from "next/server";
import { findUserById, publicUser } from "@/lib/auth/userStore";
import {
  getSessionFromCookies,
  isAuthSecretHardened,
} from "@/lib/auth/serverSession";
import {
  authBackendLabelDe,
  getAuthBackend,
} from "@/lib/supabase/config";
import { oauthPrepSummaryDe } from "@/lib/auth/oauthPrep";

export async function GET() {
  const backend = getAuthBackend();
  const sessionUser = await getSessionFromCookies();

  if (!sessionUser) {
    return NextResponse.json({
      user: null,
      syncEnabled: false,
      authBackend: backend,
      authBackendLabel: authBackendLabelDe(backend),
      authSecretHardened: isAuthSecretHardened(),
      oauthPrep: oauthPrepSummaryDe(),
    });
  }

  if (backend === "supabase") {
    return NextResponse.json({
      user: sessionUser,
      syncEnabled: true,
      authBackend: backend,
      authBackendLabel: authBackendLabelDe(backend),
      authSecretHardened: isAuthSecretHardened(),
      oauthPrep: oauthPrepSummaryDe(),
    });
  }

  const stored = await findUserById(sessionUser.id);
  if (!stored) {
    return NextResponse.json({
      user: null,
      syncEnabled: false,
      authBackend: backend,
      authBackendLabel: authBackendLabelDe(backend),
      authSecretHardened: isAuthSecretHardened(),
      oauthPrep: oauthPrepSummaryDe(),
    });
  }
  return NextResponse.json({
    user: publicUser(stored),
    syncEnabled: true,
    authBackend: backend,
    authBackendLabel: authBackendLabelDe(backend),
    authSecretHardened: isAuthSecretHardened(),
    oauthPrep: oauthPrepSummaryDe(),
  });
}
