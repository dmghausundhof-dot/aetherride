import '../bike.dart';
import '../component.dart';

/// Disziplin für Intervall-Defaults. Schmutz/Nässe (MTB) verkürzt.
enum RideDiscipline { mtb, gravel, road, city }

RideDiscipline rideDisciplineOf(Bike bike) {
  return switch (bike.category) {
    BikeCategory.mtbTrail ||
    BikeCategory.mtbAm ||
    BikeCategory.mtbEnduro ||
    BikeCategory.dh ||
    BikeCategory.emtb =>
      RideDiscipline.mtb,
    BikeCategory.gravel => RideDiscipline.gravel,
    BikeCategory.road => RideDiscipline.road,
    _ => RideDiscipline.city,
  };
}

/// Quellen (Recherche 2026-08):
/// - Kette: Park Tool 0,5 % bei 11s+ — km nur Prüf-Default, kein Ersatz-km.
///   https://www.parktool.com/en-int/blog/repair-help/when-to-replace-a-chain-on-a-bicycle
///   BikeRadar: 11–13s bei 0,5 %, 6–10s bei 0,75 %.
///   https://www.bikeradar.com/advice/workshop/how-to-know-when-its-time-to-replace-your-bicycle-chain
///   eMTB kürzer (WatchMy.bike: 1000–2000 km Kette) → prüfen früher.
/// - Kassette: 2–3 Ketten wenn rechtzeitig getauscht (Park Tool / WatchMy.bike).
/// - Beläge: Hersteller ohne km. Spanne WatchMy.bike MTB 500–2000, Gravel 2000–5000,
///   Road trocken 4000–8000. Default = unteres Drittel (prüfen, nicht tauschen).
///   https://watchmy.bike/blog/brake-pads-when-to-replace
/// - Reifen: Schwalbe Standard 2000–5000 km, Marathon 6000–12000, MTB keine km.
///   https://www.schwalbe.com/en/technology-faq/tire-wear/
/// - Fahrwerk: RockShox Lower 50 h / Full 200 h.
///   https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product
///   Fox Full 125 h oder 1 Jahr, earlier lowers 30–50 h (Shops).
///   https://www.ridefoxaustralia.com.au/pages/service-intervals
///   Öhlins Lower 50 h / Full 100 h oder 1 Jahr.
///   https://www.ohlins.com/en-us/mountain-bike
///   App-Default Full: 125 h **oder** 365 Tage (konservativ „prüfen lassen“).
/// - Vario: RockShox Reverb Lower-Post 50 h.
/// - Lager: jährlich / ~5000 km (Bike Gremlin, L'Atelier 6–12 Monate).
///   https://bike.bikegremlin.com/19342/bicycle-maintenance-service-intervals/
/// - Bremsen entlüften: SRAM DOT mind. 1×/Jahr. Magura Royal Blood altert nicht.
///   Default: 12 Monate Druckpunkt prüfen (DOT: entlüften).
///   https://support.sram.com/hc/en-us/articles/5927419450651-How-often-should-I-bleed-my-SRAM-DOT-brakes
/// - E-Bike: Bosch Erstinspektion ~4 Wochen / 300 km, danach Händler-Intervall;
///   Brose mind. 1×/Jahr; Shimano STEPS Händler jährlich.
///   https://www.bosch-ebike.com/en/service/dealer-service

class IntervalTemplate {
  const IntervalTemplate({
    required this.slot,
    required this.label,
    this.intervalKm,
    this.intervalHours,
    this.intervalDays,
    required this.sourceLabel,
    this.sourceUrl,
    this.sourceSpan,
    this.bikeWide = false,
    this.needsSlot = true,
  });

  final ComponentSlot slot;
  final String label;
  final double? intervalKm;
  final double? intervalHours;
  final int? intervalDays;
  final String sourceLabel;
  final String? sourceUrl;

  /// Hersteller-Spanne, wenn der Default abweicht.
  final String? sourceSpan;

