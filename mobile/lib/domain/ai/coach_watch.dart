// Deterministischer Assistenten-Monitor — Spiegel src/lib/ai/coachWatch.ts.

import '../bike.dart';
import '../compatibility/engine.dart';
import '../compatibility/rules.dart';
import '../component.dart';
import '../ebike/range.dart';
import '../maintenance/intervals.dart';
import '../post_ride/analyze.dart';
import '../ride.dart';
import '../setup.dart';

enum CoachKind { maintenance, wear, compat, setup, range, feedback }

enum CoachSeverity { info, dueSoon, overdue }

class CoachNotice {
  const CoachNotice({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.detail,
    required this.reasoning,
    required this.href,
    required this.tool,
    required this.query,
    required this.fingerprint,
    this.bikeId,
    this.numbers = const [],
  });

  final String id;
  final CoachKind kind;
  final CoachSeverity severity;
  final String title;
  final String detail;
  final String reasoning;
  final String href;
  final String? bikeId;
  final String tool;
  final String query;
  final String fingerprint;
  final List<Map<String, dynamic>> numbers;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'severity': switch (severity) {
          CoachSeverity.overdue => 'overdue',
          CoachSeverity.dueSoon => 'due_soon',
          CoachSeverity.info => 'info',
        },
        'title': title,
        'detail': detail,
        'reasoning': reasoning,
        'href': href,
        if (bikeId != null) 'bikeId': bikeId,
        'tool': tool,
        'query': query,
        'fingerprint': fingerprint,
        'numbers': numbers,
      };
}

class CoachWatchInput {
  const CoachWatchInput({
    required this.bikes,
    required this.componentsByBike,
    required this.rides,
    this.setupsByBike = const {},
    this.calibration,
    this.now,
  });

  final List<Bike> bikes;
  final Map<String, List<BikeComponent>> componentsByBike;
  final List<RideRecord> rides;
  final Map<String, List<BikeSetup>> setupsByBike;
  final RangeCalibration? calibration;
  final DateTime? now;
}

const _feedbackWindow = Duration(hours: 48);
const _maxNotices = 8;

int _rank(CoachSeverity s) => switch (s) {
      CoachSeverity.overdue => 0,
      CoachSeverity.dueSoon => 1,
      CoachSeverity.info => 2,
    };

