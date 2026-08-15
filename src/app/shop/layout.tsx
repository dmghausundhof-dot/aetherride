import type { Metadata } from "next";
import { HOF_COPY } from "@/lib/home/hofCopy";

export const metadata: Metadata = {
  title: HOF_COPY.shopTitle,
  description: HOF_COPY.shopHint,
};

export default function ShopLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
