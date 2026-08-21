/// Einheitliche Touren-Filter für alle Fahrradfahrer (nicht nur MTB/Road-Silos).
///
/// Mapping: API-/Seed-Felder → Filter-Keys → DE-Labels.
/// Quellen: `/api/tours/catalog`, Seeds (`surface_mix`, `effort_label`),
/// Outdooractive (`difficulty`), OSM (`mtb_scale` / Typ).
library;

import '../bike.dart';
import 'trail_difficulty.dart';

/// Kanonische Oberflächen-Keys (Match gegen Katalog/Seeds/OA).
enum TourSurfaceKey {
  asphalt,
  gravel,
  trail,
  mixed,
}

/// Beanspruchung — sportneutral (nicht nur S-Skala).
enum TourEffortKey {
  easy,
  mid,
  hard,
}

/// Höhenmeter-Bänder (wie Web Discover).
enum TourElevationKey {
  flat,
  hilly,
  alpine,
}

/// Sichtbarkeit eigener SavedRoutes (Mappe / Meine).
enum TourVisibilityKey {
  allMine,
  privateOnly,
  sharedOnly,
}

/// Form der Tour — nicht nur Rundkurs.
enum TourFormKey {
  all,
  loop,
  pointToPoint,
  downhill,
}

/// Discover-Fahrradtyp (hart filterbar). DH getrennt von MTB.
enum TourSportKey {
  mtb,
  emtb,
  gravel,
  road,
  urban,
  hiking,
  dh,
}

class TourFilterChip<T> {
  const TourFilterChip(this.id, this.label, {this.hint});
  final T id;
  final String label;
  final String? hint;
}

/// Shared Filter-Semantik für Discover (Mobile Priorität, Web angleichen).
class TourFilters {
  TourFilters._();

  /// Primärchips auf Discover (sichtbar): Dauer · Form · Untergrund · Distanz.
  /// Expertenfilter (Schwierigkeit, hm, weitere Dauer/Untergründe, Trailnetz)
  /// leben im „Mehr Filter"-Sheet — analog Komoot/AllTrails.
  static const primaryQuickDurationMin = 60;
  static const primaryQuickDistanceKm = 40.0;
  static const primaryQuickSurface = TourSurfaceKey.asphalt;

  static const surfaceChips = <TourFilterChip<TourSurfaceKey>>[
    TourFilterChip(
      TourSurfaceKey.asphalt,
      'Asphalt',
      hint: 'Asphalt · Radweg · befestigt',
    ),
    TourFilterChip(
      TourSurfaceKey.gravel,
      'Schotter',
      hint: 'Schotter · Forst · verdichtet',
    ),
    TourFilterChip(
      TourSurfaceKey.trail,
      'Trail',
      hint: 'Naturboden · Singletrail · Wurzel',
    ),
    TourFilterChip(
      TourSurfaceKey.mixed,
      'Gemischt',
      hint: 'Stadt · gemischter Belag',
    ),
  ];

  static const effortChips = <TourFilterChip<TourEffortKey>>[
    TourFilterChip(
      TourEffortKey.easy,
      'Leicht',
      hint: 'S0 / entspannt / wenig Technik',
    ),
    TourFilterChip(
      TourEffortKey.mid,
      'Mittel',
      hint: 'S1–S2 / sportlich / gemischt',
    ),
    TourFilterChip(
      TourEffortKey.hard,
      'Anspruchsvoll',
      hint: 'S2+ / schwer / technisch',
    ),
  ];

  static const elevationChips = <TourFilterChip<TourElevationKey>>[
    TourFilterChip(TourElevationKey.flat, '< 400 hm'),
    TourFilterChip(TourElevationKey.hilly, '400–1100 hm'),
    TourFilterChip(TourElevationKey.alpine, '1100+ hm'),
  ];