List<CoachNotice> buildCoachWatch(CoachWatchInput input) {
  if (input.bikes.isEmpty) return [];
  final now = input.now ?? DateTime.now().toUtc();
  final notices = <CoachNotice>[];

  for (final bike in input.bikes) {
    final comps = input.componentsByBike[bike.id] ?? const <BikeComponent>[];
    final due = listDueMaintenance(bike: bike, components: comps, now: now);
    for (final a in due) {
      notices.add(
        CoachNotice(
          id: 'maint:${bike.id}:${a.slot.apiId}:${a.label}',
          kind: CoachKind.maintenance,
          severity: a.status == DueStatus.overdue
              ? CoachSeverity.overdue
              : CoachSeverity.dueSoon,
          title: a.label,
          detail: '${bike.name}: ${a.remainingLabel}',
          reasoning: a.sourceLabel ?? 'Intervall',
          href: '/garage',
          bikeId: bike.id,
          tool: 'garage',
          query: a.label,
          fingerprint: '${a.status.name}|${a.label}|${a.remainingLabel}',
        ),
      );
    }

    try {
      final results = checkBikeCompatibility(comps)
          .where((r) => r.verdict == CompatVerdict.incompatible)
          .take(2);
      for (final r in results) {
        final overdue = r.severity == RuleSeverity.safetyCritical;
        notices.add(
          CoachNotice(
            id: 'compat:${bike.id}:${r.ruleCode}',
            kind: CoachKind.compat,
            severity:
                overdue ? CoachSeverity.overdue : CoachSeverity.dueSoon,
            title: r.title,
            detail: r.explainDe,
            reasoning: '${r.ruleCode} · ${bike.name}',
            href: '/garage',
            bikeId: bike.id,
            tool: 'compat',
            query: 'Passt ${r.title}?',
            fingerprint: '${r.verdict.name}|${r.ruleCode}|${r.explainDe}',
          ),
        );
      }
    } catch (_) {}

    if (bike.hasElectricAssist) {
      final samples = input.calibration?.samples ?? 0;
      if (samples < 2) {
        notices.add(
          CoachNotice(
            id: 'range:${bike.id}:cal',
            kind: CoachKind.range,
            severity: CoachSeverity.info,
            title: 'Reichweite noch unsicher',
            detail:
                '${bike.name}: nach ein paar Fahrten mit SOC wird die Spanne enger.',
            reasoning: 'Kalibrierung $samples Sample(s).',
            href: '/chat',
            bikeId: bike.id,
            tool: 'range',
            query: 'Welche Reichweite habe ich mit aktuellem Akku?',
            fingerprint: 'range|$samples',
            numbers: [
              {'value': samples, 'unit': '', 'source': 'range.samples'},
            ],
          ),
        );
      }
    }
  }

  final sortedRides = [...input.rides]
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  if (sortedRides.isNotEmpty) {
    final last = sortedRides.first;
    final age = now.difference(last.endedAt ?? last.startedAt);
    if (!age.isNegative && age <= _feedbackWindow) {
      final fb = last.feedback;
      if (fb == null || fb.skipped) {
        notices.add(
          CoachNotice(
            id: 'feedback:${last.id}',
            kind: CoachKind.feedback,
            severity: CoachSeverity.info,
            title: 'Kurzes Feedback zur letzten Fahrt',
            detail:
                'Drei Taps — der Assistent nutzt das für Setup-Hinweise.',
            reasoning: 'Post-Ride-Fenster 48 h, noch kein Feedback.',
            href: '/post-ride',
            bikeId: last.bikeId,
            tool: 'setup_history',
            query:
                'Was hat sich am Setup nach der letzten Fahrt angeboten?',
            fingerprint: 'feedback|${last.id}',
            numbers: [
              {'value': 48, 'unit': 'h', 'source': 'feedback.window'},
            ],
          ),
        );
      }
      Bike? bike;
      for (final b in input.bikes) {
        if (b.id == last.bikeId) {
          bike = b;
          break;
        }
      }
      bike ??= input.bikes.isEmpty ? null : input.bikes.first;
      if (bike != null) {
        final setups = input.setupsByBike[bike.id] ?? const <BikeSetup>[];
        BikeSetup? current;
        for (final s in setups) {
          if (s.isCurrent) current = s;
        }
        final rebound = current?.valueFor('fork.rebound')?.round();
        final analysis = analyzePostRide(
          ride: last,
          bikeName: bike.name,
          feedback: fb,
          forkReboundClicks: rebound,
        );
        final sug = analysis.setupSuggestion;
        if (sug != null) {
          notices.add(
            CoachNotice(
              id: 'setup:${last.id}:${sug.adjusterKey ?? sug.title}',
              kind: CoachKind.setup,
              severity: sug.confidence == 'high'
                  ? CoachSeverity.dueSoon
                  : CoachSeverity.info,
              title: sug.title,
              detail: sug.content,
              reasoning: sug.reasoning,
              href: '/post-ride',
              bikeId: bike.id,
              tool: 'setup_history',
              query: sug.title,
              fingerprint: '${sug.title}|${sug.content}',
              numbers: [
                if (sug.suggestedDelta != null)
                  {
                    'value': sug.suggestedDelta,
                    'unit': 'klicks',
                    'source': 'setup.delta',
                  },
              ],
            ),
          );
        }
      }
    }
  }

  notices.sort((a, b) => _rank(a.severity).compareTo(_rank(b.severity)));
  final seen = <String>{};
  final unique = <CoachNotice>[];
  for (final n in notices) {
    if (!seen.add(n.id)) continue;
    unique.add(n);
    if (unique.length >= _maxNotices) break;
  }
  return unique;
}

String formulateCoachWatch(List<CoachNotice> notices) {
  if (notices.isEmpty) {
    return 'Gerade steht nichts an. Wartung, Verschleiß, Setup und '
        'Kompatibilität sind im grünen Bereich.';
  }
  final overdue =
      notices.where((n) => n.severity == CoachSeverity.overdue).length;
  final soon =
      notices.where((n) => n.severity == CoachSeverity.dueSoon).length;
  final lines = notices.take(5).map((n) {
    final tag = switch (n.severity) {
      CoachSeverity.overdue => 'überfällig',
      CoachSeverity.dueSoon => 'bald',
      CoachSeverity.info => 'Hinweis',
    };
    return '$tag: ${n.title} — ${n.detail}';
  });
  final head = overdue > 0
      ? '$overdue überfällig, $soon bald fällig.'
      : soon > 0
          ? '$soon bald fällig.'
          : '${notices.length} Hinweis${notices.length == 1 ? '' : 'e'}.';
  return '$head ${lines.join(' ')}';
}
