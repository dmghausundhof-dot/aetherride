import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.libraryTitle,
    description: c.libraryHint,
  }));

export default function LibraryLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