  /// Distanz-Obergrenzen (km) — aus typischen Katalog-/Seed-Längen.
  static const visibilityChips = <TourFilterChip<TourVisibilityKey>>[
    TourFilterChip(TourVisibilityKey.allMine, 'Alle'),
    TourFilterChip(TourVisibilityKey.privateOnly, 'Privat'),
    TourFilterChip(TourVisibilityKey.sharedOnly, 'Freigegeben'),
  ];

  static bool visibilityMatches(String? visibility, TourVisibilityKey filter) {
    final shared = visibility == 'shared';
    return switch (filter) {
      TourVisibilityKey.allMine => true,
      TourVisibilityKey.privateOnly => !shared,
      TourVisibilityKey.sharedOnly => shared,
    };
  }

  static const distanceMaxChips = <TourFilterChip<double>>[
    TourFilterChip(20, '≤ 20 km'),
    TourFilterChip(40, '≤ 40 km'),
    TourFilterChip(70, '≤ 70 km'),
  ];

  /// Normalisiert API-/Seed-Oberflächen auf einen Key.
  ///
  /// Katalog: `asphalt`, `asphalt/bike-lane`, `gravel/asphalt`, `trail/forest`…
  /// Seeds: `asphalt/paved`, `gravel/compacted`, `trail/root`, `mixed/urban`
  /// Legacy: `flow/compact` → gravel (verdichtet / Allround).
  static TourSurfaceKey? parseSurface(String? raw) {
    if (raw == null) return null;
    final t = raw.trim().toLowerCase();
    if (t.isEmpty || t == '—' || t == '-') return null;

    if (t.contains('trail') ||
        t.contains('root') ||
        t.contains('alpine') ||
        t.contains('single') ||
        t.contains('naturboden')) {
      return TourSurfaceKey.trail;
    }
    if (t.contains('gravel') ||
        t.contains('schotter') ||
        t.contains('forst') ||
        t.contains('unpaved') ||
        t.contains('compact') ||
        t == 'flow/compact' ||
        t.startsWith('flow')) {
      return TourSurfaceKey.gravel;
    }
    if (t.contains('urban') ||
        t.contains('mixed') ||
        t.contains('stadt') ||
        t.contains('gemischt')) {
      return TourSurfaceKey.mixed;
    }
    if (t.contains('asphalt') ||
        t.contains('paved') ||
        t.contains('bike-lane') ||
        t.contains('bike_lane') ||
        t.contains('radweg') ||
        t.contains('pavement') ||
        t == 'path' ||
        t.endsWith('/path')) {
      return TourSurfaceKey.asphalt;
    }
    return TourSurfaceKey.mixed;
  }

  /// Anzeige-Label (Detail / Tooltip).
  static String surfaceDisplay(String raw) {
    final key = parseSurface(raw);
    if (key != null) {
      return switch (key) {
        TourSurfaceKey.asphalt => 'Asphalt · befestigt',
        TourSurfaceKey.gravel => 'Schotter · verdichtet',
        TourSurfaceKey.trail => 'Naturboden · Trail',
        TourSurfaceKey.mixed => 'Stadt · gemischt',
      };
    }
    return raw;
  }

  static String surfaceChipLabel(TourSurfaceKey key) => switch (key) {
        TourSurfaceKey.asphalt => 'Asphalt',
        TourSurfaceKey.gravel => 'Schotter',
        TourSurfaceKey.trail => 'Trail',
        TourSurfaceKey.mixed => 'Gemischt',
      };

  /// Weicher Surface-Match (verwandte Beläge).
  static bool surfaceMatches(String tourSurface, TourSurfaceKey filter) {
    final key = parseSurface(tourSurface);
    if (key == null) return filter == TourSurfaceKey.mixed;
    if (key == filter) return true;
    const soft = <TourSurfaceKey, Set<TourSurfaceKey>>{
      TourSurfaceKey.asphalt: {TourSurfaceKey.asphalt, TourSurfaceKey.mixed},
      TourSurfaceKey.mixed: {TourSurfaceKey.mixed, TourSurfaceKey.asphalt},
      TourSurfaceKey.gravel: {TourSurfaceKey.gravel, TourSurfaceKey.trail},
      TourSurfaceKey.trail: {TourSurfaceKey.trail, TourSurfaceKey.gravel},
    };
    return soft[filter]?.contains(key) ?? false;
  }

