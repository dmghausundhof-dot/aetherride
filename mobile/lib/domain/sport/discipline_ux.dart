import '../bike.dart';

/// Multi-Sport UX: Labels & Copy, die alle Fahrer:innen ansprechen —
/// MTB, Gravel, Rennrad, City, E-Bike — ohne Trail-only Framing.
///
/// Routing/API-IDs bleiben technisch; hier nur Sprache & IA.

/// Sport-Familien für Filter-Chips und Defaults (breiter als einzelne Kategorie).
enum SportFamily {
  mtb,
  gravel,
  road,
  urban,
  ebike,
  other,
}

extension BikeCategoryUx on BikeCategory {
  SportFamily get family => switch (this) {
        BikeCategory.mtbTrail ||
        BikeCategory.mtbAm ||
        BikeCategory.mtbEnduro ||
        BikeCategory.dh =>
          SportFamily.mtb,
        BikeCategory.gravel => SportFamily.gravel,
        BikeCategory.road => SportFamily.road,
        BikeCategory.urban => SportFamily.urban,
        BikeCategory.emtb || BikeCategory.etrekking => SportFamily.ebike,
        BikeCategory.hiking => SportFamily.other,
      };

  /// Kurzer, inklusiver Anzeigename (UI).
  String get shortLabel => switch (this) {
        BikeCategory.mtbTrail => 'MTB Trail',
        BikeCategory.mtbAm => 'MTB',
        BikeCategory.mtbEnduro => 'Enduro',
        BikeCategory.dh => 'Downhill',
        BikeCategory.gravel => 'Gravel',
        BikeCategory.road => 'Rennrad',
        BikeCategory.urban => 'City',
        BikeCategory.emtb => 'E-MTB',
        BikeCategory.etrekking => 'E-Trekking',
        BikeCategory.hiking => 'Zu Fuß',
      };

  /// Einzeiler für Onboarding / Kacheln.
  String get blurb => switch (this) {
        BikeCategory.mtbTrail => 'Singletrails & Wald',
        BikeCategory.mtbAm => 'Trails & Touren',
        BikeCategory.mtbEnduro => 'Steil & technisch',
        BikeCategory.dh => 'Bikepark & Abfahrt',
        BikeCategory.gravel => 'Schotter & Distanz',
        BikeCategory.road => 'Asphalt & Tempo',
        BikeCategory.urban => 'Alltag & Pendeln',
        BikeCategory.emtb => 'Trail mit Assist',
        BikeCategory.etrekking => 'Touren mit Assist',
        BikeCategory.hiking => 'Zu Fuß unterwegs',
      };

  /// Ob Setup/SAG/Fahrwerk relevant ist (nicht City-Pendler-Default).
  bool get showsSuspensionUx => switch (this) {
        BikeCategory.mtbTrail ||
        BikeCategory.mtbAm ||
        BikeCategory.mtbEnduro ||
        BikeCategory.dh ||
        BikeCategory.emtb ||
        BikeCategory.gravel =>
          true,
        _ => false,
      };

  /// Ob „Fahrwerk“-Layer im Ride Sinn ergibt.
  bool get showsChassisLayer => showsSuspensionUx;
}

/// Onboarding-Kacheln — bewusst alle Kern-Disziplinen gleichwertig.
class OnboardingSportOption {
  const OnboardingSportOption({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
  });

  final BikeCategory id;
  final String label;
  final String blurb;
  final String icon; // Material icon name hint for UI

  static const List<OnboardingSportOption> all = [
    OnboardingSportOption(
      id: BikeCategory.mtbAm,
      label: 'MTB',
      blurb: 'Trails & Touren',
      icon: 'terrain',
    ),
    OnboardingSportOption(
      id: BikeCategory.mtbEnduro,
      label: 'Enduro',
      blurb: 'Steil & technisch',
      icon: 'landscape',
    ),
    OnboardingSportOption(
      id: BikeCategory.gravel,
      label: 'Gravel',
      blurb: 'Schotter & Distanz',
      icon: 'route',
    ),
    OnboardingSportOption(
      id: BikeCategory.road,
      label: 'Rennrad',
      blurb: 'Asphalt & Tempo',
      icon: 'speed',
    ),
    OnboardingSportOption(
      id: BikeCategory.urban,
      label: 'City',
      blurb: 'Alltag & Pendeln',
      icon: 'location_city',
    ),
    OnboardingSportOption(
      id: BikeCategory.emtb,
      label: 'E-MTB',
      blurb: 'Trail mit Assist',
      icon: 'electric_bike',
    ),
    OnboardingSportOption(
      id: BikeCategory.etrekking,
      label: 'E-Trekking',
      blurb: 'Touren mit Assist',
      icon: 'electric_moped',
    ),
    OnboardingSportOption(
      id: BikeCategory.mtbTrail,
      label: 'Trail',
      blurb: 'Singletrail-Fokus',
      icon: 'forest',
    ),
  ];
}

