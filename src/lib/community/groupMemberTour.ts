import { needsMemberTrack } from "@/lib/community/rideGroup";
import type { RideGroup } from "@/lib/community/types";
import type { RideGroupInvitePayload } from "@/lib/community/rideGroupInvite";
import {
  buildTourSharePayload,
  parseTourShareMap,
  savedRouteFromTourShare,
} from "@/lib/community/shareCodec";
import type { SharedTourPayload } from "@/lib/community/shareTypes";
import type { SavedRoute } from "@/types/route";

/** Invite-Token-Limit inkl. eingebetteter Spur (WhatsApp/SMS). */
export const MAX_GROUP_INVITE_TOKEN_CHARS = 2400;

/** Private Host-GPX: Spur ins Invite, nicht auf Explore. */
export function tourShareForGroupInvite(input: {
  savedRouteId: string;
  catalogTourId?: string | null;
  route?: SavedRoute | null;
}): SharedTourPayload | undefined {
  const route = input.route;
  if (!route) return undefined;
  if (
    !needsMemberTrack({
      savedRouteId: input.savedRouteId,
      catalogTourId: input.catalogTourId ?? route.catalogTourId,
    })
  ) {
    return undefined;
  }
  return buildTourSharePayload(route);
}

/** Gast-Kopie mit Host-Id, damit Losfahren matcht. Ohne Spur: null. */
export function importMemberTourFromInvite(input: {
  payload?: RideGroupInvitePayload | null;
  existing: SavedRoute[];
}): SavedRoute | null {
  const payload = input.payload;
  if (!payload) return null;
  if (
    !needsMemberTrack({
      savedRouteId: payload.savedRouteId,
      catalogTourId: payload.catalogTourId,
    })
  ) {
    return null;
  }
  if (input.existing.some((r) => r.id === payload.savedRouteId)) return null;
  const tour = parseTourShareMap(payload.tour);
  if (!tour) return null;
  return savedRouteFromTourShare(tour, payload.savedRouteId);
}

export function tourForInviteGroup(
  group: Pick<RideGroup, "savedRouteId" | "catalogTourId">,
  route?: SavedRoute | null
): SharedTourPayload | undefined {
  return tourShareForGroupInvite({
    savedRouteId: group.savedRouteId,
    catalogTourId: group.catalogTourId,
    route,
  });
}