  /// Kanonischer Tag zum Speichern auf [_RouteSuggestion.surface].
  static String canonicalSurfaceTag(TourSurfaceKey key) => switch (key) {
        TourSurfaceKey.asphalt => 'asphalt/paved',
        TourSurfaceKey.gravel => 'gravel/compacted',
        TourSurfaceKey.trail => 'trail/root',
        TourSurfaceKey.mixed => 'mixed/urban',
      };

  /// Leitet Untergrund aus Text/Typ/Profil ab (OA/OSM oft ohne surface).
  static String inferSurfaceTag({
    required String title,
    String? type,
    String? difficulty,
    String? profileApiId,
  }) {
    final blob =
        '${title.toLowerCase()} ${type?.toLowerCase() ?? ''} ${difficulty?.toLowerCase() ?? ''}';
    if (blob.contains('city') ||
        blob.contains('urban') ||
        blob.contains('stadt') ||
        blob.contains('pendel') ||
        blob.contains('alltag')) {
      return canonicalSurfaceTag(TourSurfaceKey.mixed);
    }
    if (blob.contains('road') ||
        blob.contains('rennrad') ||
        blob.contains('asphalt') ||
        blob.contains('race') ||
        blob.contains('radweg')) {
      return canonicalSurfaceTag(TourSurfaceKey.asphalt);
    }
    if (blob.contains('gravel') ||
        blob.contains('schotter') ||
        blob.contains('forst') ||
        blob.contains('unpaved')) {
      return canonicalSurfaceTag(TourSurfaceKey.gravel);
    }
    if (blob.contains('mtb') ||
        blob.contains('trail') ||
        blob.contains('enduro') ||
        blob.contains('single') ||
        blob.contains('s2') ||
        blob.contains('s3') ||
        blob.contains('schwer')) {
      return canonicalSurfaceTag(TourSurfaceKey.trail);
    }
    final p = (profileApiId ?? '').toLowerCase();
    if (p.contains('road')) return canonicalSurfaceTag(TourSurfaceKey.asphalt);
    if (p.contains('urban')) return canonicalSurfaceTag(TourSurfaceKey.mixed);
    if (p.contains('gravel') || p.contains('ebike')) {
      return canonicalSurfaceTag(TourSurfaceKey.gravel);
    }
    if (p.contains('mtb') || p.contains('enduro') || p.contains('emtb')) {
      return canonicalSurfaceTag(TourSurfaceKey.trail);
    }
    return canonicalSurfaceTag(TourSurfaceKey.gravel);
  }

  /// Normalisiert Katalog-Roh-surface auf kanonischen Tag.
  static String normalizeStoredSurface(String raw, {String? fallbackTitle}) {
    final key = parseSurface(raw);
    if (key != null) return canonicalSurfaceTag(key);
    if (fallbackTitle != null && fallbackTitle.isNotEmpty) {
      return inferSurfaceTag(title: fallbackTitle);
    }
    return canonicalSurfaceTag(TourSurfaceKey.mixed);
  }

  /// Nur Chips, die in den geladenen Touren vorkommen (sonst alle).
  static List<TourSurfaceKey> availableSurfaces(Iterable<String> surfaces) {
    final present = <TourSurfaceKey>{};
    for (final s in surfaces) {
      final k = parseSurface(s);
      if (k != null) present.add(k);
    }
    if (present.isEmpty) {
      return TourSurfaceKey.values.toList();
    }
    return [
      for (final c in surfaceChips)
        if (present.contains(c.id)) c.id,
    ];
  }

