import { redirect } from "next/navigation";
import { shopListingHref } from "@/lib/shop/listingRedirect";

type Props = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

export default async function PartsAlias({ searchParams }: Props) {
  redirect(shopListingHref(await searchParams));
}
