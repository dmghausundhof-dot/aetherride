import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.activitiesTitle,
    description: c.activitiesHint,
  }));

export default function ActivitiesLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
