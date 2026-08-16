"use client";

import { useMemo } from "react";
import { buildCoachWatch } from "@/lib/ai/coachWatch";
import {
  mergeCoachInbox,
  unreadCoachCount,
  type CoachInboxItem,
} from "@/lib/ai/coachInbox";
import { useAppStore } from "@/store/useAppStore";

export function useCoachInbox(): {
  items: CoachInboxItem[];
  unread: number;
  overdue: CoachInboxItem[];
} {
  const bikes = useAppStore((s) => s.bikes);
  const rides = useAppStore((s) => s.rides);
  const intervals = useAppStore((s) => s.maintenanceIntervals);
  const profile = useAppStore((s) => s.riderProfile);
  const calibration = useAppStore((s) => s.rangeCalibration);
  const rideFeedbacks = useAppStore((s) => s.rideFeedbacks);
  const meta = useAppStore((s) => s.coachMeta);

  const notices = useMemo(
    () =>
      buildCoachWatch({
        bikes,
        rides,
        intervals,
        profile,
        calibration,
        rideFeedbacks,
      }),
    [bikes, rides, intervals, profile, calibration, rideFeedbacks]
  );

  const items = useMemo(
    () => mergeCoachInbox(notices, meta),
    [notices, meta]
  );

  return {
    items,
    unread: unreadCoachCount(items),
    overdue: items.filter((i) => i.severity === "overdue"),
  };
}