  /// Auch ohne eingetragenes Teil — Zähler am Rad reicht.
  final bool bikeWide;

  /// Slot muss verbaut sein (Gabel/Dämpfer/Vario).
  final bool needsSlot;
}

double chainCheckKm(Bike bike) {
  final e = bike.hasElectricAssist;
  return switch (rideDisciplineOf(bike)) {
    RideDiscipline.mtb => e ? 700 : 1000,
    RideDiscipline.gravel => 1200,
    RideDiscipline.road => 1500,
    RideDiscipline.city => e ? 1000 : 1200,
  };
}

double cassetteCheckKm(Bike bike) {
  return switch (rideDisciplineOf(bike)) {
    RideDiscipline.mtb => 4000,
    RideDiscipline.gravel => 6000,
    RideDiscipline.road => 8000,
    RideDiscipline.city => 6000,
  };
}

double brakePadCheckKm(Bike bike, {required bool rear}) {
  final e = bike.hasElectricAssist;
  final base = switch (rideDisciplineOf(bike)) {
    RideDiscipline.mtb => e ? 800 : 1000,
    RideDiscipline.gravel => 2000,
    RideDiscipline.road => 3000,
    RideDiscipline.city => 2000,
  };
  return rear ? (base * 0.8).roundToDouble() : base.toDouble();
}

double tireCheckKm(Bike bike) {
  return switch (rideDisciplineOf(bike)) {
    RideDiscipline.mtb => 1500,
    RideDiscipline.gravel => 3000,
    RideDiscipline.road => 4000,
    RideDiscipline.city => 5000,
  };
}

double bearingCheckKm(Bike bike) {
  return rideDisciplineOf(bike) == RideDiscipline.mtb ? 4000 : 5000;
}

