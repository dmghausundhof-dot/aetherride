import { createSign } from "crypto";

type ServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri?: string;
};

function b64url(input: string | Buffer): string {
  return Buffer.from(input)
    .toString("base64")
    .replace(/=+$/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

async function googleAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(
    JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: sa.token_uri || "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    })
  );
  const unsigned = `${header}.${claim}`;
  const signer = createSign("RSA-SHA256");
  signer.update(unsigned);
  signer.end();
  const signature = signer
    .sign(sa.private_key)
    .toString("base64")
    .replace(/=+$/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
  const assertion = `${unsigned}.${signature}`;

  const body = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion,
  });
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!res.ok) {
    throw new Error(`google_oauth_${res.status}`);
  }
  const data = (await res.json()) as { access_token?: string };
  if (!data.access_token) throw new Error("google_oauth_no_token");
  return data.access_token;
}

export type PlayVerifyResult =
  | {
      ok: true;
      mode: "google_api";
      subscriptionState?: string;
      expiryTimeMillis?: string;
    }
  | { ok: false; mode: "google_api"; error: string; status?: number };

/**
 * Verifies a Play subscription purchase via Android Publisher API (2A).
 * Prefers subscriptionsv2; falls back to legacy subscriptions.get.
 */
export async function verifyPlayPurchaseWithGoogle(params: {
  packageName: string;
  productId: string;
  purchaseToken: string;
  serviceAccountJson: string;
}): Promise<PlayVerifyResult> {
  let sa: ServiceAccount;
  try {
    sa = JSON.parse(params.serviceAccountJson) as ServiceAccount;
  } catch {
    return { ok: false, mode: "google_api", error: "invalid_service_account_json" };
  }
  if (!sa.client_email || !sa.private_key) {
    return { ok: false, mode: "google_api", error: "incomplete_service_account" };
  }

  let accessToken: string;
  try {
    accessToken = await googleAccessToken(sa);
  } catch (e) {
    return {
      ok: false,
      mode: "google_api",
      error: e instanceof Error ? e.message : "oauth_failed",
    };
  }

  const pkg = encodeURIComponent(params.packageName);
  const token = encodeURIComponent(params.purchaseToken);
  const v2Url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}/purchases/subscriptionsv2/tokens/${token}`;

  const v2 = await fetch(v2Url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (v2.ok) {
    const data = (await v2.json()) as {
      subscriptionState?: string;
      lineItems?: Array<{ expiryTime?: string }>;
    };
    const state = data.subscriptionState ?? "";
    const active =
      state === "SUBSCRIPTION_STATE_ACTIVE" ||
      state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" ||
      state === "SUBSCRIPTION_STATE_ON_HOLD";
    if (!active) {
      return {
        ok: false,
        mode: "google_api",
        error: `inactive:${state || "unknown"}`,
        status: 200,
      };
    }
    return {
      ok: true,
      mode: "google_api",
      subscriptionState: state,
      expiryTimeMillis: data.lineItems?.[0]?.expiryTime,
    };
  }

  // Legacy fallback (requires product / base plan id).
  const subId = encodeURIComponent(params.productId);
  const legacyUrl = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${pkg}/purchases/subscriptions/${subId}/tokens/${token}`;
  const legacy = await fetch(legacyUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!legacy.ok) {
    return {
      ok: false,
      mode: "google_api",
      error: `publisher_api_${v2.status}_${legacy.status}`,
      status: legacy.status,
    };
  }
  const data = (await legacy.json()) as {
    paymentState?: number;
    expiryTimeMillis?: string;
    cancelReason?: number;
  };
  // paymentState 1 = received; 2 = free trial; 3 = pending deferred
  const paid =
    data.paymentState === 1 ||
    data.paymentState === 2 ||
    data.paymentState === undefined;
  const notExpired =
    !data.expiryTimeMillis ||
    Number(data.expiryTimeMillis) > Date.now();
  if (!paid || !notExpired) {
    return {
      ok: false,
      mode: "google_api",
      error: "subscription_not_active",
      status: 200,
    };
  }
  return {
    ok: true,
    mode: "google_api",
    expiryTimeMillis: data.expiryTimeMillis,
  };
}
