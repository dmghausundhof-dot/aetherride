import '../bike.dart';
import '../component.dart';
import '../maintenance/intervals.dart';
import '../setup.dart';
import 'werkstatt_setup.dart';

/// Die Box — Werkstatt-IA. Tab stays Werkstatt; this is the resident's stall.
enum DieBoxReadiness { ready, almost, unknown }

enum DieBoxItemId {
  setActive,
  pressureUnknown,
  sagUnknown,
  travelUnknown,
  chainTeach,
  lightsMissing,
  lockMissing,
  rackMissing,
  bagsMissing,
  brakesUnknown,
  dueCare,
  pairCsc,
  parkTrail,
}

class DieBoxChip {
  const DieBoxChip({required this.label, this.known = true});
  final String label;
  final bool known;
}

class DieBoxTodayItem {
  const DieBoxTodayItem({
    required this.id,
    required this.title,
    required this.hint,
    required this.cta,
    this.slot,
    this.due,
  });

  final DieBoxItemId id;
  final String title;
  final String hint;
  final String cta;
  final ComponentSlot? slot;
  final MaintenanceAlert? due;
}

class DieBoxPlan {
  const DieBoxPlan({
    required this.setup,
    required this.readiness,
    required this.sentence,
    required this.chips,
    required this.today,
    required this.onBike,
    required this.addableSlots,
    required this.showParkTrail,
    this.parkSetup,
    this.trailSetup,
  });

  final WerkstattSetupPlan setup;
  final DieBoxReadiness readiness;
  final String sentence;
  final List<DieBoxChip> chips;
  final List<DieBoxTodayItem> today;
  final List<BikeComponent> onBike;
  final List<ComponentSlot> addableSlots;
  final bool showParkTrail;
  final BikeSetup? parkSetup;
  final BikeSetup? trailSetup;

  DieBoxTodayItem? get primary => today.isEmpty ? null : today.first;

  bool get isReady => readiness == DieBoxReadiness.ready && today.isEmpty;
}

bool _hasSlot(List<BikeComponent> comps, ComponentSlot slot) =>
    comps.any((c) => c.isInstalled && c.slot == slot);

bool _userLoggedPressure(List<BikeSetup> setups) {
  for (final s in setups) {
    if (s.createdBy != 'user') continue;
    if (s.valueFor('tire_front.pressure_psi') != null ||
        s.valueFor('tire_rear.pressure_psi') != null) {
      return true;
    }
  }
  return false;
}

bool _userLoggedSag(List<BikeSetup> setups) {
  for (final s in setups) {
    if (s.createdBy != 'user') continue;
    if (s.valueFor('fork.sag_pct') != null ||
        s.valueFor('shock.sag_pct') != null) {
      return true;
    }
  }
  return false;
}

bool _logMentions(List<Map<String, dynamic>> logs, String bikeId, String needle) {
  final n = needle.toLowerCase();
  for (final e in logs) {
    if (e['bikeId'] != bikeId) continue;
    final a = '${e['activity'] ?? ''} ${e['notes'] ?? ''}'.toLowerCase();
    if (a.contains(n)) return true;
  }
  return false;
}

bool _isPark(BikeSetup s) {
  final blob = '${s.conditions} ${s.label}'.toLowerCase();
  return blob.contains('bikepark') ||
      blob.contains('park') ||
      blob.contains('dh');
}

bool _isTrail(BikeSetup s) {
  final blob = '${s.conditions} ${s.label}'.toLowerCase();
  return blob.contains('trail') ||
      blob.contains('general') ||
      blob.contains('wet') ||
      blob.contains('dry') ||
      blob.contains('mixed');
}

/// Slots the rider may add for this bike — never the full 25-ghost catalog.
List<ComponentSlot> addableSlotsFor(WerkstattSetupPlan plan) {
  final slots = <ComponentSlot>{
    ComponentSlot.tireFront,
    ComponentSlot.tireRear,
    ComponentSlot.chain,
    ComponentSlot.brakeFront,
    ComponentSlot.brakeRear,
    ...plan.emphasisSlots,
  };
  if (plan.kind == WerkstattKind.urban) {
    slots.addAll([
      ComponentSlot.light,
      ComponentSlot.lock,
      ComponentSlot.rack,
    ]);
  }
  if (plan.kind == WerkstattKind.gravel) {
    slots.add(ComponentSlot.bags);
  }
  if (plan.hasSuspension) {
    slots.addAll([ComponentSlot.fork, ComponentSlot.rearShock]);
  }
  if (plan.hasElectricAssist) {
    slots.addAll([
      ComponentSlot.motor,
      ComponentSlot.battery,
      ComponentSlot.display,
    ]);
  }
  slots.remove(ComponentSlot.other);
  return slots.toList();
}