/// Kategorie-abhängige Templates. Vorhandene 50 h Lower-Leg bleiben.
List<IntervalTemplate> intervalTemplatesFor(Bike bike) {
  final e = bike.hasElectricAssist;
  final mtb = rideDisciplineOf(bike) == RideDiscipline.mtb;
  final dropperSport = mtb || rideDisciplineOf(bike) == RideDiscipline.gravel;
  return [
    IntervalTemplate(
      slot: ComponentSlot.frame,
      label: e ? 'Jährliche E-Bike-Inspektion' : 'Jährliche Inspektion',
      intervalDays: 365,
      intervalKm: e ? 1500 : null,
      bikeWide: true,
      needsSlot: false,
      sourceLabel: e
          ? 'Bosch / Brose / Shimano STEPS — jährlich'
          : 'Werkstatt-Schnitt 12 Monate',
      sourceUrl: 'https://www.bosch-ebike.com/en/service/dealer-service',
      sourceSpan: e
          ? 'Bosch Erstcheck 300 km/4 Wochen, danach Händler; Brose ≥1×/Jahr'
          : 'Unabhängig vom Sport, Schmutz verkürzt',
    ),
    IntervalTemplate(
      slot: ComponentSlot.chain,
      label: 'Kettenverschleiß prüfen',
      intervalKm: chainCheckKm(bike),
      bikeWide: true,
      needsSlot: false,
      sourceLabel: 'Park Tool 0,5 % Dehnung (11s+)',
      sourceUrl:
          'https://www.parktool.com/en-int/blog/repair-help/when-to-replace-a-chain-on-a-bicycle',
      sourceSpan:
          'Wechsel nach Lehre, nicht nach km. Prüf-Default ${chainCheckKm(bike).round()} km',
    ),
    IntervalTemplate(
      slot: ComponentSlot.cassette,
      label: 'Kassette prüfen (nach 2–3 Ketten)',
      intervalKm: cassetteCheckKm(bike),
      bikeWide: true,
      needsSlot: false,
      sourceLabel: 'Park Tool / 2–3 Ketten',
      sourceUrl:
          'https://www.parktool.com/en-int/blog/repair-help/when-to-replace-a-chain-on-a-bicycle',
      sourceSpan: 'Spanne ~4000–12000 km je Pflege',
    ),
    IntervalTemplate(
      slot: ComponentSlot.brakeFront,
      label: 'Bremsbeläge vorne prüfen',
      intervalKm: brakePadCheckKm(bike, rear: false),
      bikeWide: true,
      needsSlot: false,
      sourceLabel: 'WatchMy.bike / Industriepraxis',
      sourceUrl: 'https://watchmy.bike/blog/brake-pads-when-to-replace',
      sourceSpan: 'MTB 500–2000 · Gravel 2000–5000 · Road 4000–8000 km',
    ),
    IntervalTemplate(
      slot: ComponentSlot.brakeRear,
      label: 'Bremsbeläge hinten prüfen',
      intervalKm: brakePadCheckKm(bike, rear: true),
      bikeWide: true,
      needsSlot: false,
      sourceLabel: 'WatchMy.bike / Industriepraxis',
      sourceUrl: 'https://watchmy.bike/blog/brake-pads-when-to-replace',
    ),
    IntervalTemplate(
      slot: ComponentSlot.tireRear,
      label: 'Reifen prüfen',
      intervalKm: tireCheckKm(bike),
      bikeWide: true,
      needsSlot: false,
      sourceLabel: 'Schwalbe Laufleistung',
      sourceUrl: 'https://www.schwalbe.com/en/technology-faq/tire-wear/',
      sourceSpan: 'Standard 2000–5000 · Marathon 6000–12000 · MTB stilabhängig',
    ),
    IntervalTemplate(
      slot: ComponentSlot.tireFront,
      label: 'Tubeless-Milch erneuern',
      intervalDays: 120,
      sourceLabel: 'Tubeless-Praxis 3–6 Monate',
      sourceSpan: 'Default 120 Tage (Mitte der Spanne)',
    ),
    IntervalTemplate(
      slot: ComponentSlot.tireRear,
      label: 'Tubeless-Milch erneuern',
      intervalDays: 120,
      sourceLabel: 'Tubeless-Praxis 3–6 Monate',
    ),
    IntervalTemplate(
      slot: ComponentSlot.headset,
      label: 'Lager prüfen (Steuersatz/Naben/Tretlager)',
      intervalKm: bearingCheckKm(bike),
      intervalDays: 365,
      bikeWide: true,
      needsSlot: false,
      sourceLabel: 'Bike Gremlin / L\'Atelier 6–12 Monate',
      sourceUrl:
          'https://bike.bikegremlin.com/19342/bicycle-maintenance-service-intervals/',
      sourceSpan: 'Nass/MTB kürzer — Default ${bearingCheckKm(bike).round()} km oder 1 Jahr',
    ),
    IntervalTemplate(
      slot: ComponentSlot.brakeFront,
      label: 'Bremsen: Druckpunkt / Entlüften',
      intervalDays: 365,
      sourceLabel: 'SRAM DOT ≥1×/Jahr; Magura nur bei Schwamm',
      sourceUrl:
          'https://support.sram.com/hc/en-us/articles/5927419450651-How-often-should-I-bleed-my-SRAM-DOT-brakes',
      sourceSpan: 'Mineralöl oft 18–24 Monate; Default 12 Monate prüfen',
    ),
    if (e)
      IntervalTemplate(
        slot: ComponentSlot.battery,
        label: 'Akku-Check (Kontakte, Kapazität)',
        intervalDays: 365,
        bikeWide: true,
        needsSlot: false,
        sourceLabel: 'Bosch / Shimano STEPS jährlich',
        sourceUrl: 'https://www.bosch-ebike.com/en/service/dealer-service',
      ),
    if (mtb) ...[
      IntervalTemplate(
        slot: ComponentSlot.fork,
        label: 'Gabel Lower-Leg Service',
        intervalHours: 50,
        sourceLabel: 'RockShox / Öhlins 50 h',
        sourceUrl:
            'https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product',
        sourceSpan: 'Fox-Shops oft 30–50 h lowers; Default 50 h',
      ),
      IntervalTemplate(
        slot: ComponentSlot.fork,
        label: 'Gabel Vollservice (Feder/Dämpfer)',
        intervalHours: 125,
        intervalDays: 365,
        sourceLabel: 'Fox 125 h / 1 Jahr (konservativ)',
        sourceUrl: 'https://www.ridefoxaustralia.com.au/pages/service-intervals',
        sourceSpan: 'RockShox Full 200 h · Öhlins 100 h/Jahr · Default 125 h oder 1 Jahr',
      ),
      IntervalTemplate(
        slot: ComponentSlot.rearShock,
        label: 'Dämpfer Air-Can Service',
        intervalHours: 50,
        sourceLabel: 'RockShox Service FAQ',
        sourceUrl:
            'https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product',
      ),
      IntervalTemplate(
        slot: ComponentSlot.rearShock,
        label: 'Dämpfer Vollservice',
        intervalHours: 125,
        intervalDays: 365,
        sourceLabel: 'Fox 125 h / 1 Jahr (konservativ)',
        sourceUrl: 'https://www.ridefoxaustralia.com.au/pages/service-intervals',
        sourceSpan: 'RockShox Deluxe/SD 200 h · Default 125 h oder 1 Jahr',
      ),
    ],
    if (dropperSport)
      IntervalTemplate(
        slot: ComponentSlot.seatpost,
        label: 'Dropper Lower-Post Service',
        intervalHours: 50,
        sourceLabel: 'RockShox Reverb 50 h',
        sourceUrl:
            'https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product',
      ),
  ];
}

