import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/community/ride_group_policy.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/hof_threshold_nav.dart';

class RideGroupExtendChoice {
  const RideGroupExtendChoice.hours(this.addHours) : newEnd = null;
  const RideGroupExtendChoice.end(this.newEnd) : addHours = null;

  final double? addHours;
  final DateTime? newEnd;
}

String formatRideGroupLocalWhen(DateTime t) {
  final l = t.toLocal();
  final dd = l.day.toString().padLeft(2, '0');
  final mm = l.month.toString().padLeft(2, '0');
  final hh = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$dd.$mm. $hh:$min';
}

String formatRideGroupWhenLine({
  required DateTime start,
  required DateTime end,
  required AppLocalizations l10n,
  DateTime? now,
}) {
  final decimal = l10n.localeName.startsWith('en') ? '.' : ',';
  return RideGroupPolicy.formatWhenLabeled(
    start: start,
    end: end,
    now: now,
    weekdayShort: (local) =>
        RideGroupPolicy.weekdayShortForLocale(local, l10n.localeName),
    today: l10n.rideGroupWhenToday,
    tomorrow: l10n.rideGroupWhenTomorrow,
    other: l10n.rideGroupWhenWeekday,
    closed: l10n.rideGroupWhenClosed,
    decimalSep: decimal,
  );
}

Future<DateTime?> pickRideGroupDateTime(
  BuildContext context, {
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) async {
  final now = DateTime.now();
  final firstDate = first ?? DateTime(now.year, now.month, now.day);
  final lastDate = last ?? now.add(const Duration(days: 14));
  var seed = initial;
  if (seed.isBefore(firstDate)) seed = firstDate;
  if (seed.isAfter(lastDate)) seed = lastDate;
  final date = await showDatePicker(
    context: context,
    initialDate: seed,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Future<RideGroupExtendChoice?> showRideGroupExtendSheet(
  BuildContext context, {
  String? currentWhen,
}) {
  final extraCtrl = TextEditingController();
  return showModalBottomSheet<RideGroupExtendChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final loc = AppLocalizations.of(ctx);
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: HofThresholdNav.sheetBottomInset(ctx) +
                MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.rideGroupExtend,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (currentWhen != null && currentWhen.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                currentWhen,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              loc.rideGroupExtendCapHint,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  key: const Key('ride-group-extend-30m'),
                  label: Text(loc.rideGroupExtend30m),
                  onPressed: () => Navigator.pop(
                    ctx,
                    const RideGroupExtendChoice.hours(0.5),
                  ),
                ),
                ActionChip(
                  key: const Key('ride-group-extend-1h'),
                  label: Text(loc.rideGroupExtend1h),
                  onPressed: () => Navigator.pop(
                    ctx,
                    const RideGroupExtendChoice.hours(1),
                  ),
                ),
                ActionChip(
                  key: const Key('ride-group-extend-2h'),
                  label: Text(loc.rideGroupExtend2h),
                  onPressed: () => Navigator.pop(
                    ctx,
                    const RideGroupExtendChoice.hours(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('ride-group-extend-hours'),
              controller: extraCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: loc.platzDurationHoursHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                final hours = RideGroupPolicy.parseDurationHours(extraCtrl.text);
                if (hours == null ||
                    !RideGroupPolicy.isValidDurationHours(hours)) {
                  return;
                }
                Navigator.pop(ctx, RideGroupExtendChoice.hours(hours));
              },
              child: Text(loc.rideGroupExtend),
            ),
            TextButton(
              key: const Key('ride-group-extend-custom-end'),
              onPressed: () async {
                final picked = await pickRideGroupDateTime(
                  ctx,
                  initial: DateTime.now().add(const Duration(hours: 1)),
                  last: DateTime.now().add(const Duration(hours: 12)),
                );
                if (picked != null && ctx.mounted) {
                  Navigator.pop(ctx, RideGroupExtendChoice.end(picked));
                }
              },
              child: Text(loc.rideGroupExtendCustomEnd),
            ),
          ],
          ),
        ),
      );
    },
  ).whenComplete(extraCtrl.dispose);
}
