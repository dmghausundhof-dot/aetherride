"use client";

import { useSearchParams } from "next/navigation";
import { AuthCard } from "@/components/auth/AuthCard";
import { safeAppNextPath } from "@/lib/nav/marketingNav";

export function AnmeldenForm() {
  const searchParams = useSearchParams();
  const next = safeAppNextPath(searchParams.get("next"));
  return <AuthCard redirectTo={next} />;
}
