// Shared strip helpers — keep in sync with src/lib/garage/bikeValueStrip.ts

enum StripServiceKind { appointment, care, empty }

enum StripIntervalStatus { overdue, dueSoon }

class StripServicePlan {
  const StripServicePlan({
    required this.kind,
    required this.caption,
    required this.value,
  });

  final StripServiceKind kind;
  final String caption;
  final String value;
}

String formatStripCount(double value, String dash, {int decimals = 0}) {
  if (value.isNaN || value <= 0) return dash;
  return decimals == 0
      ? value.round().toString()
      : value.toStringAsFixed(decimals);
}

StripServicePlan planStripService({
  String? appointmentLabel,
  StripIntervalStatus? intervalStatus,
  String? intervalRemaining,
  required String appointmentCaption,
  required String careCaption,
  required String dueNow,
  required String dash,
}) {
  final appt = appointmentLabel?.trim();
  if (appt != null && appt.isNotEmpty) {
    return StripServicePlan(
      kind: StripServiceKind.appointment,
      caption: appointmentCaption,
      value: appt,
    );
  }
  if (intervalStatus == StripIntervalStatus.overdue) {
    return StripServicePlan(
      kind: StripServiceKind.care,
      caption: careCaption,
      value: dueNow,
    );
  }
  final rem = intervalRemaining?.trim();
  if (intervalStatus == StripIntervalStatus.dueSoon &&
      rem != null &&
      rem.isNotEmpty) {
    final cut = rem.indexOf(' · ');
    return StripServicePlan(
      kind: StripServiceKind.care,
      caption: careCaption,
      value: cut < 0 ? rem : rem.substring(0, cut),
    );
  }
  return StripServicePlan(
    kind: StripServiceKind.empty,
    caption: appointmentCaption,
    value: dash,
  );
}
