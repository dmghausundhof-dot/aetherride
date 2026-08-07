String greetingLine({String? displayName, DateTime? now}) {
  final n = now ?? DateTime.now();
  final h = n.hour;
  final g = h < 5
      ? 'Gute Nacht'
      : h < 11
          ? 'Guten Morgen'
          : h < 17
              ? 'Guten Tag'
              : h < 22
                  ? 'Guten Abend'
                  : 'Gute Nacht';
  final name = displayName?.trim();
  return (name != null && name.isNotEmpty) ? '$g, $name' : g;
}

String avatarInitials({String? displayName, String? email}) {
  if (displayName != null && displayName.trim().isNotEmpty) {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
    }
    return displayName.substring(0, displayName.length.clamp(0, 2)).toUpperCase();
  }
  if (email != null && email.contains('@')) {
    return email.substring(0, 2).toUpperCase();
  }
  return 'AR';
}