/// MTB-Defaults — nur noch für Tests/Doku, die die alte Konstante erwarten.
List<IntervalTemplate> get defaultIntervalTemplates => intervalTemplatesFor(
      const Bike(id: '_', name: '', category: BikeCategory.mtbAm),
    );

enum DueStatus { ok, dueSoon, overdue }

class MaintenanceAlert {
  const MaintenanceAlert({
    required this.slot,
    required this.label,
    required this.status,
    required this.progressPct,
    required this.remainingLabel,
    this.sourceLabel,
    this.sourceSpan,
    this.neverLogged = false,
  });

  final ComponentSlot slot;
  final String label;
  final DueStatus status;
  final int progressPct;
  final String remainingLabel;
  final String? sourceLabel;
  final String? sourceSpan;
  final bool neverLogged;
}

/// Fällige (und optional nächste) Checks. Quelle: km-/Stunden-Zähler + Logs.
List<MaintenanceAlert> listDueMaintenance({
  required Bike bike,
  required List<BikeComponent> components,
  DateTime? now,
  List<Map<String, dynamic>> logs = const [],
  bool includeUpcoming = false,
}) {
  final installed = components.where((c) => c.isInstalled).toList();
  final slots = installed.map((c) => c.slot).toSet();
  final clock = now ?? DateTime.now();
  final bikeLogs = [
    for (final e in logs)
      if (e['bikeId'] == bike.id) e,
  ];
  final alerts = <MaintenanceAlert>[];

  final inspection = _inspectionAlert(
    bike: bike,
    logs: bikeLogs,
    now: clock,
    includeUpcoming: includeUpcoming,
  );
  if (inspection != null) alerts.add(inspection);

  for (final t in intervalTemplatesFor(bike)) {
    if (t.slot == ComponentSlot.frame && t.intervalDays == 365) {
      continue;
    }
    final hasSlot = slots.contains(t.slot);
    if (t.needsSlot && !hasSlot && !t.bikeWide) continue;
    if (!t.bikeWide && !hasSlot) continue;
    BikeComponent? comp;
    if (hasSlot) {
      comp = installed.firstWhere((c) => c.slot == t.slot);
    }
    final due = _evaluate(
      template: t,
      bike: bike,
      component: comp,
      now: clock,
      logs: bikeLogs,
    );
    if (due.status == DueStatus.ok) {
      if (!includeUpcoming) continue;
      if (due.progressPct <= 0) continue;
    }
    alerts.add(
      MaintenanceAlert(
        slot: t.slot,
        label: t.label,
        status: due.status,
        progressPct: due.progressPct,
        remainingLabel: due.remainingLabel,
        sourceLabel: t.sourceLabel,
        sourceSpan: t.sourceSpan,
      ),
    );
  }

  alerts.sort((a, b) {
    final rank = _statusRank(b.status) - _statusRank(a.status);
    if (rank != 0) return rank;
    return b.progressPct.compareTo(a.progressPct);
  });
  if (includeUpcoming && alerts.length > 10) {
    return alerts.sublist(0, 10);
  }
  return alerts;
}

