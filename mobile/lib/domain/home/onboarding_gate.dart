/// Onboarding-Overlay nur für echte Erstnutzung.
///
/// Ein vorhandenes Rad oder eine Fahrt heißt: der Hof ist schon bewohnt.
/// Timeout beim Laden darf das Overlay nicht erzwingen.
abstract final class OnboardingGate {
  static bool shouldShow({
    required bool? flaggedDone,
    required bool hasBike,
    required bool hasRide,
  }) {
    if (flaggedDone == true) return false;
    if (flaggedDone == null) return false;
    if (hasBike || hasRide) return false;
    return true;
  }
}
