/// Heading helpers for the Ride HUD compass rose.
///
/// Not a Clean-Mode nav stat — overlay like Pause / media transport.
double normalizeHeadingDeg(double deg) {
  var n = deg % 360;
  if (n < 0) n += 360;
  return n;
}

/// German cardinals (N · NO · O · SO · S · SW · W · NW).
String compassCardinalDe(double headingDeg) {
  const labels = ['N', 'NO', 'O', 'SO', 'S', 'SW', 'W', 'NW'];
  final n = normalizeHeadingDeg(headingDeg);
  return labels[((n + 22.5) / 45).floor() % 8];
}

/// Degrees to rotate the rose so **N** points to geographic north on screen.
/// Heading-up maps already rotate with the rider → counteract heading.
/// North-up maps keep north at the top → 0.
double compassRoseDeg(double headingDeg, {required bool northUp}) {
  if (northUp) return 0;
  return -normalizeHeadingDeg(headingDeg);
}
