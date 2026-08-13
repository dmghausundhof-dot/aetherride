import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Der Hof",
  description:
    "Das Rad wohnt hier. Himmel, eine Stunde vor dem Tor, Rausfahren.",
};

export default function HomeLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
