import { hofDoorMeta } from "@/lib/i18n/hofDoorMeta";

export const generateMetadata = () =>
  hofDoorMeta((c) => ({
    title: c.profileTitle,
    description: c.profileHint,
  }));

export default function ProfileLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="mx-auto w-full max-w-xl px-0">
      {children}
    </div>
  );
}
