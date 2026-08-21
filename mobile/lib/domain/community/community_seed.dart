/// Redaktionelle Treffen — Spiegel von src/lib/community/seed.ts.
/// Kein Join, keine Live-Pins, keine erfundenen Teilnehmer.
class CommunityEventSeed {
  const CommunityEventSeed({
    required this.id,
    required this.title,
    required this.regionLabel,
    required this.dateLabel,
    required this.sport,
    required this.blurb,
    this.catalogTourId,
    this.regionSlug,
  });

  final String id;
  final String title;
  final String regionLabel;
  final String dateLabel;
  final String sport;
  final String blurb;
  final String? catalogTourId;
  final String? regionSlug;
}

class CommunityClubSeed {
  const CommunityClubSeed({
    required this.id,
    required this.name,
    required this.regionLabel,
    required this.sports,
    required this.blurb,
    this.regionSlug,
  });

  final String id;
  final String name;
  final String regionLabel;
  final List<String> sports;
  final String blurb;
  final String? regionSlug;
}

const communityClubSeeds = <CommunityClubSeed>[
  CommunityClubSeed(
    id: 'cl-rn-allround',
    name: 'Rhein-Neckar Allround',
    regionLabel: 'Rhein-Neckar',
    regionSlug: 'rhein-neckar',
    sports: ['road', 'gravel', 'urban'],
    blurb: 'Wöchentliche Gruppen — Disziplin rotiert. Anfänger willkommen.',
  ),
  CommunityClubSeed(
    id: 'cl-sw-trails',
    name: 'Schwarzwald Trail & Tour',
    regionLabel: 'Schwarzwald',
    regionSlug: 'schwarzwald',
    sports: ['mtb', 'gravel', 'ebike'],
    blurb: 'MTB und Gravel gemischt, Fokus auf sichere Linien und Trail-Etikette.',
  ),
  CommunityClubSeed(
    id: 'cl-by-lakes',
    name: 'Bayern Seenrunde',
    regionLabel: 'Bayern',
    regionSlug: 'bayern',
    sports: ['road', 'gravel', 'touring'],
    blurb: 'Seen, Flachland und Alpenvorland — Touring-lastig.',
  ),
];

const communityEventSeeds = <CommunityEventSeed>[
  CommunityEventSeed(
    id: 'ev-gravel-bw',
    title: 'Gravel-Treff Schwarzwald West',
    regionLabel: 'Schwarzwald',
    regionSlug: 'schwarzwald',
    dateLabel: 'Sa, 12. Sep 2026 · 09:00',
    sport: 'gravel',
    blurb: 'Lockere Gruppenfahrt, ca. 50 km. Keine Zeitnahme — nur Community.',
    catalogTourId: 'r-schwarzwald-gravel',
  ),
  CommunityEventSeed(
    id: 'ev-city-hd',
    title: 'Heidelberg Critical Mass light',
    regionLabel: 'Rhein-Neckar',
    regionSlug: 'rhein-neckar',
    dateLabel: 'Fr, 25. Sep 2026 · 18:30',
    sport: 'urban',
    blurb: 'Langsame Stadt-Runde für alle Räder. Treffpunkt am Neckar.',
    catalogTourId: 'r-heidelberg-city',
  ),
  CommunityEventSeed(
    id: 'ev-road-bodensee',
    title: 'Bodensee Südufer Genussfahrt',
    regionLabel: 'Bodensee',
    regionSlug: 'bodensee',
    dateLabel: 'So, 4. Okt 2026 · 08:30',
    sport: 'road',
    blurb: 'Flach, fotogen, Kaffee-Stops. Rennrad & E-Trekking willkommen.',
    catalogTourId: 'r-bodensee-road',
  ),
  CommunityEventSeed(
    id: 'ev-alster-hh',
    title: 'Hamburg Alster Feierabend',
    regionLabel: 'Norddeutschland',
    regionSlug: 'norddeutschland',
    dateLabel: 'Mi, 16. Sep 2026 · 18:00',
    sport: 'urban',
    blurb: 'Flache Runde um die Alster. City, nicht Alpen — Tempo nach Gefühl.',
    catalogTourId: 'r-hamburg-alster',
  ),
  CommunityEventSeed(
    id: 'ev-neckar-voll',
    title: 'Neckar-Vollrunde Feierabend',
    regionLabel: 'Rhein-Neckar',
    regionSlug: 'rhein-neckar',
    dateLabel: 'Do, 24. Sep 2026 · 18:00',
    sport: 'gravel',
    blurb:
        'Gemeinsame Runde auf der Referenz-Tour. Kein RSVP — wer kommt, kommt. Treffpunkt am Neckar.',
    catalogTourId: 'r-heidelberg-neckar-voll',
  ),
];