/// DE-Fallback-Kopien (Multi-Sport) für Tests / domain ohne [BuildContext].
///
/// UI soll [AppLocalizations] (+ `l10n_ext.dart`) nutzen — Locale `de`/`en`.
abstract final class MultiSportCopy {
  static const appTagline =
      'Für MTB, Gravel, Rennrad, City & E-Bike — eine App fürs Rad.';

  static const navHome = 'Home';
  static const navGarage = 'Garage';
  static const navRide = 'Fahren';
  static const navDiscover = 'Touren';
  static const navParts = 'Teile';

  static const searchHome = 'Wohin willst du? Ort, Tour oder Adresse';
  static const startRide = 'Fahrt starten';
  static const startFreeride = 'Ohne Route fahren';
  static const startWithRoute = 'Route fahren';
  static const goRide = 'Losfahren';
  static const readyTitle = 'Bereit zum Fahren';
  static const readyMessage =
      'GPS-Track startet sofort. Sensoren und Route sind optional — '
      'egal ob Trail, Asphalt oder City.';
  static const optionalRoute =
      'Optional: unter Touren eine Route wählen und „Losfahren“.';
  static const discoverMenuPhotos = 'Umgebungsfotos';
  static const discoverMenuOffline = 'Offline-Karten';
  static const discoverMenuCollections = 'Sammlungen';
  static const discoverMenuPrivacy = 'Heatmap & Privatsphäre';
  static const partsTitle = 'Teile & Zubehör';
  static const partsSubtitle =
      'Live featured-parts in AetherRide — Soft-Fit & Preise, '
      'ohne Shopify-Passwort-Dead-End.';
  static const weatherFallback = 'Wetter nicht verfügbar';
  static const statsRidesOne = 'Fahrt';
  static const statsRidesMany = 'Fahrten';

  /// Untertitel unter der Begrüßung — sportabhängig (DE-Fallback).
  static String homeSubtitle({
    BikeCategory? sport,
    String? weatherLine,
  }) {
    final base = switch (sport?.family) {
      SportFamily.mtb => 'Trails, Touren & dein Setup',
      SportFamily.gravel => 'Schotter, Distanz & Navigation',
      SportFamily.road => 'Asphalt, Tempo & Training',
      SportFamily.urban => 'Pendeln, Stadt & Alltag',
      SportFamily.ebike => 'Assist, Reichweite & Touren',
      SportFamily.other || null => 'Jede Art zu fahren — dein Rad, deine Route',
    };
    if (weatherLine == null || weatherLine.isEmpty) return base;
    return '$weatherLine · $base';
  }

  /// Tip-Hero-Titel je Sport (DE-Fallback).
  static String tipHeroTitle(BikeCategory? sport) => switch (sport?.family) {
        SportFamily.mtb => 'Heute raus aufs Rad',
        SportFamily.gravel => 'Heute Schotter oder Mix',
        SportFamily.road => 'Heute Asphalt-Kilometer',
        SportFamily.urban => 'Heute durch die Stadt',
        SportFamily.ebike => 'Heute mit Assist unterwegs',
        _ => 'Heute passt eine Fahrt',
      };

  static String tipHeroSubtitle(BikeCategory? sport) => switch (sport?.family) {
        SportFamily.mtb => 'Route wählen oder einfach freifahren — Track lokal.',
        SportFamily.gravel => 'Plane eine Distanz oder starte ohne Route.',
        SportFamily.road => 'Runde bauen oder freies Training aufzeichnen.',
        SportFamily.urban => 'Pendeln tracken oder kurze Runde speichern.',
        SportFamily.ebike => 'Tour planen und Reichweite im Blick behalten.',
        _ => 'MTB, Gravel, Rennrad oder City — alles hier.',
      };

  /// Layer-Label: Fahrwerk nur wenn relevant, sonst „Sensorik“ (DE-Fallback).
  static String chassisLayerLabel(BikeCategory? sport) =>
      (sport?.showsChassisLayer ?? true) ? 'Fahrwerk' : 'Sensorik';
}
