import type { Metadata } from "next";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { isShopEnabled } from "@/lib/shop/shopEnabled";
import { ShopPaused } from "@/components/shop/ShopPaused";

export const metadata: Metadata = {
  title: HOF_COPY.shopTitle,
  description: HOF_COPY.shopHint,
};

export default function ShopLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  if (!isShopEnabled()) return <ShopPaused />;
  return children;
}