  /// Beanspruchung aus difficulty / effort / mtbScale.
  static bool effortMatches(String raw, TourEffortKey filter) {
    final t = raw.trim().toLowerCase();
    if (t.isEmpty || t == '—' || t == '-' || t == 'offen' || t == 'open') {
      // Unklassifiziert (viele Road/City/Katalog-Touren): leicht + mittel ok.
      return filter == TourEffortKey.easy || filter == TourEffortKey.mid;
    }

    if (t.contains('anspruch') ||
        t.contains('schwer') ||
        t.contains('hard') ||
        t.contains('difficult') ||
        t.contains('rau')) {
      return filter == TourEffortKey.hard;
    }
    if (t.contains('leicht') ||
        t.contains('easy') ||
        t.contains('entspannt') ||
        t.contains('flach')) {
      return filter == TourEffortKey.easy;
    }
    if (t.contains('mittel') ||
        t.contains('medium') ||
        t.contains('sportlich') ||
        t.contains('gemischt')) {
      return filter == TourEffortKey.mid || filter == TourEffortKey.easy;
    }

    final parsed = parseTrailDifficulty(raw);
    if (parsed != TrailDifficulty.open) {
      return switch (filter) {
        TourEffortKey.easy =>
          parsed == TrailDifficulty.s0 || parsed == TrailDifficulty.s1,
        TourEffortKey.mid =>
          parsed == TrailDifficulty.s1 || parsed == TrailDifficulty.s2,
        TourEffortKey.hard =>
          parsed == TrailDifficulty.s2 ||
              parsed == TrailDifficulty.s3 ||
              parsed == TrailDifficulty.s3plus,
      };
    }

    // SAC / Wander-Skala
    if (RegExp(r't[34]', caseSensitive: false).hasMatch(t)) {
      return filter == TourEffortKey.hard;
    }
    if (RegExp(r't[12]', caseSensitive: false).hasMatch(t)) {
      return filter == TourEffortKey.easy || filter == TourEffortKey.mid;
    }

    // Keine Skala: wie Web road/city — easy+mid.
    return filter == TourEffortKey.easy || filter == TourEffortKey.mid;
  }

  static bool elevationMatches(int hm, TourElevationKey filter) {
    return switch (filter) {
      TourElevationKey.flat => hm < 400,
      TourElevationKey.hilly => hm >= 400 && hm < 1100,
      TourElevationKey.alpine => hm >= 1100,
    };
  }

  static bool distanceMatches(double km, double? maxKm) {
    if (maxKm == null || maxKm <= 0) return true;
    return km <= maxKm + 0.05;
  }

  /// Umkreis: Abstand Tour-Mitte → Standort. Nicht die Tourlänge.
  static bool awayMatches(double awayKm, double? maxAwayKm) {
    return distanceMatches(awayKm, maxAwayKm);
  }

  /// Weiche Sport-Präferenz: true wenn Tour zur Kategorie passt.
  static bool softSportMatch(
    List<BikeCategory> tourCategories,
    BikeCategory? preferred,
  ) {
    if (preferred == null) return false;
    if (tourCategories.contains(preferred)) return true;
    // Familien-Nähe (E-MTB ↔ MTB)
    final fam = _family(preferred);
    for (final c in tourCategories) {
      if (_family(c) == fam) return true;
    }
    // Touring/E-Trekking: Road · Gravel · City sind verwandt (wie Web sport=touring).
    if (preferred == BikeCategory.etrekking) {
      return tourCategories.any(
        (c) =>
            c == BikeCategory.road ||
            c == BikeCategory.gravel ||
            c == BikeCategory.urban ||
            c == BikeCategory.etrekking,
      );
    }
    if (tourCategories.contains(BikeCategory.etrekking)) {
      return preferred == BikeCategory.road ||
          preferred == BikeCategory.gravel ||
          preferred == BikeCategory.urban;
    }
    return false;
  }

  /// Weiche Präferenz gegen mehrere gewählte Disziplinen.
  static bool softSportMatchAny(
    List<BikeCategory> tourCategories,
    Iterable<BikeCategory> preferred,
  ) {
    for (final p in preferred) {
      if (softSportMatch(tourCategories, p)) return true;
    }
    return false;
  }

