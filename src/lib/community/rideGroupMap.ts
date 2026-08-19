/**
 * Static meeting pins for Browse / Explore — never a live GPS of a member.
 */

import type { RideGroup } from "@/lib/community/types";
import { canShowMeetingOnExplore } from "@/lib/community/rideGroup";
import { parseMeetingLatLng } from "@/lib/community/placesMerger";

export type GroupMeetPin = {
  group: RideGroup;
  lat: number;
  lng: number;
  label: string;
  placeId: string;
};

export function groupMeetPinsOnExplore(input: {
  groups: RideGroup[];
  memberGroupIds: Iterable<string>;
  now?: Date;
  centerFor?: (
    group: RideGroup
  ) => { lat: number; lng: number } | null | undefined;
}): GroupMeetPin[] {
  const members = new Set(input.memberGroupIds);
  const now = input.now ?? new Date();
  const out: GroupMeetPin[] = [];
  for (const group of input.groups) {
    if (
      !canShowMeetingOnExplore({
        visibility: group.visibility,
        status: group.status,
        startWindowEnd: group.startWindowEnd,
        isMember: members.has(group.id),
        now,
      })
    ) {
      continue;
    }
    const parsed = parseMeetingLatLng(group.meetingPoint);
    const fallback = input.centerFor?.(group);
    const lat = parsed?.lat ?? fallback?.lat;
    const lng = parsed?.lng ?? fallback?.lng;
    if (lat == null || lng == null) continue;
    const label = (parsed?.label ?? group.meetingPoint ?? "").trim();
    out.push({
      group,
      lat,
      lng,
      label: label || group.title,
      placeId: `meet-${group.id}`,
    });
  }
  return out;
}
