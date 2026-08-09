import { createHmac, timingSafeEqual } from "node:crypto";

type StatePayload = {
  uid: string;
  exp: number;
  mobile?: boolean;
};

function secret(): string | null {
  return (
    process.env.STRAVA_STATE_SECRET?.trim() ||
    process.env.STRAVA_CLIENT_SECRET?.trim() ||
    null
  );
}

export function signStravaOAuthState(
  userId: string,
  opts?: { mobile?: boolean }
): string {
  const s = secret();
  if (!s) throw new Error("missing_strava_secret");
  const payload: StatePayload = {
    uid: userId,
    exp: Date.now() + 10 * 60 * 1000,
    mobile: opts?.mobile === true,
  };
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const sig = createHmac("sha256", s).update(body).digest("base64url");
  return `${body}.${sig}`;
}

export function verifyStravaOAuthState(
  state: string
): { userId: string; mobile: boolean } | null {
  const s = secret();
  if (!s) return null;
  const [body, sig] = state.split(".");
  if (!body || !sig) return null;
  const expected = createHmac("sha256", s).update(body).digest("base64url");
  try {
    const a = Buffer.from(sig);
    const b = Buffer.from(expected);
    if (a.length !== b.length || !timingSafeEqual(a, b)) return null;
  } catch {
    return null;
  }
  try {
    const data = JSON.parse(
      Buffer.from(body, "base64url").toString("utf8")
    ) as StatePayload;
    if (typeof data.uid !== "string" || typeof data.exp !== "number") {
      return null;
    }
    if (Date.now() > data.exp) return null;
    return { userId: data.uid, mobile: data.mobile === true };
  } catch {
    return null;
  }
}
