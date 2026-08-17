import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Start",
  description:
    "Dein Rad und ein Knopf: Losfahren. Kein Feed.",
};

export default function HomeLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
