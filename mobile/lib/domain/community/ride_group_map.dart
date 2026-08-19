import 'ride_group.dart';
import 'ride_group_policy.dart';
import 'stimme_pin.dart';

/// Static meeting pin for Browse — never a live GPS of a member.
class GroupMeetPin {
  const GroupMeetPin({
    required this.group,
    required this.lat,
    required this.lng,
    required this.label,
  });

  final RideGroup group;
  final double lat;
  final double lng;
  final String label;

  String get placeId => 'meet-${group.id}';
}

/// Public joinable groups (and own groups) as map pins.
/// Uses meeting coordinates when present, else [centerFor].
List<GroupMeetPin> groupMeetPinsOnExplore({
  required List<RideGroup> groups,
  required Set<String> memberGroupIds,
  required DateTime now,
  ({double lat, double lng})? Function(RideGroup group)? centerFor,
}) {
  final out = <GroupMeetPin>[];
  for (final g in groups) {
    if (!RideGroupPolicy.canShowMeetingOnExplore(
      g,
      isMember: memberGroupIds.contains(g.id),
      now: now,
    )) {
      continue;
    }
    final parsed = parseMeetingLatLng(g.meetingPoint);
    final fallback = centerFor?.call(g);
    final lat = parsed?.lat ?? fallback?.lat;
    final lng = parsed?.lng ?? fallback?.lng;
    if (lat == null || lng == null) continue;
    final label = (parsed?.label ?? g.meetingPoint ?? '').trim();
    out.add(
      GroupMeetPin(
        group: g,
        lat: lat,
        lng: lng,
        label: label.isEmpty ? g.title : label,
      ),
    );
  }
  return out;
}
