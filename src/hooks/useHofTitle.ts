"use client";

import { useEffect, useState } from "react";
import { hofTitleFromNavigator } from "@/lib/home/hofTitle";

/** Country title after mount — avoids CH/DE hydration mismatch. */
export function useHofTitle(): string {
  const [title, setTitle] = useState("Start");
  useEffect(() => {
    setTitle(hofTitleFromNavigator());
  }, []);
  return title;
}
