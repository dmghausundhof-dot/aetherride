import Link from "next/link";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { HofPageHeader } from "@/components/hof/HofPageHeader";

/** In-app cart retired — kasse is Shopify. */
export default function CheckoutPage() {
  return (
    <div className="mx-auto max-w-lg px-5 py-10">
      <HofPageHeader
        kicker={HOF_COPY.shopKicker}
        title={HOF_COPY.checkoutTitle}
        hint={HOF_COPY.checkoutHint}
      />
      <Link
        href="/shop"
        className="mt-6 inline-flex h-12 w-full items-center justify-center rounded-xl bg-chrome text-sm font-semibold text-background"
      >
        {HOF_COPY.shopTitle}
      </Link>
    </div>
  );
}
