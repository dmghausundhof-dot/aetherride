String greetingLine({
  String? displayName,
  DateTime? now,
  String languageCode = 'de',
}) {
  final n = now ?? DateTime.now();
  final g = timeOfDayGreeting(n.hour, languageCode);
  final name = displayName?.trim();
  return (name != null && name.isNotEmpty) ? '$g, $name' : g;
}

String timeOfDayGreeting(int hour, String languageCode) {
  final lang = languageCode.toLowerCase();
  if (lang.startsWith('en')) {
    if (hour < 5) return 'Good night';
    if (hour < 11) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 22) return 'Good evening';
    return 'Good night';
  }
  if (lang.startsWith('fr')) {
    if (hour < 5) return 'Bonne nuit';
    if (hour < 18) return 'Bonjour';
    if (hour < 22) return 'Bonsoir';
    return 'Bonne nuit';
  }
  if (lang.startsWith('it')) {
    if (hour < 5) return 'Buona notte';
    if (hour < 12) return 'Buongiorno';
    if (hour < 18) return 'Buon pomeriggio';
    if (hour < 22) return 'Buonasera';
    return 'Buona notte';
  }
  if (lang.startsWith('nl')) {
    if (hour < 5) return 'Goedenacht';
    if (hour < 12) return 'Goedemorgen';
    if (hour < 18) return 'Goedemiddag';
    if (hour < 22) return 'Goedenavond';
    return 'Goedenacht';
  }
  if (hour < 5) return 'Gute Nacht';
  if (hour < 11) return 'Guten Morgen';
  if (hour < 17) return 'Guten Tag';
  if (hour < 22) return 'Guten Abend';
  return 'Gute Nacht';
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
  return '?';
}
