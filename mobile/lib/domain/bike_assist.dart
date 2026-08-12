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
    BikeCategory.mtbTrail,
    BikeCategory.mtbAm,
    BikeCategory.mtbEnduro,
    BikeCategory.dh,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.urban,
    BikeCategory.hiking,
  ];

  /// UI-Untertypen unter E-Bike (1:1 mit Persistenz + isEbike).
  static const ebikeCategories = <BikeCategory>[
    BikeCategory.emtb,
    BikeCategory.etrekking,
    BikeCategory.gravel,
    BikeCategory.urban,
    BikeCategory.road,
  ];

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
            : BikeCategory.mtbAm,
      };
    }
    return switch (current) {
      BikeCategory.mtbTrail ||
      BikeCategory.mtbAm ||
      BikeCategory.mtbEnduro ||
      BikeCategory.dh =>
        BikeCategory.emtb,
      BikeCategory.hiking => BikeCategory.etrekking,
      BikeCategory.emtb ||
      BikeCategory.etrekking ||
      BikeCategory.gravel ||
      BikeCategory.urban ||
      BikeCategory.road =>
        current,
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
