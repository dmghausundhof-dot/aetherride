"use client";

import { useEffect } from "react";
import { useAppStore } from "@/store/useAppStore";

export function Providers({ children }: { children: React.ReactNode }) {
  const seedDemoData = useAppStore((s) => s.seedDemoData);

  useEffect(() => {
    // Seed demo data on first load if empty
    seedDemoData();
  }, [seedDemoData]);

  return <>{children}</>;
}
