import { redirect } from "next/navigation";
import { shopListingHref } from "@/lib/shop/listingRedirect";

type Props = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

/** featured-parts listing — Query bleibt, Tür „Für dein Rad“. */
export default async function ShopPartsRedirect({ searchParams }: Props) {
  redirect(shopListingHref(await searchParams));
}
