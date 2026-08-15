import { redirect } from "next/navigation";

type Props = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

/** Catalog world retired — door lives on /shop. */
export default async function ShopPartsRedirect({ searchParams }: Props) {
  const sp = await searchParams;
  const params = new URLSearchParams();
  params.set("door", "parts");
  for (const [key, value] of Object.entries(sp)) {
    if (typeof value === "string") params.set(key, value);
  }
  redirect(`/shop?${params.toString()}`);
}
