import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Aktivitäten",
  description:
    "Fahrten analysieren: Stats, Track und Setup-Hinweise. Aufzeichnung in der AetherRide App.",
};

export default function ActivitiesLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
