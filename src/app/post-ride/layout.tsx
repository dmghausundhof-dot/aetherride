import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.postRideTitle,
    description: c.postRideHint,
  }));

export default function PostRideLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