  static String _family(BikeCategory c) => switch (c) {
        BikeCategory.mtbTrail ||
        BikeCategory.mtbAm ||
        BikeCategory.mtbEnduro ||
        BikeCategory.dh ||
        BikeCategory.emtb =>
          'mtb',
        BikeCategory.gravel => 'gravel',
        BikeCategory.road => 'road',
        BikeCategory.urban ||
        BikeCategory.cargo ||
        BikeCategory.folding ||
        BikeCategory.kids =>
          'urban',
        BikeCategory.etrekking => 'touring',
        BikeCategory.hiking => 'hike',
      };

  static const sportFilterChips = <TourSportKey>[
    TourSportKey.mtb,
    TourSportKey.emtb,
    TourSportKey.gravel,
    TourSportKey.road,
    TourSportKey.urban,
    TourSportKey.hiking,
    TourSportKey.dh,
  ];

  static const formFilterChips = <TourFormKey>[
    TourFormKey.all,
    TourFormKey.loop,
    TourFormKey.pointToPoint,
    TourFormKey.downhill,
  ];

  static bool hasTrailFamily(List<BikeCategory> cats) => cats.any(
        (c) =>
            c == BikeCategory.mtbTrail ||
            c == BikeCategory.mtbAm ||
            c == BikeCategory.mtbEnduro ||
            c == BikeCategory.dh ||
            c == BikeCategory.emtb,
      );

  /// S-Skala im Filter-Sheet nur wenn MTB/Trail/DH relevant — nicht bei City.
  static bool filterSheetShowsSScale({
    required bool mtbOverlayFamily,
    required Set<TourSportKey> sportFilter,
    required TourFormKey form,
  }) {
    if (form == TourFormKey.downhill) return true;
    if (mtbOverlayFamily) return true;
    return sportFilter.contains(TourSportKey.mtb) ||
        sportFilter.contains(TourSportKey.emtb) ||
        sportFilter.contains(TourSportKey.dh);
  }

  /// S-Skala nur an MTB/Trail/DH hängen — Gravel/Rennrad bleibt „offen“.
  static String honestScaleTag({
    required String effortLabel,
    required List<BikeCategory> categories,
    String? stored,
  }) {
    final raw = stored?.trim();
    if (raw != null &&
        raw.isNotEmpty &&
        raw != '—' &&
        raw != '-' &&
        raw.toLowerCase() != 'offen' &&
        raw.toLowerCase() != 'open') {
      if (trailDifficultiesIn(raw).isNotEmpty) return raw;
    }
    if (!hasTrailFamily(categories)) return 'offen';
    return switch (effortLabel.trim().toLowerCase()) {
      'leicht' || 'easy' => 'S0',
      'anspruchsvoll' || 'schwer' || 'hard' => 'S2',
      _ => 'S1',
    };
  }

  static bool scaleMatches(
    String raw,
    List<BikeCategory> categories,
    Set<TrailDifficulty> wanted,
  ) {
    if (wanted.isEmpty) return true;
    final grades = trailDifficultiesIn(raw);
    if (grades.isEmpty) return false;
    return grades.any(wanted.contains);
  }

  static bool isDownhillTour({
    required List<BikeCategory> categories,
    required List<String> tags,
    required String title,
    String? sportLabel,
    required bool isLoop,
  }) {
    if (categories.contains(BikeCategory.dh)) return true;
    final blob =
        '${title.toLowerCase()} ${sportLabel ?? ''} ${tags.join(' ')}'.toLowerCase();
    if (blob.contains('downhill') ||
        blob.contains('bikepark') ||
        blob.contains('bike-park') ||
        RegExp(r'(^|[^a-z])dh([^a-z]|$)').hasMatch(blob)) {
      return true;
    }
    // Enduro A→B ist typisch abfahrtslastig — Rundkurs nicht automatisch DH.
    if (!isLoop && categories.contains(BikeCategory.mtbEnduro)) return true;
    return false;
  }