int _statusRank(DueStatus s) => switch (s) {
      DueStatus.overdue => 2,
      DueStatus.dueSoon => 1,
      DueStatus.ok => 0,
    };

MaintenanceAlert? _inspectionAlert({
  required Bike bike,
  required List<Map<String, dynamic>> logs,
  required DateTime now,
  required bool includeUpcoming,
}) {
  final last = _lastInspection(bike, logs);
  final e = bike.hasElectricAssist;
  const firstKm = 300.0;
  const firstDays = 28;
  final annualKm = e ? 1500.0 : null;

  if (last == null) {
    final fromPurchase = _parseIso(bike.owner.purchasedAt);
    if (fromPurchase != null) {
      final days = now.difference(fromPurchase).inDays;
      final usedKm = bike.odometerKm;
      final firstDue = usedKm >= firstKm || days >= firstDays;
      if (!firstDue && !includeUpcoming) return null;
      final progress = _maxRatio([
        usedKm / firstKm,
        days / firstDays,
      ]);
      return MaintenanceAlert(
        slot: ComponentSlot.frame,
        label: e ? 'Erste E-Bike-Inspektion' : 'Erste Inspektion',
        status: _statusFrom(progress, remainingDays: firstDays - days),
        progressPct: (progress * 100).round().clamp(0, 100),
        remainingLabel: firstDue
            ? 'fällig · Bosch ~300 km / 4 Wochen'
            : '${(firstKm - usedKm).clamp(0, firstKm).round()} km · ${(firstDays - days).clamp(0, firstDays)} Tage',
        sourceLabel: 'Bosch Händler-Service',
        sourceSpan: 'Danach jährlich',
        neverLogged: true,
      );
    }
    final ageYears = bike.year == null ? null : now.year - bike.year!;
    final oldOrUsed = bike.odometerKm >= firstKm ||
        bike.hours >= 20 ||
        (ageYears != null && ageYears >= 1);
    if (!oldOrUsed && !includeUpcoming) return null;
    if (!oldOrUsed) {
      return MaintenanceAlert(
        slot: ComponentSlot.frame,
        label: e ? 'Erste E-Bike-Inspektion' : 'Erste Inspektion',
        status: DueStatus.ok,
        progressPct: (bike.odometerKm / firstKm * 100).round().clamp(0, 99),
        remainingLabel:
            '${(firstKm - bike.odometerKm).clamp(0, firstKm).round()} km',
        sourceLabel: 'Bosch Erstcheck ~300 km',
        neverLogged: true,
      );
    }
    return MaintenanceAlert(
      slot: ComponentSlot.frame,
      label: e ? 'Jährliche E-Bike-Inspektion' : 'Jährliche Inspektion',
      status: DueStatus.overdue,
      progressPct: 100,
      remainingLabel: 'noch keine Inspektion gemerkt',
      sourceLabel: e
          ? 'Bosch / Brose / Shimano STEPS — jährlich'
          : 'Werkstatt-Schnitt 12 Monate',
      neverLogged: true,
    );
  }

  final usedDays = now.difference(last.at).inDays;
  final usedKm = (bike.odometerKm - last.odo).clamp(0, double.infinity);
  final ratios = <double>[usedDays / 365];
  if (annualKm != null) ratios.add(usedKm / annualKm);
  final progress = _maxRatio(ratios);
  final status = _statusFrom(progress, remainingDays: 365 - usedDays);
  if (status == DueStatus.ok && !includeUpcoming) return null;
  return MaintenanceAlert(
    slot: ComponentSlot.frame,
    label: e ? 'Jährliche E-Bike-Inspektion' : 'Jährliche Inspektion',
    status: status,
    progressPct: (progress * 100).round().clamp(0, 100),
    remainingLabel: [
      '${(365 - usedDays).clamp(0, 365)} Tage',
      if (annualKm != null)
        '${(annualKm - usedKm).clamp(0, annualKm).round()} km',
    ].join(' · '),
    sourceLabel: e
        ? 'Bosch / Brose / Shimano STEPS — jährlich'
        : 'Werkstatt-Schnitt 12 Monate',
  );
}

