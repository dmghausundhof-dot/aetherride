/// Internal product name remains `hof`. On-screen title is the job word
/// (Start / Accueil / Inizio), by UI language — not country poetry.
String hofTitleFor({
  String? countryCode,
  String languageCode = 'de',
}) {
  switch (languageCode.trim().toLowerCase()) {
    case 'fr':
      return 'Accueil';
    case 'it':
      return 'Inizio';
    default:
      return 'Start';
  }
}

/// Country of a Nähe-Seed from its id (GPS hour-at-the-gate), not from locale.
/// Unknown ids return null — caller falls back to locale country.
String? countryFromSeedId(String id) {
  final t = id.toLowerCase();
  if (_matches(t, _chTokens)) return 'CH';
  if (_matches(t, _atTokens)) return 'AT';
  if (_matches(t, _frTokens)) return 'FR';
  if (_matches(t, _itTokens)) return 'IT';
  if (_matches(t, _deTokens) ||
      t.contains('seed-loop-') ||
      t.contains('-rn-') ||
      t.contains('berlin') ||
      t.contains('tempelhof') ||
      t.contains('grunewald')) {
    return 'DE';
  }
  return null;
}

bool _matches(String id, List<String> tokens) {
  for (final token in tokens) {
    if (id.contains(token)) return true;
  }
  return false;
}

const _chTokens = <String>[
  'zurich',
  'zuerich',
  'basel',
  'bern',
  'geneva',
  'genf',
  'lucerne',
  'luzern',
  'lausanne',
  'st-gallen',
  'stgallen',
  'lugano',
  'winterthur',
  'chur',
  'thun',
  'locarno',
  'fribourg',
  'neuchatel',
  'sion',
  'zermatt',
  'interlaken',
  'davos',
  'stmoritz',
  'moritz',
];

const _atTokens = <String>[
  'vienna',
  'wien',
  'innsbruck',
  'salzburg',
  'graz',
  'linz',
  'bregenz',
  'klagenfurt',
  'villach',
  'soelden',
  'solden',
  'kitzbuehel',
  'kitzbuhel',
];

const _frTokens = <String>[
  'paris',
  'lyon',
  'strasbourg',
  'bordeaux',
  'nice',
  'annecy',
  'grenoble',
  'toulouse',
  'marseille',
  'nantes',
  'lille',
  'montpellier',
  'dijon',
  'rennes',
];

const _itTokens = <String>[
  'milan',
  'milano',
  'roma',
  'rome',
  'torino',
  'firenze',
  'bozen',
  'bolzano',
  'meran',
];

/// Konstanz is DE (Mainau). Must be listed so CH matching does not steal it.
const _deTokens = <String>[
  'konstanz',
  'hamburg',
  'munich',
  'muenchen',
  'berlin',
  'cologne',
  'koeln',
  'frankfurt',
  'stuttgart',
  'leipzig',
  'dresden',
  'freiburg',
  'hannover',
  'kiel',
  'heidelberg',
  'mannheim',
  'wiesloch',
  'nuernberg',
  'duesseldorf',
  'mainz',
  'erfurt',
  'rostock',
  'saarbruecken',
  'augsburg',
  'bremen',
  'potsdam',
  'karlsruhe',
  'regensburg',
  'muenster',
  'dortmund',
  'kassel',
  'chemnitz',
  'wiesbaden',
  'trier',
  'schwerin',
  'garmisch',
  'ruegen',
  'mueggel',
  'stralsund',
  'luebeck',
  'flensburg',
];
