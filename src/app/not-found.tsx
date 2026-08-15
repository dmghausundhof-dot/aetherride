import Link from "next/link";
import { HOF_COPY } from "@/lib/home/hofCopy";
import { HofEmpty } from "@/components/hof/HofEmpty";

export default function NotFound() {
  return (
    <div className="hof-safe-page mx-auto flex min-h-dvh max-w-lg flex-col justify-center px-5 py-16">
      <HofEmpty
        title={HOF_COPY.notFoundTitle}
        hint={HOF_COPY.notFoundHint}
        showDoors
      />
      <Link
        href="/home"
        className="mt-6 inline-flex h-12 items-center justify-center rounded-xl bg-chrome text-sm font-semibold text-background"
      >
        Zum Hof
      </Link>
    </div>
  );
}
