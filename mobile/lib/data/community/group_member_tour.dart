import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/tours/tour_akte.dart';
import 'ride_group_invite.dart';
import 'tour_share_codec.dart';

/// Invite-Token-Limit inkl. eingebetteter Spur (WhatsApp/SMS).
const maxGroupInviteTokenChars = 2400;

/// Private Host-GPX: Spur ins Invite, nicht auf Explore.
Map<String, dynamic>? tourShareForGroupInvite({
  required String savedRouteId,
  String? catalogTourId,
  SavedRouteEntry? route,
  SavedRouteMeta? meta,
}) {
  if (route == null) return null;
  if (!needsMemberTrack(
    savedRouteId: savedRouteId,
    catalogTourId: catalogTourId ?? meta?.catalogTourId,
  )) {
    return null;
  }
  return buildTourSharePayload(route, meta: meta ?? SavedRouteMeta.empty);
}

/// Gast-Kopie mit Host-Id, damit Losfahren matcht. Ohne Spur: null.
SavedRouteEntry? importMemberTourFromInvite({
  required RideGroupInvitePayload? payload,
  required List<SavedRouteEntry> existing,
}) {
  if (payload == null) return null;
  if (!needsMemberTrack(
    savedRouteId: payload.savedRouteId,
    catalogTourId: payload.catalogTourId,
  )) {
    return null;
  }
  if (existing.any((r) => r.id == payload.savedRouteId)) return null;
  final tour = payload.tour;
  if (tour == null) return null;
  return savedRouteFromTourShare(
    tour: tour,
    keepId: payload.savedRouteId,
  );
}
