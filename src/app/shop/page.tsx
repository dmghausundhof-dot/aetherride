import { Suspense } from "react";
import { ShopGateway } from "@/components/shop/ShopGateway";
import { HOF_COPY } from "@/lib/home/hofCopy";

export default function ShopPage() {
  return (
    <Suspense
      fallback={
        <div className="mx-auto max-w-2xl p-4 pt-6 text-sm text-text-secondary">
          {HOF_COPY.shopTitle}…
        </div>
      }
    >
      <ShopGateway />
    </Suspense>
  );
}
