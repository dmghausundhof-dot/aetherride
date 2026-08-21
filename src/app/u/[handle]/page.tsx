import type { Metadata } from "next";
import { PublicProfileView } from "./PublicProfileView";
import {
  getEditorialProfile,
  listEditorialHandles,
} from "@/lib/community/editorialProfiles";
import {
  editorialPersonJsonLd,
  siteOrigin,
} from "@/lib/content/siteJsonLd";
import { chromeRequestLang } from "@/lib/i18n/hofDoorMeta";
import { profileCopy } from "@/lib/i18n/profileCopy";

type Props = { params: Promise<{ handle: string }> };

export function generateStaticParams() {
  return listEditorialHandles().map((handle) => ({ handle }));
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { handle } = await params;
  const editorial = getEditorialProfile(handle);
  if (!editorial) {
    const copy = profileCopy(await chromeRequestLang());
    return {
      title: copy.publicTitle,
      description: copy.publicHint,
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
  const normalized = handle.trim().toLowerCase();
  const editorial = getEditorialProfile(normalized);
  return (
    <>
      {editorial ? (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify(
              editorialPersonJsonLd(siteOrigin(), editorial),
            ),
          }}
        />
      ) : null}
      <PublicProfileView handle={normalized} />
    </>
  );
}
