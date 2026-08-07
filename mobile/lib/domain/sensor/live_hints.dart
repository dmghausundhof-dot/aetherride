/// F-SEN-005 Live-Hinweise (max. 6 Wörter), keine Ablese-Aufforderung.
library;

class LiveHint {
  const LiveHint({
    required this.id,
    required this.text,
    required this.kind,
  });

  final String id;
  final String text;
  final String kind; // safety | bracketing | stand
}

const _wordLimit = 6;

String clampHint(String text) {
  final words = text.trim().split(RegExp(r'\s+'));
  return words.take(_wordLimit).join(' ');
}

List<LiveHint> hintsFromMetrics({
  required double speedKmh,
  required double standSeconds,
  required bool impactJustDetected,
  int? bracketingRunJustCaptured,
  required int hardImpactStreak,
}) {
  final hints = <LiveHint>[];

  if (bracketingRunJustCaptured != null) {
    hints.add(
      LiveHint(
        id: 'bracket-run',
        text: clampHint('Durchgang $bracketingRunJustCaptured erfasst'),
        kind: 'bracketing',
      ),
    );
  }

  if (impactJustDetected && hardImpactStreak >= 3) {
    hints.add(
      LiveHint(
        id: 'impact-streak',
        text: clampHint('Harte Schlagfolge erkannt'),
        kind: 'safety',
      ),
    );
  }

  if (speedKmh < 3 && standSeconds > 10) {
    hints.add(
      const LiveHint(
        id: 'stand-setup',
        text: 'Stand: Setup prüfen möglich',
        kind: 'stand',
      ),
    );
  }

  return hints;
}
