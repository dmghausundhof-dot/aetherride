import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Planen – Route für alle Disziplinen",
  description:
    "Desktop-Planer für Rennrad, Gravel, MTB, E-Bike und City. Start, Via, Ziel — Navigation in der App.",
};

export default function PlannerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <div className="w-full">{children}</div>;
}
