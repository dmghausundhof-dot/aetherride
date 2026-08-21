import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.homeTitle,
    description: c.homeHint,
  }));

export default function HomeLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
