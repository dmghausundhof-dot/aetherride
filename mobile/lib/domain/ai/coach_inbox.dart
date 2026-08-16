// In-App-Postfach — Spiegel src/lib/ai/coachInbox.ts.

import 'coach_watch.dart';

const coachSnoozeDays = 7;

class CoachMeta {
  const CoachMeta({this.snoozedUntil, this.readFingerprint});

  final DateTime? snoozedUntil;
  final String? readFingerprint;

  Map<String, dynamic> toJson() => {
        if (snoozedUntil != null)
          'snoozedUntil': snoozedUntil!.toUtc().toIso8601String(),
        if (readFingerprint != null) 'readFingerprint': readFingerprint,
      };

  factory CoachMeta.fromJson(Map<String, dynamic> json) {
    DateTime? until;
    final raw = json['snoozedUntil'] as String?;
    if (raw != null) until = DateTime.tryParse(raw)?.toUtc();
    return CoachMeta(
      snoozedUntil: until,
      readFingerprint: json['readFingerprint'] as String?,
    );
  }

  CoachMeta copyWith({
    DateTime? snoozedUntil,
    String? readFingerprint,
  }) {
    return CoachMeta(
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      readFingerprint: readFingerprint ?? this.readFingerprint,
    );
  }
}

class CoachInboxItem {
  const CoachInboxItem({required this.notice, required this.unread});
  final CoachNotice notice;
  final bool unread;
}

bool isSnoozed(CoachMeta? meta, DateTime now) {
  final until = meta?.snoozedUntil;
  if (until == null) return false;
  return until.isAfter(now);
}

List<CoachInboxItem> mergeCoachInbox(
  List<CoachNotice> notices,
  Map<String, CoachMeta> meta, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now().toUtc();
  final items = <CoachInboxItem>[];
  for (final n in notices) {
    final prev = meta[n.id];
    if (isSnoozed(prev, clock)) continue;
    final unread =
        prev?.readFingerprint == null || prev!.readFingerprint != n.fingerprint;
    items.add(CoachInboxItem(notice: n, unread: unread));
  }
  return items;
}

Map<String, CoachMeta> snoozeMeta(
  Map<String, CoachMeta> meta,
  CoachNotice notice, {
  int days = coachSnoozeDays,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now().toUtc();
  final next = Map<String, CoachMeta>.from(meta);
  next[notice.id] = CoachMeta(
    snoozedUntil: clock.add(Duration(days: days)),
    readFingerprint: notice.fingerprint,
  );
  return next;
}

Map<String, CoachMeta> markReadMeta(
  Map<String, CoachMeta> meta,
  Iterable<CoachNotice> notices,
) {
  final next = Map<String, CoachMeta>.from(meta);
  for (final n in notices) {
    final prev = next[n.id];
    next[n.id] = CoachMeta(
      snoozedUntil: prev?.snoozedUntil,
      readFingerprint: n.fingerprint,
    );
  }
  return next;
}

int unreadCoachCount(List<CoachInboxItem> items) =>
    items.where((i) => i.unread).length;
