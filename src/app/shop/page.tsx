import { Suspense } from "react";
import { ShopGateway } from "@/components/shop/ShopGateway";
import { ShopLoading } from "@/components/shop/ShopLoading";

export default function ShopPage() {
  return (
    <Suspense fallback={<ShopLoading />}>
      <ShopGateway />
    </Suspense>
  );
}
