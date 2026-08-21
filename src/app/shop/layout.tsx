import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";
import { isShopEnabled } from "@/lib/shop/shopEnabled";
import { ShopPaused } from "@/components/shop/ShopPaused";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.shopTitle,
    description: c.shopHint,
  }));

export default function ShopLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  if (!isShopEnabled()) return <ShopPaused />;
  return children;
}
