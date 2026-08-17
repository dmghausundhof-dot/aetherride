import '../bike.dart';
import '../component.dart';
import '../maintenance/intervals.dart';
import '../setup.dart';
import 'werkstatt_setup.dart';

/// Die Box — stall for the active bike. Tab label is the bike name.
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

  DieBoxTodayItem copyWith({
    String? title,
    String? hint,
    String? cta,
    ComponentSlot? slot,
    MaintenanceAlert? due,
  }) {
    return DieBoxTodayItem(
      id: id,
      title: title ?? this.title,
      hint: hint ?? this.hint,
      cta: cta ?? this.cta,
      slot: slot ?? this.slot,
      due: due ?? this.due,
    );
  }
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

  /// Heute without the primary — one next thing, no duplicate card.
  List<DieBoxTodayItem> get heuteRest =>
      today.length <= 1 ? const [] : today.sublist(1);

  bool get isReady => readiness == DieBoxReadiness.ready && today.isEmpty;
}

/// Hof-Tafel: nur fällige Pflege. SAG/Druck/Kette-Heute bleibt in der Box.
DieBoxTodayItem? tafelCareItem(DieBoxPlan plan) {
  DieBoxTodayItem? soon;
  for (final item in plan.today) {
    if (item.id != DieBoxItemId.dueCare) continue;
    if (item.due?.status == DueStatus.overdue) return item;
    soon ??= item;
  }
  return soon;
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

bool _logMentions(
    List<Map<String, dynamic>> logs, String bikeId, String needle) {
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

/// Teile-Tab and Am Rad: addable slots plus rider-typed parts.
/// Catalog OEM dump (headset, saddle with model id) stays off the stall.
List<BikeComponent> listedWorkshopParts({
  required List<BikeComponent> installed,
  required List<ComponentSlot> addable,
}) {
  final listed = <BikeComponent>[
    for (final s in addable)
      if (installed.any((c) => c.slot == s))
        installed.firstWhere((c) => c.slot == s),
  ];
  for (final c in installed) {
    if (listed.any((x) => x.id == c.id)) continue;
    final explicit = c.catalogModelId == null;
    if (explicit) listed.add(c);
  }
  return listed;
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
  if (plan.showsFahrwerk) {
    slots.add(ComponentSlot.fork);
    if (plan.hasRearShock) slots.add(ComponentSlot.rearShock);
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
  final pressureKnown =
      _userLoggedPressure(setups) || _logMentions(logs, bike.id, 'druck');
  final sagKnown = setup.showsFahrwerk && _userLoggedSag(setups);
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

  final hasCockpit = _hasSlot(installed, ComponentSlot.handlebar) ||
      _hasSlot(installed, ComponentSlot.stem);

  // Only known facts on the first surface — gaps live in Heute, not as "offen".
  final chips = <DieBoxChip>[];
  if (setup.wheelLabel != null) {
    chips.add(DieBoxChip(label: setup.wheelLabel!));
  }
  if (everyday) {
    if (hasLights) chips.add(const DieBoxChip(label: 'Licht'));
    if (hasLock) chips.add(const DieBoxChip(label: 'Schloss'));
    if (hasRack) chips.add(const DieBoxChip(label: 'Träger'));
    if (hasChain || chainMeasured) chips.add(const DieBoxChip(label: 'Kette'));
    if (pressureKnown) chips.add(const DieBoxChip(label: 'Druck'));
  }
  if (gravel) {
    if (pressureKnown) chips.add(const DieBoxChip(label: 'Druck'));
    if (hasBags) chips.add(const DieBoxChip(label: 'Taschen'));
    if (hasCockpit) chips.add(const DieBoxChip(label: 'Cockpit'));
    if (hasChain || chainMeasured) chips.add(const DieBoxChip(label: 'Kette'));
  }
  if (road) {
    if (pressureKnown) chips.add(const DieBoxChip(label: 'Druck'));
    if (chainMeasured) chips.add(const DieBoxChip(label: 'Kette'));
    if (hasCockpit) chips.add(const DieBoxChip(label: 'Cockpit'));
  }
  if (mtb) {
    if (pressureKnown) chips.add(const DieBoxChip(label: 'Reifen'));
    if (setup.hasDropper) chips.add(const DieBoxChip(label: 'Vario'));
    if (hasBrakes) chips.add(const DieBoxChip(label: 'Bremsen'));
    if (showParkTrail) chips.add(const DieBoxChip(label: 'Park | Trail'));
  }
  if (setup.showsFahrwerk &&
      ((bike.travelFrontMm ?? 0) > 0 || (bike.travelRearMm ?? 0) > 0)) {
    final t = '${bike.travelFrontMm ?? '–'}/${bike.travelRearMm ?? '–'} mm';
    chips.add(DieBoxChip(label: t));
  }
  if (sagKnown) chips.add(const DieBoxChip(label: 'SAG'));
  if (setup.hasElectricAssist && cscPaired) {
    chips.add(const DieBoxChip(label: 'CSC'));
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
        hint: 'Eines steht in der Box — Umschalten holt es nach vorn.',
        cta: 'Als aktiv setzen',
      ),
    );
  }
  if (everyday && !hasLights) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.lightsMissing,
        title: 'Licht eintragen',
        hint: 'Nur wenn Licht wirklich am Rad ist.',
        cta: 'Licht eintragen',
        slot: ComponentSlot.light,
      ),
    );
  }
  // Schloss, Träger, Taschen: addable, not Heute-nags on an empty stall.
  if ((everyday || gravel || road) && !pressureKnown) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.pressureUnknown,
        title: 'Druck merken',
        hint: 'Vorn und hinten am Ventil ablesen.',
        cta: 'Druck merken',
      ),
    );
  }
  if (mtb && setup.showsFahrwerk && !pressureKnown) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.pressureUnknown,
        title: 'Reifendruck merken',
        hint: 'Vorn und hinten am Ventil ablesen.',
        cta: 'Druck merken',
      ),
    );
  }
  if (mtb && !setup.hasSuspension) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.travelUnknown,
        title: 'Federweg eintragen',
        hint: 'Nur der Federweg, der am Rad steht.',
        cta: 'Federweg eintragen',
      ),
    );
  }
  if (setup.showsFahrwerk && !sagKnown) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.sagUnknown,
        title: 'Federung merken',
        hint: 'Eine Zahl an Gabel und Dämpfer, abgelesen am Rad.',
        cta: 'Federung merken',
      ),
    );
  }
  if ((road || gravel || everyday) && !chainMeasured) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.chainTeach,
        title: 'Kette merken',
        hint: 'Mit der Lehre messen, dann hier merken.',
        cta: 'Kette gemessen',
        slot: ComponentSlot.chain,
      ),
    );
  }
  if (mtb && !hasBrakes) {
    today.add(
      const DieBoxTodayItem(
        id: DieBoxItemId.brakesUnknown,
        title: 'Bremsen eintragen',
        hint: 'Nur wenn Beläge am Rad sind.',
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
            ? 'Anschauen und mit der Lehre messen.'
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
        hint: 'Beide Setups sind da — wechseln, wenn du willst.',
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
    readiness: readiness,
    everyday: everyday,
    gravel: gravel,
    road: road,
    mtb: mtb,
    pressureKnown: pressureKnown,
    hasBags: hasBags,
    chainMeasured: chainMeasured,
    showParkTrail: showParkTrail,
    park: park,
  );

  final priority = addableSlotsFor(setup);
  final onBike = listedWorkshopParts(
    installed: installed,
    addable: priority,
  );

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
  required DieBoxReadiness readiness,
  required bool everyday,
  required bool gravel,
  required bool road,
  required bool mtb,
  required bool pressureKnown,
  required bool hasBags,
  required bool chainMeasured,
  required bool showParkTrail,
  required BikeSetup? park,
}) {
  if (everyday) {
    if (readiness == DieBoxReadiness.ready) {
      return '${bike.name} wohnt hier · Montag-bereit';
    }
    return '${bike.name} wohnt hier';
  }
  if (gravel) {
    final wheel = bike.wheelSize?.label;
    final bits = <String>[
      if (wheel != null) wheel,
      if (pressureKnown) 'Druck gemerkt',
      if (hasBags) 'Taschen da',
    ];
    final core = bits.isEmpty
        ? '${bike.name} wohnt hier'
        : '${bike.name} · ${bits.join(' · ')}';
    return readiness == DieBoxReadiness.ready ? '$core · bereit' : core;
  }
  if (road) {
    final wheel = bike.wheelSize?.label;
    final bits = <String>[
      if (wheel != null) wheel,
      if (chainMeasured) 'Kette gemessen',
      if (pressureKnown) 'Druck gemerkt',
    ];
    final core = bits.isEmpty
        ? '${bike.name} wohnt hier'
        : '${bike.name} · ${bits.join(' · ')}';
    return readiness == DieBoxReadiness.ready ? '$core · bereit' : core;
  }
  if (mtb) {
    if (showParkTrail && park?.isCurrent == true) {
      return 'Park-Setup';
    }
    if ((bike.travelFrontMm ?? 0) == 0 && (bike.travelRearMm ?? 0) == 0) {
      return '${bike.name} wohnt hier';
    }
    final travel = '${bike.travelFrontMm ?? '–'}/${bike.travelRearMm ?? '–'}';
    final drive = bike.hasElectricAssist ? ' · E-Antrieb' : '';
    final core = '${bike.name} · $travel$drive';
    return readiness == DieBoxReadiness.ready ? '$core · bereit' : core;
  }
  return '${bike.name} wohnt hier';
}

String dieBoxReadinessLabel(DieBoxReadiness r) => switch (r) {
      DieBoxReadiness.ready => 'Bereit',
      DieBoxReadiness.almost => 'Fast bereit',
      DieBoxReadiness.unknown => 'Neu hier',
    };