  static bool formMatches({
    required TourFormKey form,
    required bool isLoop,
    required List<BikeCategory> categories,
    required List<String> tags,
    required String title,
    String? sportLabel,
  }) {
    return switch (form) {
      TourFormKey.all => true,
      TourFormKey.loop => isLoop,
      TourFormKey.pointToPoint => !isLoop,
      TourFormKey.downhill => isDownhillTour(
          categories: categories,
          tags: tags,
          title: title,
          sportLabel: sportLabel,
          isLoop: isLoop,
        ),
    };
  }

  /// Peek/Liste: ein einzelnes „ebike“ auf Asphalt ist City, nicht E-Bike.
  static String? honestSportLabel({
    String? sportLabel,
    required String surface,
  }) {
    final raw = sportLabel?.trim();
    if (raw == null || raw.isEmpty) return null;
    final t = raw.toLowerCase();
    if (t == 'ebike' || t == 'e-bike') {
      final surf = parseSurface(surface);
      if (surf == TourSurfaceKey.asphalt || surf == TourSurfaceKey.mixed) {
        return 'city';
      }
    }
    return raw;
  }

  static TourSportKey sportOf(List<BikeCategory> cats) {
    if (cats.isEmpty) return TourSportKey.urban;
    return _sportOf(cats.first);
  }

  static TourSportKey _sportOf(BikeCategory c) => switch (c) {
        BikeCategory.dh => TourSportKey.dh,
        BikeCategory.emtb => TourSportKey.emtb,
        BikeCategory.mtbTrail ||
        BikeCategory.mtbAm ||
        BikeCategory.mtbEnduro =>
          TourSportKey.mtb,
        BikeCategory.gravel || BikeCategory.etrekking => TourSportKey.gravel,
        BikeCategory.road => TourSportKey.road,
        BikeCategory.hiking => TourSportKey.hiking,
        BikeCategory.urban ||
        BikeCategory.cargo ||
        BikeCategory.folding ||
        BikeCategory.kids =>
          TourSportKey.urban,
      };

  /// Hart-Filter: leere Auswahl = alle Typen.
  static bool sportMatches(
    List<BikeCategory> cats,
    Iterable<TourSportKey> filters,
  ) {
    if (filters.isEmpty) return true;
    final wanted = filters.toSet();
    for (final c in cats) {
      if (wanted.contains(_sportOf(c))) return true;
    }
    return false;
  }

