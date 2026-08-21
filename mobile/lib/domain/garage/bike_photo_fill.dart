import '../bike.dart';
import '../bike_assist.dart';
import '../catalog_bike.dart';
import '../component.dart';

enum OemPartSource { catalog, vision, typed }

/// Ein vermutetes Teil — nie still installieren, nur zur Kontrolle.
class OemPartSuggestion {
  const OemPartSuggestion({
    required this.slot,
    this.manufacturer,
    this.model,
    this.catalogModelId,
    this.source = OemPartSource.catalog,
    this.occupied = false,
    this.occupiedLabel,
  });

  final ComponentSlot slot;
  final String? manufacturer;
  final String? model;
  final String? catalogModelId;
  final OemPartSource source;
  final bool occupied;
  final String? occupiedLabel;

  bool get hasCatalogId => (catalogModelId ?? '').trim().isNotEmpty;

  /// Grok hat Hersteller/Modell, aber keinen Katalog-SKU — nicht verwerfen.
  bool get isGrokOnly =>
      source != OemPartSource.typed &&
      !hasCatalogId &&
      ((manufacturer ?? '').trim().isNotEmpty ||
          (model ?? '').trim().isNotEmpty);

  bool get canInstall =>
      hasCatalogId ||
      (manufacturer ?? '').trim().isNotEmpty ||
      (model ?? '').trim().isNotEmpty;

  String get title {
    final bits = [
      if ((manufacturer ?? '').trim().isNotEmpty) manufacturer!.trim(),
      if ((model ?? '').trim().isNotEmpty) model!.trim(),
    ];
    return bits.isEmpty ? slot.label : bits.join(' ');
  }

  String get sourceLabel {
    if (source == OemPartSource.typed) return 'Selbst eingetragen';
    if (isGrokOnly) return 'Von Grok, nicht im Katalog';
    if (source == OemPartSource.vision) {
      return 'Am Foto gesehen — am Rad prüfen';
    }
    return 'Laut Katalog / Grok — am Rad prüfen';
  }
}

/// Was Grok/Katalog in ein bestehendes Rad schreiben darf.
///
/// Nur leere Felder. Nie Seriennummer, Farbe, Druck, SAG, km, Stunden.
class BikePhotoFill {
  const BikePhotoFill({
    required this.bike,
    required this.filled,
    this.oemSlots = const [],
    this.suggestions = const [],
  });

  final Bike bike;
  final List<String> filled;
  final List<ComponentSlot> oemSlots;
  final List<OemPartSuggestion> suggestions;

  bool get changed => filled.isNotEmpty;
}

bool bikeNameIsPlaceholder(Bike bike) {
  final n = bike.name.trim();
  if (n.isEmpty) return true;
  return n == fallbackBikeName(bike.category, isEbike: bike.isEbike) ||
      n == BikeAssistUx.displayLabel(
        category: bike.category,
        isEbike: bike.isEbike,
      );
}

bool _blank(String? v) => v == null || v.trim().isEmpty;

/// Katalog-Treffer → nur Lücken. Kategorie bleibt, wenn der Fahrer sie gesetzt hat.
BikePhotoFill fillEmptyBikeFromCatalog({
  required Bike bike,
  required String manufacturerName,
  required CatalogBikeVariant catalog,
  bool treatDefaultWheelAsEmpty = true,
}) {
  final filled = <String>[];
  var next = bike;

  if (_blank(next.brand) && manufacturerName.trim().isNotEmpty) {
    next = next.copyWith(brand: manufacturerName.trim());
    filled.add('Marke');
  }
  if (_blank(next.model) && catalog.name.trim().isNotEmpty) {
    next = next.copyWith(model: catalog.name.trim());
    filled.add('Modell');
  }
  if (next.year == null && catalog.year > 0) {
    next = next.copyWith(year: catalog.year);
    filled.add('Jahr');
  }
  if (_blank(next.catalogBikeId) && catalog.id.isNotEmpty) {
    next = next.copyWith(catalogBikeId: catalog.id);
    filled.add('Katalog');
  }

  final defaultWheel = BikeAssistUx.defaultWheelFor(bike.category);
  final wheelEmpty = next.wheelSize == null ||
      (treatDefaultWheelAsEmpty && next.wheelSize == defaultWheel);
  if (wheelEmpty && catalog.wheelSizeFront != defaultWheel) {
    next = next.copyWith(wheelSize: catalog.wheelSizeFront);
    filled.add('Laufrad');
  } else if (next.wheelSize == null) {
    next = next.copyWith(wheelSize: catalog.wheelSizeFront);
    filled.add('Laufrad');
  }

  if ((next.travelFrontMm == null || next.travelFrontMm == 0) &&
      (catalog.travelFrontMm ?? 0) > 0) {
    next = next.copyWith(travelFrontMm: catalog.travelFrontMm);
    filled.add('Federweg vorn');
  }
  if ((next.travelRearMm == null || next.travelRearMm == 0) &&
      (catalog.travelRearMm ?? 0) > 0) {
    next = next.copyWith(travelRearMm: catalog.travelRearMm);
    filled.add('Federweg hinten');
  }

  if (_blank(next.frameSize) && catalog.frameSizeOptions.length == 1) {
    next = next.copyWith(frameSize: catalog.frameSizeOptions.first);
    filled.add('Rahmengröße');
  }

  if (!next.isEbike && catalog.isEbike) {
    next = next.copyWith(isEbike: true);
    filled.add('E-Antrieb');
  }

  if (bikeNameIsPlaceholder(bike) &&
      (next.brand != null || next.model != null)) {
    final label = [next.brand, next.model].whereType<String>().join(' ');
    if (label.trim().isNotEmpty) {
      next = next.copyWith(name: label.trim());
      filled.add('Name');
    }
  }

  final oemSlots = <ComponentSlot>[];
  for (final key in catalog.oemComponents.keys) {
    final slot = ComponentSlotLabel.fromApiId(key);
    if (slot != null) oemSlots.add(slot);
  }

  return BikePhotoFill(
    bike: next,
    filled: filled,
    oemSlots: oemSlots,
    suggestions: oemSuggestionsFromMap(catalog.oemComponents),
  );
}

