/**
 * /shop/parts · /teile · /parts → Hub, Query bleibt (slot, bike, fit).
 */
export function shopListingHref(
  sp: Record<string, string | string[] | undefined>
): string {
  const params = new URLSearchParams();
  params.set("door", "parts");
  for (const [key, value] of Object.entries(sp)) {
    if (key === "door") continue;
    if (typeof value !== "string" || value.length === 0) continue;
    params.set(key, value);
  }
  return `/shop?${params.toString()}`;
}
