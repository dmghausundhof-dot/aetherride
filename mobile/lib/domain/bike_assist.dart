import 'bike.dart';
import 'catalog_bike.dart';

/// Muskel vs. E-Bike — UI-Steuerung für Garage (Mobile/Web-Parität).
enum BikeAssistMode { muscle, ebike }

/// Disziplin-Untertypen je Assist-Modus.
///
/// Mobile persistiert wie Web: [Bike.category] + [Bike.isEbike]
/// (Drift-Spalte `is_ebike`). E-City/E-Gravel/E-Road bleiben `urban`/`gravel`/
/// `road` mit `isEbike=true` — kein Kollaps auf `etrekking`.
class BikeAssistUx {
  BikeAssistUx._();

  static const muscleCategories = <BikeCategory>[
    BikeCategory.urban,
    BikeCategory.cargo,
    BikeCategory.folding,
    BikeCategory.kids,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.mtbTrail,
    BikeCategory.mtbAm,
    BikeCategory.mtbEnduro,
    BikeCategory.dh,
    BikeCategory.hiking,
  ];

  /// UI-Untertypen unter E-Bike (1:1 mit Persistenz + isEbike).
  static const ebikeCategories = <BikeCategory>[
    BikeCategory.etrekking,
    BikeCategory.urban,
    BikeCategory.cargo,
    BikeCategory.folding,
    BikeCategory.kids,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.emtb,
  ];

  static const everydayMuscle = <BikeCategory>[
    BikeCategory.urban,
    BikeCategory.cargo,
    BikeCategory.folding,
    BikeCategory.kids,
  ];

  static const everydayEbike = <BikeCategory>[
    BikeCategory.etrekking,
    BikeCategory.urban,
    BikeCategory.cargo,
    BikeCategory.folding,
    BikeCategory.kids,
  ];

  static const tourCategories = <BikeCategory>[
    BikeCategory.gravel,
    BikeCategory.road,
  ];

  static const trailMuscle = <BikeCategory>[
    BikeCategory.mtbTrail,
    BikeCategory.mtbAm,
    BikeCategory.mtbEnduro,
    BikeCategory.dh,
    BikeCategory.hiking,
  ];

  static const trailEbike = <BikeCategory>[BikeCategory.emtb];

  /// Kurze Typ-Liste beim Anlegen — Feinschnitt später in der Identität.
  static const addMuscle = <BikeCategory>[
    BikeCategory.urban,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.mtbAm,
    BikeCategory.cargo,
    BikeCategory.folding,
  ];

  static const addEbike = <BikeCategory>[
    BikeCategory.urban,
    BikeCategory.etrekking,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.emtb,
    BikeCategory.cargo,
  ];

  static List<BikeCategory> addCategories(BikeAssistMode mode) =>
      mode == BikeAssistMode.ebike ? addEbike : addMuscle;

  /// Enduro/Trail/DH aus Onboarding markieren die MTB-Kachel.
  static bool addTileSelected(
    BikeCategory tile,
    BikeCategory current,
    BikeAssistMode mode,
  ) {
    if (tile == current) return true;
    if (mode == BikeAssistMode.muscle && tile == BikeCategory.mtbAm) {
      return current == BikeCategory.mtbTrail ||
          current == BikeCategory.mtbEnduro ||
          current == BikeCategory.dh;
    }
    return false;
  }

  static WheelSize defaultWheelFor(BikeCategory c) => switch (c) {
        BikeCategory.urban ||
        BikeCategory.road ||
        BikeCategory.etrekking ||
        BikeCategory.cargo ||
        BikeCategory.folding ||
        BikeCategory.kids =>
          WheelSize.c700,
        BikeCategory.gravel => WheelSize.b650,
        _ => WheelSize.w29,
      };

  /// Anlegen: Trail zuerst (Katalog-Schwerpunkt). Zu Fuß ist kein Rad.
  static List<({String id, String label, List<BikeCategory> categories})>
      pickGroups(
    BikeAssistMode mode, {
    bool includeHiking = false,
  }) {
    final allowed = mode == BikeAssistMode.ebike
        ? ebikeCategories
        : muscleCategories;
    List<BikeCategory> take(List<BikeCategory> raw) => [
          for (final c in raw)
            if (allowed.contains(c) &&
                (includeHiking || c != BikeCategory.hiking))
              c,
        ];
    return [
      (
        id: 'trail',
        label: 'Trail',
        categories: take(
          mode == BikeAssistMode.ebike ? trailEbike : trailMuscle,
        ),
      ),
      (id: 'tour', label: 'Tour', categories: take(tourCategories)),
      (
        id: 'everyday',
        label: 'Alltag',
        categories: take(
          mode == BikeAssistMode.ebike ? everydayEbike : everydayMuscle,
        ),
      ),
    ].where((g) => g.categories.isNotEmpty).toList();
  }

