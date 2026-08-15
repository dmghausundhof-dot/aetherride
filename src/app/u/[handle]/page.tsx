import type { Metadata } from "next";
import { PublicProfileView } from "./PublicProfileView";
import {
  getEditorialProfile,
  listEditorialHandles,
} from "@/lib/community/editorialProfiles";

type Props = { params: Promise<{ handle: string }> };

export function generateStaticParams() {
  return listEditorialHandles().map((handle) => ({ handle }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { handle } = await params;
  const editorial = getEditorialProfile(handle);
  if (!editorial) {
    return {
      title: "Profil",
      description:
        "Öffentliches FlowLine-Profil. Nur mit Opt-in, keine GPS-Spuren.",
      robots: { index: false, follow: true },
    };
  }
  return {
    title: `${editorial.displayName} (@${editorial.handle})`,
    description: editorial.bio,
  };
}

export default async function PublicProfilePage({ params }: Props) {
  const { handle } = await params;
  return <PublicProfileView handle={handle.trim().toLowerCase()} />;
}