DieBoxPlan planDieBox({
  required Bike bike,
  List<BikeComponent> components = const [],
  BikeSetup? currentSetup,
  List<BikeSetup> setups = const [],
  List<MaintenanceAlert> due = const [],
  List<Map<String, dynamic>> logs = const [],
  bool cscPaired = false,
}) {
  final setup = planWerkstattSetup(bike: bike, components: components);
  final installed = components.where((c) => c.isInstalled).toList();
  final kind = setup.kind;

  final hasLights = _hasSlot(installed, ComponentSlot.light);
  final hasLock = _hasSlot(installed, ComponentSlot.lock);
  final hasRack = _hasSlot(installed, ComponentSlot.rack);
  final hasBags = _hasSlot(installed, ComponentSlot.bags);
  final hasChain = _hasSlot(installed, ComponentSlot.chain);
  final hasBrakes = _hasSlot(installed, ComponentSlot.brakeFront) ||
      _hasSlot(installed, ComponentSlot.brakeRear);
  final pressureKnown = _userLoggedPressure(setups) ||
      _logMentions(logs, bike.id, 'druck');
  final sagKnown = setup.hasSuspension && _userLoggedSag(setups);
  final chainMeasured = _logMentions(logs, bike.id, 'kette gemessen') ||
      _logMentions(logs, bike.id, 'chain_measured');

  final everyday = kind == WerkstattKind.urban;
  final gravel = kind == WerkstattKind.gravel;
  final road = kind == WerkstattKind.road;
  final mtb = kind == WerkstattKind.mtb;

  BikeSetup? park;
  BikeSetup? trail;
  for (final s in setups) {
    if (park == null && _isPark(s)) park = s;
    if (trail == null && _isTrail(s) && !_isPark(s)) trail = s;
  }
  final showParkTrail = mtb && park != null && trail != null;

  final chips = <DieBoxChip>[];
  if (setup.wheelLabel != null) {
    chips.add(DieBoxChip(label: setup.wheelLabel!));
  }
  if (everyday) {
    chips.add(DieBoxChip(label: 'Licht', known: hasLights));
    chips.add(DieBoxChip(label: 'Schloss', known: hasLock));
    chips.add(DieBoxChip(label: 'Träger', known: hasRack));
    chips.add(DieBoxChip(label: 'Kette', known: hasChain || chainMeasured));
    chips.add(DieBoxChip(label: 'Druck', known: pressureKnown));
  }
  if (gravel) {
    chips.add(DieBoxChip(label: 'Druck', known: pressureKnown));
    chips.add(DieBoxChip(label: 'Taschen', known: hasBags));
    chips.add(const DieBoxChip(label: 'Cockpit'));
    chips.add(DieBoxChip(label: 'Kette', known: hasChain || chainMeasured));
  }
  if (road) {
    chips.add(DieBoxChip(label: 'Druck', known: pressureKnown));
    chips.add(DieBoxChip(label: 'Kette', known: chainMeasured));
    chips.add(const DieBoxChip(label: 'Cockpit'));
  }
  if (mtb) {
    if (setup.hasSuspension) {
      final t =
          '${bike.travelFrontMm ?? '–'}/${bike.travelRearMm ?? '–'} mm';
      chips.add(DieBoxChip(label: t));
      chips.add(DieBoxChip(label: 'SAG', known: sagKnown));
    } else {
      chips.add(const DieBoxChip(label: 'Federweg', known: false));
    }
    chips.add(DieBoxChip(label: 'Reifen', known: pressureKnown));
    if (setup.hasDropper) chips.add(const DieBoxChip(label: 'Vario'));
    chips.add(DieBoxChip(label: 'Bremsen', known: hasBrakes));
    if (showParkTrail) chips.add(const DieBoxChip(label: 'Park | Trail'));
  }
  if (setup.hasElectricAssist) {
    chips.add(DieBoxChip(label: 'CSC', known: cscPaired));
    chips.add(const DieBoxChip(label: 'Akku ehrlich'));
  }
  if (hasLights && !everyday) {
    chips.add(const DieBoxChip(label: 'Licht'));
  }

  final today = <DieBoxTodayItem>[];
  if (!bike.isActive) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.setActive,
        title: 'Dieses Rad nach vorn',
        hint: 'Ein Bewohner in der Box — Umschalten ist Wohnrecht.',
        cta: 'Als aktiv setzen',
      ),
    );
  }
  if (everyday && !hasLights) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.lightsMissing,
        title: 'Licht nicht eingetragen',
        hint: 'Kein Ghost-Fahrwerk. Nur einhaken, wenn Licht wirklich da ist.',
        cta: 'Licht eintragen',
        slot: ComponentSlot.light,
      ),
    );
  }
  if (everyday && !hasLock) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.lockMissing,
        title: 'Schloss nicht eingetragen',
        hint: 'Alltag: anschließen, nicht nur abschließen.',
        cta: 'Schloss eintragen',
        slot: ComponentSlot.lock,
      ),
    );
  }
  if (everyday && !hasRack) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.rackMissing,
        title: 'Gepäckträger nicht eingetragen',
        hint: 'Nur wenn das Rad einen hat.',
        cta: 'Träger eintragen',
        slot: ComponentSlot.rack,
      ),
    );
  }
  if (gravel && !hasBags) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.bagsMissing,
        title: 'Taschen nicht eingetragen',
        hint: 'Kein erfundenes Apidura-Set — nur wenn Taschen am Rad sind.',
        cta: 'Taschen eintragen',
        slot: ComponentSlot.bags,
      ),
    );
  }
  if ((everyday || gravel || road) && !pressureKnown) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.pressureUnknown,
        title: 'Druck nicht gemessen',
        hint: 'Am Rad nachmessen. Keine OEM-Tabelle, kein erfundener psi.',
        cta: 'Druck merken',
      ),
    );
  }
  if (mtb && setup.hasSuspension && !pressureKnown) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.pressureUnknown,
        title: 'Reifendruck nicht gemessen',
        hint: 'psi am Ventil, nicht aus einer Gewichtstabelle.',
        cta: 'Druck merken',
      ),
    );
  }
  if (mtb && !setup.hasSuspension) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.travelUnknown,
        title: 'Federweg nicht eingetragen',
        hint: 'Keine erfundenen Fox-Zahlen. Travel nur wenn er am Rad steht.',
        cta: 'Federweg eintragen',
      ),
    );
  }
  if (mtb && setup.hasSuspension && !sagKnown) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.sagUnknown,
        title: 'SAG nicht gemessen',
        hint: 'O-Ring, Attack-Position, Prozent eintragen. Kein OEM-psi als SAG.',
        cta: 'SAG messen',
      ),
    );
  }
  if ((road || gravel || everyday) && !chainMeasured) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.chainTeach,
        title: 'Kette noch nicht gemessen',
        hint:
            'Die Lehre schlägt jede Kilometer-Rechnung. Messen, dann hier merken.',
        cta: 'Kette gemessen',
        slot: ComponentSlot.chain,
      ),
    );
  }
  if (mtb && !hasBrakes) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.brakesUnknown,
        title: 'Beläge nicht eingetragen',
        hint: 'Park braucht Beläge in der Box — nur wenn sie am Rad sind.',
        cta: 'Bremse eintragen',
        slot: ComponentSlot.brakeFront,
      ),
    );
  }
  // CSC pairing lives in the Werkstatt bar — never a Heute/primary CTA.
  for (final a in due.take(4)) {
    final teachChain = a.slot == ComponentSlot.chain;
    today.add(
      DieBoxTodayItem(
        id: DieBoxItemId.dueCare,
        title: teachChain ? 'Kette mit der Lehre prüfen' : a.label,
        hint: teachChain
            ? 'Kein km-Orakel. Anschauen und messen.'
            : '${a.remainingLabel}${a.sourceLabel != null ? ' · ${a.sourceLabel}' : ''}',
        cta: 'Erledigt',
        slot: a.slot,
        due: a,
      ),
    );
  }
  if (showParkTrail) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.parkTrail,
        title: 'Park oder Trail',
        hint: 'Nur weil beide Setups existieren — kein zweiter Modus erfunden.',
        cta: 'Wechseln',
      ),
    );
  }

  DieBoxReadiness readiness;
  final unknownCount = today
      .where(
        (t) =>
            t.id != DieBoxItemId.setActive &&
            t.id != DieBoxItemId.dueCare &&
            t.id != DieBoxItemId.parkTrail,
      )
      .length;
  final hasDue = today.any((t) => t.id == DieBoxItemId.dueCare);
  if (!bike.isActive) {
    readiness = DieBoxReadiness.almost;
  } else if (unknownCount == 0 && !hasDue) {
    readiness = DieBoxReadiness.ready;
  } else if (unknownCount <= 2 && !hasDue) {
    readiness = DieBoxReadiness.almost;
  } else {
    readiness = DieBoxReadiness.unknown;
  }

  final sentence = _sentence(
    bike: bike,
    kind: kind,
    readiness: readiness,
    everyday: everyday,
    gravel: gravel,
    road: road,
    mtb: mtb,
    hasLights: hasLights,
    hasChain: hasChain || chainMeasured,
    pressureKnown: pressureKnown,
    sagKnown: sagKnown,
    hasBags: hasBags,
    chainMeasured: chainMeasured,
    showParkTrail: showParkTrail,
    park: park,
  );

  final priority = addableSlotsFor(setup);
  final onBike = <BikeComponent>[
    for (final s in priority)
      if (installed.any((c) => c.slot == s))
        installed.firstWhere((c) => c.slot == s),
  ];
  for (final c in installed) {
    if (!onBike.any((x) => x.id == c.id)) onBike.add(c);
  }

  return DieBoxPlan(
    setup: setup,
    readiness: readiness,
    sentence: sentence,
    chips: chips,
    today: today,
    onBike: onBike,
    addableSlots: addableSlotsFor(setup),
    showParkTrail: showParkTrail,
    parkSetup: park,
    trailSetup: trail,
  );
}

