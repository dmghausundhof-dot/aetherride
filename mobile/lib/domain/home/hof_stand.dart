import '../bike.dart';

/// Legacy-Default aus älteren Ständen. Neue Räder nutzen
/// [fallbackBikeName] (Kategorie). Nicht umbenennen, nur erkennen.
const kDefaultBikeName = 'Mein Bike';

/// Leerer Platzhalter: Legacy-Default, Import, oder noch kein Name.
/// Kein Katalog, keine Marke/Modell.
bool isUnnamedPlaceholderBike(Bike bike) {
  final name = bike.name.trim();
  final isLegacyDefault = name.isEmpty ||
      name == kDefaultBikeName ||
      name == 'Mein Rad' ||
      name == 'Import-Bike';
  if (!isLegacyDefault) return false;
  final noCatalog =
      bike.catalogBikeId == null || bike.catalogBikeId!.trim().isEmpty;
  final noBrand = bike.brand == null || bike.brand!.trim().isEmpty;
  final noModel = bike.model == null || bike.model!.trim().isEmpty;
  return noCatalog && noBrand && noModel;
}

/// Bewohner am Stand: benanntes/Katalog-Rad vor einem „Mein Bike“-Platzhalter.
/// Nur Platzhalter → der aktive bzw. erste. Leere Liste → null.
Bike? hofResidentBike(List<Bike> bikes) {
  if (bikes.isEmpty) return null;
  final named = [for (final b in bikes) if (!isUnnamedPlaceholderBike(b)) b];
  final pool = named.isEmpty ? bikes : named;
  for (final b in pool) {
    if (b.isActive) return b;
  }
  return pool.first;
}

/// Andere Räder auf dem Hof — ohne Duplikate und ohne Default-Phantome,
/// sobald ein benanntes/Katalog-Rad der Bewohner ist.
List<Bike> hofStandOthers({
  required Bike active,
  required List<Bike> all,
}) {
  final seen = <String>{active.id};
  final residentIsReal = !isUnnamedPlaceholderBike(active);
  final out = <Bike>[];
  for (final bike in all) {
    if (!seen.add(bike.id)) continue;
    if (residentIsReal && isUnnamedPlaceholderBike(bike)) continue;
    out.add(bike);
  }
  return out;
}

/// Anzeigename für „gefahren mit …“: echter preferred-Name, sonst Bewohner.
String? riddenWithLabel({
  required String? preferredBikeId,
  required List<Bike> bikes,
  Bike? active,
}) {
  Bike? preferred;
  final id = preferredBikeId?.trim();
  if (id != null && id.isNotEmpty) {
    for (final bike in bikes) {
      if (bike.id == id) {
        preferred = bike;
        break;
      }
    }
  }
  if (preferred != null && !isUnnamedPlaceholderBike(preferred)) {
    return preferred.name;
  }
  if (active != null && !isUnnamedPlaceholderBike(active)) {
    return active.name;
  }
  return preferred?.name ?? active?.name;
}
