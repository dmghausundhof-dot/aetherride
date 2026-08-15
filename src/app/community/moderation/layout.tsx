import type { ReactNode } from "react";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Community-Moderation",
  robots: { index: false, follow: false },
};

export default function ModerationLayout({
  children,
}: {
  children: ReactNode;
}) {
  return children;
}