({DateTime at, double odo, double hours})? _lastInspection(
  Bike bike,
  List<Map<String, dynamic>> logs,
) {
  DateTime? bestAt;
  var bestOdo = 0.0;
  var bestH = 0.0;
  final ownerAt = _parseIso(bike.owner.lastServiceAt);
  if (ownerAt != null) {
    bestAt = ownerAt;
  }
  for (final e in logs) {
    if (!_looksLikeInspection(e)) continue;
    final at = _parseIso('${e['date'] ?? ''}');
    if (at == null) continue;
    if (bestAt == null || at.isAfter(bestAt)) {
      bestAt = at;
      bestOdo = (e['odometerKm'] as num?)?.toDouble() ?? bike.odometerKm;
      bestH = (e['hours'] as num?)?.toDouble() ?? bike.hours;
    }
  }
  if (bestAt == null) return null;
  return (at: bestAt, odo: bestOdo, hours: bestH);
}

bool _looksLikeInspection(Map<String, dynamic> e) {
  final a = '${e['activity'] ?? ''} ${e['notes'] ?? ''}'.toLowerCase();
  return a.contains('inspektion') ||
      a.contains('inspection') ||
      a.contains('jahres') ||
      a.contains('erstcheck');
}

({DueStatus status, int progressPct, String remainingLabel}) _evaluate({
  required IntervalTemplate template,
  required Bike bike,
  BikeComponent? component,
  required DateTime now,
  required List<Map<String, dynamic>> logs,
}) {
  final last = _lastForTemplate(template, logs);
  final ratios = <double>[];
  final remainders = <String>[];
  var remainingDays = 9999;

  if (template.intervalKm != null) {
    final installed = component?.odometerKm ?? 0;
    final logged = last?.odo ?? 0;
    final start = installed > logged ? installed : logged;
    final used = (bike.odometerKm - start).clamp(0, double.infinity);
    final ratio = used / template.intervalKm!;
    ratios.add(ratio);
    remainders.add(
      '${(template.intervalKm! - used).clamp(0, double.infinity).round()} km',
    );
  }
  if (template.intervalHours != null) {
    final installed = component?.hoursAtInstallResolved ?? 0;
    final logged = last?.hours ?? 0;
    final start = installed > logged ? installed : logged;
    final used = (bike.hours - start).clamp(0, double.infinity);
    final ratio = used / template.intervalHours!;
    ratios.add(ratio);
    remainders.add(
      '${(template.intervalHours! - used).clamp(0, double.infinity).round()} h',
    );
  }
  if (template.intervalDays != null) {
    final start = component?.installedAt ?? last?.at;
    if (start != null) {
      final usedDays = now.difference(start).inMilliseconds / 86400000;
      final ratio = usedDays / template.intervalDays!;
      ratios.add(ratio);
      remainingDays = (template.intervalDays! - usedDays).round();
      remainders.add('${remainingDays.clamp(0, template.intervalDays!)} Tage');
    }
  }

  if (ratios.isEmpty) {
    return (
      status: DueStatus.ok,
      progressPct: 0,
      remainingLabel: 'Kein Intervall',
    );
  }

  final progress = _maxRatio(ratios);
  final progressPct = (progress * 100).round().clamp(0, 100);
  return (
    status: _statusFrom(progress, remainingDays: remainingDays),
    progressPct: progressPct,
    remainingLabel: remainders.join(' · '),
  );
}

