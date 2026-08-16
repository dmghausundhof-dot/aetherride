/**
 * Widerruf von Tour-Share-Tokens: lokal immer, Server wenn eingeloggt.
 */

export async function revokeTourShareOnServer(
  routeId: string,
  epoch: number
): Promise<boolean> {
  if (!routeId || epoch < 1) return false;
  try {
    const res = await fetch("/api/community/tour-share-revoke", {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ routeId, epoch }),
    });
    return res.ok;
  } catch {
    return false;
  }
}

export async function isTourShareRevokedOnServer(
  routeId: string,
  tokenEpoch?: number
): Promise<boolean> {
  if (!routeId) return false;
  try {
    const q = new URLSearchParams({ routeId });
    if (tokenEpoch != null) q.set("epoch", String(tokenEpoch));
    const res = await fetch(`/api/community/tour-share-revoke?${q}`, {
      cache: "no-store",
    });
    if (!res.ok) return false;
    const data = (await res.json()) as { revoked?: boolean };
    return data.revoked === true;
  } catch {
    return false;
  }
}

const key = (routeId: string) => `fl-share-revoked:${routeId}`;

export function revokeTourShareLocally(routeId: string, epoch: number): void {
  if (typeof window === "undefined" || !routeId) return;
  try {
    window.localStorage.setItem(key(routeId), String(epoch));
  } catch {
    /* private mode */
  }
}

export function localRevokedEpoch(routeId: string): number {
  if (typeof window === "undefined" || !routeId) return 0;
  try {
    const n = Number(window.localStorage.getItem(key(routeId)) ?? 0);
    return Number.isFinite(n) ? n : 0;
  } catch {
    return 0;
  }
}

/** true = dieser Browser hat die Freigabe zurückgezogen (epoch im Token veraltet). */
export function isTourShareRevokedLocally(
  routeId: string,
  tokenEpoch?: number
): boolean {
  const revoked = localRevokedEpoch(routeId);
  if (revoked <= 0) return false;
  if (tokenEpoch == null) return true;
  return tokenEpoch <= revoked;
}
