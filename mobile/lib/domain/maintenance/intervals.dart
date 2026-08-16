import '../bike.dart';
import '../component.dart';

/// Port of web `DEFAULT_INTERVAL_TEMPLATES` (src/lib/maintenance/intervals.ts).

class IntervalTemplate {
  const IntervalTemplate({
    required this.slot,
    required this.label,
    this.intervalKm,
    this.intervalHours,
    this.intervalDays,
    required this.sourceLabel,
    this.sourceUrl,
  });

  final ComponentSlot slot;
  final String label;
  final double? intervalKm;
  final double? intervalHours;
  final int? intervalDays;
  final String sourceLabel;
  final String? sourceUrl;
}

const defaultIntervalTemplates = <IntervalTemplate>[
  IntervalTemplate(
    slot: ComponentSlot.fork,
    label: 'Gabel Lower-Leg Service',
    intervalHours: 50,
    sourceLabel: 'RockShox Service FAQ',
    sourceUrl:
        'https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product',
  ),
  IntervalTemplate(
    slot: ComponentSlot.fork,
    label: 'Gabel Vollservice (Feder/Dämpfer)',
    intervalHours: 200,
    sourceLabel: 'RockShox / Fox Service Docs',
    sourceUrl: 'https://www.sram.com/en/rockshox',
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
    intervalHours: 200,
    sourceLabel: 'RockShox Deluxe/Super Deluxe',
    sourceUrl: 'https://www.sram.com/en/rockshox',
  ),
  IntervalTemplate(
    slot: ComponentSlot.chain,
    label: 'Kettenverschleiß prüfen',
    intervalKm: 1000,
    sourceLabel: 'Park Tool / Industriepraxis 0,5 % Dehnung',
    sourceUrl: 'https://watchmy.bike/blog/how-long-do-bike-parts-last',
  ),
  IntervalTemplate(
    slot: ComponentSlot.cassette,
    label: 'Kassette prüfen (nach 2–3 Ketten)',
    intervalKm: 6000,
    sourceLabel: 'Zero Friction / WatchMy.bike',
    sourceUrl: 'https://watchmy.bike/blog/how-long-do-bike-parts-last',
  ),
  IntervalTemplate(
    slot: ComponentSlot.brakeFront,
    label: 'Bremsbeläge vorne prüfen',
    intervalKm: 1500,
    sourceLabel: 'Industriepraxis (verschleißabhängig)',
  ),
  IntervalTemplate(
    slot: ComponentSlot.brakeRear,
    label: 'Bremsbeläge hinten prüfen',
    intervalKm: 1200,
    sourceLabel: 'Industriepraxis (verschleißabhängig)',
  ),
  IntervalTemplate(
    slot: ComponentSlot.tireFront,
    label: 'Tubeless-Milch erneuern',
    intervalDays: 120,
    sourceLabel: 'Tubeless-Praxis 3–6 Monate',
  ),
  IntervalTemplate(
    slot: ComponentSlot.tireRear,
    label: 'Tubeless-Milch erneuern',
    intervalDays: 120,
    sourceLabel: 'Tubeless-Praxis 3–6 Monate',
  ),
  IntervalTemplate(
    slot: ComponentSlot.seatpost,
    label: 'Dropper Lower-Post Service',
    intervalHours: 50,
    sourceLabel: 'RockShox Reverb Interval',
    sourceUrl:
        'https://support.rockshox.com/hc/en-us/articles/4412306753947-How-often-should-I-service-my-RockShox-product',
  ),
];

enum DueStatus { ok, dueSoon, overdue }

class MaintenanceAlert {
  const MaintenanceAlert({
    required this.slot,
    required this.label,
    required this.status,
    required this.progressPct,
    required this.remainingLabel,
    this.sourceLabel,
  });

  final ComponentSlot slot;
  final String label;
  final DueStatus status;
  final int progressPct;
  final String remainingLabel;
  final String? sourceLabel;
}

/// Components due for service based on odometer / bike hours / install date.
List<MaintenanceAlert> listDueMaintenance({
  required Bike bike,
  required List<BikeComponent> components,
  DateTime? now,
}) {
  final installed = components.where((c) => c.isInstalled).toList();
  final slots = installed.map((c) => c.slot).toSet();
  final clock = now ?? DateTime.now();
  final alerts = <MaintenanceAlert>[];

  for (final t in defaultIntervalTemplates) {
    if (!slots.contains(t.slot)) continue;
    final comp = installed.firstWhere((c) => c.slot == t.slot);
    final due = _evaluate(
      template: t,
      bike: bike,
      component: comp,
      now: clock,
    );
    if (due.status == DueStatus.ok) continue;
    alerts.add(
      MaintenanceAlert(
        slot: t.slot,
        label: t.label,
        status: due.status,
        progressPct: due.progressPct,
        remainingLabel: due.remainingLabel,
        sourceLabel: t.sourceLabel,
      ),
    );
  }
  return alerts;
}

({DueStatus status, int progressPct, String remainingLabel}) _evaluate({
  required IntervalTemplate template,
  required Bike bike,
  required BikeComponent component,
  required DateTime now,
}) {
  final ratios = <double>[];
  final remainders = <String>[];

  if (template.intervalKm != null) {
    final used = (bike.odometerKm - component.odometerKm)
        .clamp(0, double.infinity);
    final ratio = used / template.intervalKm!;
    ratios.add(ratio);
    remainders.add(
      '${(template.intervalKm! - used).clamp(0, double.infinity).round()} km',
    );
  }
  if (template.intervalHours != null) {
    final used = (bike.hours - component.hoursAtInstallResolved)
        .clamp(0, double.infinity);
    final ratio = used / template.intervalHours!;
    ratios.add(ratio);
    remainders.add(
      '${(template.intervalHours! - used).clamp(0, double.infinity).round()} h',
    );
  }
  if (template.intervalDays != null && component.installedAt != null) {
    final usedDays =
        now.difference(component.installedAt!).inMilliseconds / 86400000;
    final ratio = usedDays / template.intervalDays!;
    ratios.add(ratio);
    remainders.add(
      '${(template.intervalDays! - usedDays).clamp(0, double.infinity).round()} Tage',
    );
  }

  if (ratios.isEmpty) {
    return (status: DueStatus.ok, progressPct: 0, remainingLabel: 'Kein Intervall');
  }

  final progressPct =
      (ratios.reduce((a, b) => a > b ? a : b) * 100).round().clamp(0, 100);
  final status = progressPct >= 100
      ? DueStatus.overdue
      : progressPct >= 80
          ? DueStatus.dueSoon
          : DueStatus.ok;

  return (
    status: status,
    progressPct: progressPct,
    remainingLabel: remainders.join(' · '),
  );
}