({DateTime at, double odo, double hours})? _lastForTemplate(
  IntervalTemplate template,
  List<Map<String, dynamic>> logs,
) {
  final needles = _needlesFor(template);
  DateTime? bestAt;
  var bestOdo = 0.0;
  var bestH = 0.0;
  for (final e in logs) {
    final blob = '${e['activity'] ?? ''} ${e['notes'] ?? ''}'.toLowerCase();
    if (!needles.any(blob.contains)) continue;
    final at = _parseIso('${e['date'] ?? ''}');
    if (at == null) continue;
    if (bestAt == null || at.isAfter(bestAt)) {
      bestAt = at;
      bestOdo = (e['odometerKm'] as num?)?.toDouble() ?? 0;
      bestH = (e['hours'] as num?)?.toDouble() ?? 0;
    }
  }
  if (bestAt == null) return null;
  return (at: bestAt, odo: bestOdo, hours: bestH);
}

List<String> _needlesFor(IntervalTemplate t) {
  return switch (t.slot) {
    ComponentSlot.chain => ['kette', 'chain'],
    ComponentSlot.cassette => ['kassette', 'cassette', 'ritzel'],
    ComponentSlot.brakeFront ||
    ComponentSlot.brakeRear =>
      ['belag', 'bremse', 'brake', 'entlüft'],
    ComponentSlot.tireFront ||
    ComponentSlot.tireRear =>
      ['reifen', 'tubeless', 'milch', 'tire'],
    ComponentSlot.headset ||
    ComponentSlot.frontHub ||
    ComponentSlot.rearHub ||
    ComponentSlot.bottomBracket =>
      ['lager', 'steuersatz', 'nabe', 'tretlager', 'headset'],
    ComponentSlot.fork => ['gabel', 'fork', 'lower'],
    ComponentSlot.rearShock => ['dämpfer', 'shock', 'air-can'],
    ComponentSlot.seatpost => ['dropper', 'vario', 'sattelstütze', 'reverb'],
    ComponentSlot.battery => ['akku', 'battery'],
    _ => [t.slot.apiId],
  };
}

DueStatus _statusFrom(double progress, {required int remainingDays}) {
  if (progress >= 1) return DueStatus.overdue;
  if (progress >= 0.80 || remainingDays <= 30) return DueStatus.dueSoon;
  return DueStatus.ok;
}

/// Jung / wenig gefahren — „alles grün“ ohne gemerkte Inspektion ist ehrlich.
bool bikeIsYoungForMaintenance(Bike bike, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final ageYears = bike.year == null ? null : clock.year - bike.year!;
  return bike.odometerKm < 300 &&
      bike.hours < 20 &&
      (ageYears == null || ageYears < 1);
}

bool bikeHasInspectionMemory(
  Bike bike, [
  List<Map<String, dynamic>> logs = const [],
]) {
  if ((bike.owner.lastServiceAt ?? '').trim().isNotEmpty) return true;
  return logs.any(
    (e) => e['bikeId'] == bike.id && _looksLikeInspection(e),
  );
}

/// Leere Heute-/OK-Kopie nur wenn nichts fällig ist und das keine Lüge ist.
bool maintenanceEmptyIsHonestOk({
  required Bike bike,
  List<Map<String, dynamic>> logs = const [],
  DateTime? now,
}) {
  return bikeIsYoungForMaintenance(bike, now: now) ||
      bikeHasInspectionMemory(bike, logs);
}

double _maxRatio(List<double> ratios) {
  var m = 0.0;
  for (final r in ratios) {
    if (r > m) m = r;
  }
  return m;
}

DateTime? _parseIso(String? raw) {
  final t = (raw ?? '').trim();
  if (t.isEmpty) return null;
  return DateTime.tryParse(t.length >= 10 ? t.substring(0, 10) : t);
}
