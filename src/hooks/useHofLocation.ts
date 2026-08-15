"use client";

import { useEffect, useState } from "react";

export type HofGeo = {
  lat: number;
  lng: number;
} | null;

/**
 * Optional GPS for sky + gate. Denied / missing → null (honest empty sky).
 */
export function useHofLocation(): { geo: HofGeo; resolved: boolean } {
  const [geo, setGeo] = useState<HofGeo>(null);
  const [resolved, setResolved] = useState(false);

  useEffect(() => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      setResolved(true);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setGeo({ lat: pos.coords.latitude, lng: pos.coords.longitude });
        setResolved(true);
      },
      () => {
        setGeo(null);
        setResolved(true);
      },
      { enableHighAccuracy: false, timeout: 8000, maximumAge: 10 * 60 * 1000 }
    );
  }, []);

  return { geo, resolved };
}
