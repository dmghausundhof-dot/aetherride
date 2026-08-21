import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.workshopTitle,
    description: c.workshopHint,
  }));

export default function GarageLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