List<OemPartSuggestion> oemSuggestionsFromMap(
  Map<String, String> oem, {
  List<OemPartSuggestion> vision = const [],
  List<BikeComponent> installed = const [],
}) {
  BikeComponent? occupant(ComponentSlot slot) {
    for (final c in installed) {
      if (c.isInstalled && c.slot == slot) return c;
    }
    return null;
  }

  final bySlot = <ComponentSlot, OemPartSuggestion>{};
  for (final e in oem.entries) {
    final slot = ComponentSlotLabel.fromApiId(e.key);
    if (slot == null) continue;
    final id = e.value.trim();
    if (id.isEmpty) continue;
    final here = occupant(slot);
    bySlot[slot] = OemPartSuggestion(
      slot: slot,
      catalogModelId: id,
      source: OemPartSource.catalog,
      occupied: here != null,
      occupiedLabel: here?.displayName,
    );
  }
  for (final v in vision) {
    final here = occupant(v.slot);
    final prev = bySlot[v.slot];
    if (prev == null) {
      bySlot[v.slot] = OemPartSuggestion(
        slot: v.slot,
        manufacturer: v.manufacturer,
        model: v.model,
        catalogModelId: v.catalogModelId,
        source: OemPartSource.vision,
        occupied: here != null,
        occupiedLabel: here?.displayName,
      );
      continue;
    }
    bySlot[v.slot] = OemPartSuggestion(
      slot: prev.slot,
      manufacturer: v.manufacturer ?? prev.manufacturer,
      model: v.model ?? prev.model,
      catalogModelId: prev.catalogModelId ?? v.catalogModelId,
      source: OemPartSource.vision,
      occupied: here != null,
      occupiedLabel: here?.displayName,
    );
  }
  final list = bySlot.values.toList()
    ..sort((a, b) => a.slot.label.compareTo(b.slot.label));
  return list;
}

List<OemPartSuggestion> visionPartsFromIdentify(List<CatalogVisionPart> raw) {
  final out = <OemPartSuggestion>[];
  for (final p in raw) {
    final slot = ComponentSlotLabel.fromApiId(p.slotApiId) ??
        ComponentSlot.other;
    final manufacturer = (p.manufacturer ?? '').trim();
    final model = (p.model ?? '').trim();
    if (manufacturer.isEmpty && model.isEmpty) continue;
    out.add(
      OemPartSuggestion(
        slot: slot,
        manufacturer: manufacturer.isEmpty ? null : manufacturer,
        model: model.isEmpty ? null : model,
        source: OemPartSource.vision,
      ),
    );
  }
  return out;
}

OemPartSuggestion namedSuggestion(OemPartSuggestion raw,
    {String? manufacturer, String? model}) {
  return OemPartSuggestion(
    slot: raw.slot,
    manufacturer: (manufacturer ?? '').trim().isEmpty
        ? raw.manufacturer
        : manufacturer!.trim(),
    model: (model ?? '').trim().isEmpty ? raw.model : model!.trim(),
    catalogModelId: raw.catalogModelId,
    source: raw.source,
    occupied: raw.occupied,
    occupiedLabel: raw.occupiedLabel,
  );
}

/// Leere Specs aus dem Identify-Treffer, wenn der volle Katalogeintrag fehlt.
BikePhotoFill fillEmptyBikeFromHit({
  required Bike bike,
  required CatalogBikeHit hit,
}) {
  final stub = CatalogBikeVariant(
    id: hit.id,
    name: hit.name,
    year: hit.year,
    category: hit.category,
    frameSizeOptions: const [],
    wheelSizeFront: BikeAssistUx.defaultWheelFor(hit.category),
    wheelSizeRear: BikeAssistUx.defaultWheelFor(hit.category),
    isEbike: hit.isEbike,
    oemComponents: const {},
  );
  return fillEmptyBikeFromCatalog(
    bike: bike,
    manufacturerName: hit.manufacturerName,
    catalog: stub,
    treatDefaultWheelAsEmpty: false,
  );
}

/// Nur den gelesenen Namen, wenn der Fahrer bestätigt und der Name Platzhalter ist.
/// Kein Jahr, kein Federweg, keine Rahmennummer.
BikePhotoFill suggestNameFromGrokRead({
  required Bike bike,
  required String query,
}) {
  final q = query.trim();
  if (q.isEmpty || !bikeNameIsPlaceholder(bike)) {
    return BikePhotoFill(bike: bike, filled: const []);
  }
  return BikePhotoFill(bike: bike.copyWith(name: q), filled: const ['Name']);
}

String identifyReasonMessage(String? reason) {
  return switch (reason) {
    'no_key' =>
      'Kein Vision-Schlüssel. Foto merken, Marke und Modell tippen.',
    'quota' => 'Scan-Kontingent leer. Marke und Modell tippen.',
    'failed' => 'Foto nicht gelesen. Marke und Modell tippen.',
    'unreadable' => 'Rad auf dem Foto nicht erkannt. Anderes Bild oder tippen.',
    'no_catalog' =>
      'Kein Treffer im Katalog. Gelesenen Text prüfen oder tippen.',
    _ => 'Kein Treffer im Katalog. Marke und Modell tippen.',
  };
}
