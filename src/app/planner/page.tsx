import { redirect } from "next/navigation";
import { plannerHrefFromSearch } from "@/lib/explore/workspace";

type Props = {
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

/** Planen lebt auf der Karte — eine UI, ein Draft. */
export default async function PlannerRedirect({ searchParams }: Props) {
  redirect(plannerHrefFromSearch(await searchParams));
}