  static BikeAssistMode modeFor({
    required BikeCategory category,
    bool isEbike = false,
  }) {
    if (isEbike ||
        category == BikeCategory.emtb ||
        category == BikeCategory.etrekking) {
      return BikeAssistMode.ebike;
    }
    return BikeAssistMode.muscle;
  }

  /// Label für die Typ-Kachel (unterscheidet E-Gravel vs. Gravel etc.).
  static String subtypeLabel(BikeCategory category, BikeAssistMode mode) {
    if (mode == BikeAssistMode.muscle) {
      return Bike(id: '', name: '', category: category).categoryLabel;
    }
    return switch (category) {
      BikeCategory.emtb => 'E-MTB',
      BikeCategory.etrekking => 'E-Trekking',
      BikeCategory.gravel => 'E-Gravel',
      BikeCategory.urban => 'E-City',
      BikeCategory.cargo => 'E-Lastenrad',
      BikeCategory.folding => 'E-Faltrad',
      BikeCategory.kids => 'E-Kinderrad',
      BikeCategory.road => 'E-Road',
      BikeCategory.mtbTrail => 'E-MTB Trail',
      BikeCategory.mtbAm => 'E-MTB',
      BikeCategory.mtbEnduro => 'E-Enduro',
      BikeCategory.dh => 'E-DH',
      BikeCategory.hiking => 'Zu Fuß',
    };
  }

  /// Anzeige-Label aus Persistenz (category + isEbike).
  static String displayLabel({
    required BikeCategory category,
    bool isEbike = false,
  }) {
    return subtypeLabel(
      category,
      modeFor(category: category, isEbike: isEbike),
    );
  }

  /// Beim Wechsel Muskel ↔ E-Bike sinnvollen Subtyp wählen.
  static BikeCategory coerceCategory(
    BikeCategory current,
    BikeAssistMode mode,
  ) {
    if (mode == BikeAssistMode.muscle) {
      return switch (current) {
        BikeCategory.emtb => BikeCategory.mtbAm,
        BikeCategory.etrekking => BikeCategory.urban,
        _ => muscleCategories.contains(current)
            ? current
            : BikeCategory.urban,
      };
    }
    return switch (current) {
      BikeCategory.mtbTrail ||
      BikeCategory.mtbAm ||
      BikeCategory.mtbEnduro ||
      BikeCategory.dh =>
        BikeCategory.emtb,
      BikeCategory.hiking => BikeCategory.etrekking,
      _ => current,
    };
  }

  /// Persistenz-Kategorie (Web-Parität): UI-Untertyp behalten.
  ///
  /// E-MTB → `emtb`; E-Trekking → `etrekking`; E-City/E-Gravel/E-Road →
  /// `urban`/`gravel`/`road` (Assist über [persistIsEbike]).
  static BikeCategory persistCategory(
    BikeCategory uiCategory,
    BikeAssistMode mode,
  ) {
    if (mode == BikeAssistMode.muscle) {
      if (uiCategory == BikeCategory.emtb) return BikeCategory.mtbAm;
      if (uiCategory == BikeCategory.etrekking) return BikeCategory.urban;
      return uiCategory;
    }
    return switch (uiCategory) {
      BikeCategory.mtbTrail ||
      BikeCategory.mtbAm ||
      BikeCategory.mtbEnduro ||
      BikeCategory.dh =>
        BikeCategory.emtb,
      BikeCategory.hiking => BikeCategory.etrekking,
      _ => uiCategory,
    };
  }

  /// Explizites Assist-Flag für Persistenz (Web `persistIsEbike`).
  static bool persistIsEbike(
    BikeCategory category,
    BikeAssistMode mode,
  ) {
    if (mode == BikeAssistMode.ebike) return true;
    return category == BikeCategory.emtb || category == BikeCategory.etrekking;
  }

  /// Katalog → Persistenz: Disziplin behalten wenn schon E-encoded;
  /// niemals alles auf `emtb` bzw. `etrekking` zwingen.
  static ({BikeCategory category, bool isEbike}) resolveCatalogPersist(
    CatalogBikeVariant cat,
  ) {
    if (!cat.isEbike) {
      return (category: cat.category, isEbike: false);
    }
    final persisted = persistCategory(cat.category, BikeAssistMode.ebike);
    return (category: persisted, isEbike: true);
  }
}
