/// Kurze Labels für das Tour-Funktionskit — offline, ohne gen-l10n.
class TourFunctionCopy {
  const TourFunctionCopy({
    required this.kitTitle,
    required this.kitLead,
    required this.eventTitle,
    required this.eventLead,
    required this.groupTitle,
    required this.groupBody,
    required this.groupCta,
    required this.fn,
  });

  final String kitTitle;
  final String kitLead;
  final String eventTitle;
  final String eventLead;
  final String groupTitle;
  final String groupBody;
  final String groupCta;
  final Map<String, String> fn;

  String label(String id) => fn[id] ?? id;
}

TourFunctionCopy tourFunctionCopy(String languageCode) {
  switch (languageCode) {
    case 'en':
      return const TourFunctionCopy(
        kitTitle: 'Functions on this tour',
        kitLead:
            'Map, profile, weather, Stimmen, share, Mappe, GPX, plan, ride, group, date, club, places.',
        eventTitle: 'Date on this tour',
        eventLead: 'Editorial — no RSVP, no live location.',
        groupTitle: 'Ride together',
        groupBody:
            'Invite-link group on Platz. Only on a shared or catalogue tour.',
        groupCta: 'Group on Platz',
        fn: _fnEn,
      );
    case 'fr':
      return const TourFunctionCopy(
        kitTitle: 'Fonctions de cette sortie',
        kitLead:
            'Carte, profil, météo, Stimmen, partage, Mappe, GPX, plan, sortie, groupe, date, club, lieux.',
        eventTitle: 'Date sur cette sortie',
        eventLead: 'Éditorial — pas de RSVP, pas de position live.',
        groupTitle: 'Sortir ensemble',
        groupBody:
            'Groupe avec lien d’invitation sur Platz. Seulement sortie partagée ou catalogue.',
        groupCta: 'Groupe sur Platz',
        fn: _fnFr,
      );
    case 'it':
      return const TourFunctionCopy(
        kitTitle: 'Funzioni di questa uscita',
        kitLead:
            'Mappa, profilo, meteo, Stimmen, condivisione, Mappe, GPX, piano, uscita, gruppo, data, club, luoghi.',
        eventTitle: 'Data su questa uscita',
        eventLead: 'Editoriale — niente RSVP, niente posizione live.',
        groupTitle: 'Uscire insieme',
        groupBody:
            'Gruppo con link d’invito sul Platz. Solo uscita condivisa o catalogo.',
        groupCta: 'Gruppo sul Platz',
        fn: _fnIt,
      );
    case 'nl':
      return const TourFunctionCopy(
        kitTitle: 'Functies van deze tocht',
        kitLead:
            'Kaart, profiel, weer, Stimmen, delen, Mappe, GPX, plannen, rit, groep, datum, club, plekken.',
        eventTitle: 'Datum bij deze tocht',
        eventLead: 'Redactioneel — geen RSVP, geen live-locatie.',
        groupTitle: 'Samen eropuit',
        groupBody:
            'Groep met uitnodigingslink op Platz. Alleen gedeelde of catalogustocht.',
        groupCta: 'Groep op Platz',
        fn: _fnNl,
      );
    default:
      return const TourFunctionCopy(
        kitTitle: 'Funktionen dieser Tour',
        kitLead:
            'Karte, Profil, Wetter, Stimmen, Teilen, Mappe, GPX, Planen, Fahrt, Gruppe, Termin, Club, Orte.',
        eventTitle: 'Termin an dieser Tour',
        eventLead: 'Redaktionell — kein RSVP, kein Live-Standort.',
        groupTitle: 'Zusammen raus',
        groupBody:
            'Gruppe mit Einladungslink auf dem Platz. Nur an freigegebener oder Katalog-Tour.',
        groupCta: 'Gruppe auf dem Platz',
        fn: _fnDe,
      );
  }
}

const _fnDe = {
  'map': 'Karte',
  'elevation': 'Höhe',
  'weather': 'Wetter',
  'stimmen': 'Stimmen',
  'share': 'Teilen',
  'mappe': 'Mappe',
  'gpx': 'GPX',
  'plan': 'Planen',
  'ride': 'Fahrt',
  'group': 'Gruppe',
  'event': 'Termin',
  'club': 'Club',
  'places': 'Orte',
};

const _fnEn = {
  'map': 'Map',
  'elevation': 'Elevation',
  'weather': 'Weather',
  'stimmen': 'Stimmen',
  'share': 'Share',
  'mappe': 'Mappe',
  'gpx': 'GPX',
  'plan': 'Plan',
  'ride': 'Ride',
  'group': 'Group',
  'event': 'Date',
  'club': 'Club',
  'places': 'Places',
};

const _fnFr = {
  'map': 'Carte',
  'elevation': 'Dénivelé',
  'weather': 'Météo',
  'stimmen': 'Stimmen',
  'share': 'Partager',
  'mappe': 'Mappe',
  'gpx': 'GPX',
  'plan': 'Planifier',
  'ride': 'Sortie',
  'group': 'Groupe',
  'event': 'Date',
  'club': 'Club',
  'places': 'Lieux',
};

const _fnIt = {
  'map': 'Mappa',
  'elevation': 'Dislivello',
  'weather': 'Meteo',
  'stimmen': 'Stimmen',
  'share': 'Condividi',
  'mappe': 'Mappe',
  'gpx': 'GPX',
  'plan': 'Pianifica',
  'ride': 'Uscita',
  'group': 'Gruppo',
  'event': 'Data',
  'club': 'Club',
  'places': 'Luoghi',
};

const _fnNl = {
  'map': 'Kaart',
  'elevation': 'Hoogte',
  'weather': 'Weer',
  'stimmen': 'Stimmen',
  'share': 'Delen',
  'mappe': 'Mappe',
  'gpx': 'GPX',
  'plan': 'Plannen',
  'ride': 'Rit',
  'group': 'Groep',
  'event': 'Datum',
  'club': 'Club',
  'places': 'Plekken',
};
