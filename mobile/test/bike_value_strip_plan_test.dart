import 'package:aetherride_mobile/domain/garage/bike_value_strip_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('0 km und 0 h sind Gedankenstrich', () {
    expect(formatStripCount(0, '—'), '—');
    expect(formatStripCount(0, '—', decimals: 1), '—');
    expect(formatStripCount(1240, '—'), '1240');
    expect(formatStripCount(42.5, '—', decimals: 1), '42.5');
  });

  test('Termin-Datum schlägt fälliges Intervall', () {
    final plan = planStripService(
      appointmentLabel: '12.09.2026',
      intervalStatus: StripIntervalStatus.overdue,
      intervalRemaining: 'Kette',
      appointmentCaption: 'Termin',
      careCaption: 'Pflege',
      dueNow: 'Jetzt',
      dash: '—',
    );
    expect(plan.kind, StripServiceKind.appointment);
    expect(plan.caption, 'Termin');
    expect(plan.value, '12.09.2026');
  });

  test('ohne Termin trägt die Zelle Pflege, nicht denselben Namen', () {
    final overdue = planStripService(
      intervalStatus: StripIntervalStatus.overdue,
      appointmentCaption: 'Termin',
      careCaption: 'Pflege',
      dueNow: 'Jetzt',
      dash: '—',
    );
    expect(overdue.caption, 'Pflege');
    expect(overdue.value, 'Jetzt');

    final soon = planStripService(
      intervalStatus: StripIntervalStatus.dueSoon,
      intervalRemaining: '180 km · 12 Tage',
      appointmentCaption: 'Termin',
      careCaption: 'Pflege',
      dueNow: 'Jetzt',
      dash: '—',
    );
    expect(soon.caption, 'Pflege');
    expect(soon.value, '180 km');
  });
}