  /// OA/OSM ohne Kategorie-Feld — nur aus Text, nicht erfunden.
  static List<BikeCategory> inferCategories({
    required String title,
    String? type,
    String? difficulty,
    String? surface,
  }) {
    final blob =
        '${title.toLowerCase()} ${type?.toLowerCase() ?? ''} ${difficulty?.toLowerCase() ?? ''}';
    if (blob.contains('downhill') ||
        blob.contains('bikepark') ||
        blob.contains('bike-park') ||
        RegExp(r'(^|[^a-z])dh([^a-z]|$)').hasMatch(blob)) {
      return const [BikeCategory.dh, BikeCategory.mtbEnduro, BikeCategory.emtb];
    }
    if (blob.contains('enduro')) {
      return const [
        BikeCategory.mtbEnduro,
        BikeCategory.mtbAm,
        BikeCategory.emtb,
      ];
    }
    if (blob.contains('mtb') ||
        blob.contains('mountain') ||
        blob.contains('singletrail') ||
        (blob.contains('trail') && !blob.contains('rail'))) {
      return const [
        BikeCategory.mtbAm,
        BikeCategory.mtbTrail,
        BikeCategory.emtb,
      ];
    }
    if (blob.contains('hike') ||
        blob.contains('wander') ||
        blob.contains('hiking') ||
        blob.contains('zu fuß') ||
        blob.contains('zu fuss')) {
      return const [BikeCategory.hiking];
    }
    if (blob.contains('gravel') || blob.contains('schotter')) {
      return const [BikeCategory.gravel, BikeCategory.etrekking];
    }
    if (blob.contains('road') ||
        blob.contains('rennrad') ||
        blob.contains('race') ||
        blob.contains('strada')) {
      return const [BikeCategory.road];
    }
    if (blob.contains('city') ||
        blob.contains('urban') ||
        blob.contains('stadt') ||
        blob.contains('pendel')) {
      return const [BikeCategory.urban, BikeCategory.etrekking];
    }
    final grades = trailDifficultiesIn(difficulty);
    if (grades.isNotEmpty) {
      return const [
        BikeCategory.mtbAm,
        BikeCategory.mtbTrail,
        BikeCategory.emtb,
      ];
    }
    final s = parseSurface(surface);
    if (s == TourSurfaceKey.trail) {
      return const [BikeCategory.mtbAm, BikeCategory.emtb];
    }
    if (s == TourSurfaceKey.gravel) {
      return const [BikeCategory.gravel, BikeCategory.etrekking];
    }
    if (s == TourSurfaceKey.asphalt) {
      return const [BikeCategory.road, BikeCategory.urban];
    }
    return const [
      BikeCategory.urban,
      BikeCategory.gravel,
      BikeCategory.road,
    ];
  }

  static String pinLabel(TourSportKey sport) => switch (sport) {
        TourSportKey.mtb => 'MTB',
        TourSportKey.emtb => 'eMTB',
        TourSportKey.gravel => 'GR',
        TourSportKey.road => 'RR',
        TourSportKey.urban => 'City',
        TourSportKey.hiking => 'Fuß',
        TourSportKey.dh => 'DH',
      };

  /// Browse-Karte: Minuten, keine Sport-Kürzel (GR/RR).
  static String browseTourTimeLabel(int durationMin) {
    if (durationMin <= 0) return '';
    return '$durationMin′';
  }

  /// Zoom-Stufen, die Pin-Dichte und Beschriftung wechseln.
  /// 0 unter 10, 1 ab 10, 2 ab 11, 3 ab 12, 4 ab 13.
  static int browsePinZoomBand(double zoom) {
    if (zoom < 10) return 0;
    if (zoom < 11) return 1;
    if (zoom < 12) return 2;
    if (zoom < 13) return 3;
    return 4;
  }

  /// Band 0 toggles unselected tour-start pins. 11–13 only change labels.
  static bool browsePinZoomBandNeedsFullResync(int from, int to) {
    if (from == to) return false;
    return from == 0 || to == 0;
  }

  /// Dauer ab Zoom 11 — ungewählt und gewählt, sonst Pin-Wald.
  static bool browseTourShowsTime({required double zoom}) => zoom >= 11;

  static const int _browseTourNameMax = 16;

  /// Ungewählt: nur Dauer. Gewählt ab Zoom 13: Dauer · Kurzname.
  static String browseTourPinText({
    required int durationMin,
    required bool selected,
    required double zoom,
    String? name,
  }) {
    if (!browseTourShowsTime(zoom: zoom)) return '';
    final time = browseTourTimeLabel(durationMin);
    if (!selected || zoom < 13) return time;
    final n = name?.trim() ?? '';
    if (n.isEmpty) return time;
    final short = n.length <= _browseTourNameMax
        ? n
        : '${n.substring(0, _browseTourNameMax - 1)}…';
    return time.isEmpty ? short : '$time · $short';
  }

  static String pinHalo(TourSportKey sport) => switch (sport) {
        TourSportKey.mtb || TourSportKey.emtb => '#1B5E20',
        TourSportKey.gravel => '#5D4037',
        TourSportKey.road => '#0D47A1',
        TourSportKey.urban => '#004D40',
        TourSportKey.hiking => '#4E342E',
        TourSportKey.dh => '#B71C1C',
      };
}