String _sentence({
  required Bike bike,
  required WerkstattKind kind,
  required DieBoxReadiness readiness,
  required bool everyday,
  required bool gravel,
  required bool road,
  required bool mtb,
  required bool hasLights,
  required bool hasChain,
  required bool pressureKnown,
  required bool sagKnown,
  required bool hasBags,
  required bool chainMeasured,
  required bool showParkTrail,
  required BikeSetup? park,
}) {
  if (everyday) {
    if (readiness == DieBoxReadiness.ready) {
      return '${bike.name} · Montag-bereit · Licht und Kette ok';
    }
    final bits = <String>[
      if (hasLights && hasChain) 'Licht und Kette ok',
      if (!pressureKnown) 'Druck nicht gemessen',
      if (!hasLights) 'Licht nicht eingetragen',
    ];
    return bits.isEmpty
        ? '${bike.name} · noch nicht bereit'
        : '${bike.name} · ${bits.join(' · ')}';
  }
  if (gravel) {
    final wheel = bike.wheelSize?.label ?? 'Laufrad offen';
    final bits = <String>[
      wheel,
      pressureKnown ? 'Druck gemerkt' : 'Druck grob — nachmessen',
      hasBags ? 'Taschen da' : 'Taschen nicht eingetragen',
    ];
    return '${bike.name} · ${bits.join(' · ')}';
  }
  if (road) {
    final wheel = bike.wheelSize?.label ?? '700c';
    final bits = <String>[
      wheel,
      chainMeasured ? 'Kette gemessen' : 'Kette noch nicht gemessen',
      pressureKnown ? 'Druck gemerkt' : 'Druck heute offen',
    ];
    return '${bike.name} · ${bits.join(' · ')}';
  }
  if (mtb) {
    if (showParkTrail && park?.isCurrent == true) {
      return 'Park-Setup · ${sagKnown ? 'SAG gemerkt' : 'SAG nicht gemessen'}';
    }
    if ((bike.travelFrontMm ?? 0) == 0 && (bike.travelRearMm ?? 0) == 0) {
      return '${bike.name} · Federweg nicht eingetragen';
    }
    final travel =
        '${bike.travelFrontMm ?? '–'}/${bike.travelRearMm ?? '–'}';
    return '${bike.name} · $travel · ${sagKnown ? 'SAG gemerkt' : 'SAG nicht gemessen'}';
  }
  return '${bike.name} · ${bike.categoryLabel}';
}

String dieBoxReadinessLabel(DieBoxReadiness r) => switch (r) {
      DieBoxReadiness.ready => 'Bereit',
      DieBoxReadiness.almost => 'Fast',
      DieBoxReadiness.unknown => 'Unbekannt',
    };
