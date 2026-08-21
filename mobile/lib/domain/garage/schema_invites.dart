import '../component.dart';

/// Open schema chips: due always, at most two empty invitations.
/// Frame is the bike — not a missing part. Quiet-fit slots stay off the chips.
/// Keep in sync with src/lib/garage/schema/invites.ts
const kSchemaInviteOpenMax = 2;

bool schemaInviteSkips<T>(T slot) {
  if (slot is ComponentSlot) {
    return slot == ComponentSlot.frame ||
        slot == ComponentSlot.headset ||
        slot == ComponentSlot.frontHub ||
        slot == ComponentSlot.frontRim ||
        slot == ComponentSlot.rotorFront;
  }
  switch ('$slot') {
    case 'frame':
    case 'headset':
    case 'front_hub':
    case 'frontHub':
    case 'front_rim':
    case 'frontRim':
    case 'rotor_front':
    case 'rotorFront':
      return true;
    default:
      return false;
  }
}

/// Anatomy stays on the silhouette — quieter than an invitation.
bool schemaHotspotQuiet<T>(T slot, {required bool missing}) {
  return missing && schemaInviteSkips(slot);
}

List<T> _openInviteSlots<T>({
  required List<T> hotspotSlots,
  required Set<T> installed,
  Set<T>? due,
}) {
  final dueSet = due ?? <T>{};
  return [
    for (final s in hotspotSlots)
      if (!installed.contains(s) &&
          !dueSet.contains(s) &&
          !schemaInviteSkips(s))
        s,
  ];
}

List<T> schemaInviteSlots<T>({
  required List<T> hotspotSlots,
  required Set<T> installed,
  Set<T>? due,
  int maxOpen = kSchemaInviteOpenMax,
}) {
  final dueSet = due ?? <T>{};
  final dueShown = [
    for (final s in hotspotSlots)
      if (dueSet.contains(s)) s
  ];
  return [
    ...dueShown,
    ..._openInviteSlots(
      hotspotSlots: hotspotSlots,
      installed: installed,
      due: due,
    ).take(maxOpen)
  ];
}

int schemaHiddenOpenCount<T>({
  required List<T> hotspotSlots,
  required Set<T> installed,
  Set<T>? due,
  int maxOpen = kSchemaInviteOpenMax,
}) {
  final open = _openInviteSlots(
    hotspotSlots: hotspotSlots,
    installed: installed,
    due: due,
  ).length;
  final hidden = open - maxOpen;
  return hidden < 0 ? 0 : hidden;
}
