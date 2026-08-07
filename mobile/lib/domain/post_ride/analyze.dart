/// Deterministische Post-Ride-Analyse — Spiegel src/lib/ai/postRideAnalysis.ts

import '../ride.dart';

class PostRideObservation {
  const PostRideObservation({required this.id, required this.text});
  final String id;
  final String text;
}

class SetupChangeSuggestion {
  const SetupChangeSuggestion({
    required this.title,
    required this.content,
    required this.reasoning,
    required this.expectedEffect,
    required this.limits,
    required this.confidence,
    this.adjusterKey,
    this.suggestedDelta,
  });

  final String title;
  final String content;
  final String reasoning;
  final String expectedEffect;
  final String limits;
  final String confidence; // low|medium|high
  final String? adjusterKey;
  final double? suggestedDelta;
}

class PostRideAnalysis {
  const PostRideAnalysis({
    required this.facts,
    required this.observations,
    this.setupSuggestion,
  });

  final List<String> facts;
  final List<PostRideObservation> observations;
  final SetupChangeSuggestion? setupSuggestion;
}

PostRideAnalysis analyzePostRide({
  required RideRecord ride,
  String? bikeName,
  RideFeedback? feedback,
  int? forkReboundClicks,
}) {
  final fb = feedback ?? ride.feedback;
  final m = ride.summary;
  final km = ride.distanceKm;
  final hours = ride.movingTimeSec / 3600.0;
  final flow = (m['avgFlow'] as num?)?.toDouble() ??
      (m['flowScore'] as num?)?.toDouble() ??
      0;
  final peakG = (m['peakG'] as num?)?.toDouble() ??
      (m['gForcePeak'] as num?)?.toDouble() ??
      0;
  final rms = (m['gForceRms'] as num?)?.toDouble() ?? 1.0;
  final impacts = (m['impactCount'] as num?)?.toInt() ??
      (peakG >= 3.5 ? (km * 2).round() : 0);
  final lean = (m['leanAngleMax'] as num?)?.toDouble() ?? 0;

  final facts = <String>[
    '${km.toStringAsFixed(1)} km · ${ride.elevationM.round()} hm · ${(hours * 60).toStringAsFixed(0)} min',
    'Flow ${flow.toStringAsFixed(0)} · Peak ${peakG.toStringAsFixed(1)} g · $impacts Impacts'
        '${lean > 0 ? ' · Lean ${lean.toStringAsFixed(0)}°' : ''}',
  ];
  if (bikeName != null) facts.add('Bike: $bikeName');
  final soc = m['soc'];
  if (soc != null) facts.add('SOC $soc%');

  final observations = <PostRideObservation>[];
  final impactsPerKm = km > 0.5 ? impacts / km : impacts.toDouble();

  if (impactsPerKm >= 4) {
    observations.add(
      PostRideObservation(
        id: 'impacts',
        text:
            'Viele harte Impacts ($impacts auf ${km.toStringAsFixed(1)} km) — Front/Dämpfer stark belastet.',
      ),
    );
  } else if (impacts <= 2 && km >= 10) {
    observations.add(
      PostRideObservation(
        id: 'smooth',
        text:
            'Wenige Impacts bei ${km.toStringAsFixed(1)} km — eher flowig oder glatter Untergrund.',
      ),
    );
  }

  if (flow >= 75) {
    observations.add(
      PostRideObservation(
        id: 'flow-high',
        text:
            'Hoher Flow-Score (${flow.toStringAsFixed(0)}) — Tempo und Linienwahl wirkten stimmig.',
      ),
    );
  } else if (flow > 0 && flow < 45) {
    observations.add(
      PostRideObservation(
        id: 'flow-low',
        text:
            'Niedriger Flow-Score (${flow.toStringAsFixed(0)}) — viele Tempo-Brüche oder Stopps.',
      ),
    );
  }

  if (peakG >= 4) {
    observations.add(
      PostRideObservation(
        id: 'peak-g',
        text:
            'Peak ${peakG.toStringAsFixed(1)} g — harte Einschläge; Setup und Reifendruck prüfen.',
      ),
    );
  }

  if (fb != null && !fb.skipped) {
    if (fb.frontFeel == 'too_firm' || fb.smallBump == 'harsh') {
      observations.add(
        PostRideObservation(
          id: 'fb-harsh',
          text:
              'Feedback: Front ${fb.frontFeel == 'too_firm' ? 'zu hart' : 'ok'} · kleine Schläge ${fb.smallBump == 'harsh' ? 'rau' : '—'}.',
        ),
      );
    } else if (fb.frontFeel == 'too_soft' || fb.brakeDive == 'dives') {
      observations.add(
        const PostRideObservation(
          id: 'fb-soft',
          text: 'Feedback: Front wirkt weich / taucht beim Anbremsen ab.',
        ),
      );
    }
  }

  final suggestion = _buildSetupSuggestion(
    feedback: fb,
    impactsPerKm: impactsPerKm,
    impacts: impacts,
    km: km,
    peakG: peakG,
    rms: rms,
    forkReboundClicks: forkReboundClicks,
  );

  return PostRideAnalysis(
    facts: facts,
    observations: observations.take(3).toList(),
    setupSuggestion: suggestion,
  );
}

SetupChangeSuggestion? _buildSetupSuggestion({
  required RideFeedback? feedback,
  required double impactsPerKm,
  required int impacts,
  required double km,
  required double peakG,
  required double rms,
  int? forkReboundClicks,
}) {
  final rebound = forkReboundClicks ?? 8;
  final harshFront = feedback?.frontFeel == 'too_firm' ||
      feedback?.smallBump == 'harsh' ||
      (impactsPerKm >= 3.5 && rms >= 1.2);
  final softFront =
      feedback?.frontFeel == 'too_soft' || feedback?.brakeDive == 'dives';

  if (harshFront && !softFront) {
    final next = (rebound - 2).clamp(0, 14);
    return SetupChangeSuggestion(
      title: 'Zugstufe Gabel: 2 Klicks langsamer',
      content: 'Aktuell ca. $rebound Klicks von geschlossen → Ziel $next.',
      reasoning: [
        if (feedback?.smallBump == 'harsh') 'Feedback „kleine Schläge rau“',
        if (feedback?.frontFeel == 'too_firm') 'Feedback „Front zu hart“',
        if (impactsPerKm >= 3.5)
          '$impacts Impacts / ${km.toStringAsFixed(1)} km',
        if (rms >= 1.2) 'RMS ${rms.toStringAsFixed(1)} g',
      ].whereType<String>().join(' · ').ifEmpty('Hohe Schlagbelastung an der Front'),
      expectedEffect: 'Ruhigere Front bei Schlagfolgen, etwas weniger Pop.',
      limits: 'Herstellerbereich typisch 0–14 Klicks von geschlossen.',
      confidence:
          feedback != null && !feedback.skipped ? 'high' : 'medium',
      adjusterKey: 'fork.rebound',
      suggestedDelta: -2,
    );
  }

  if (softFront) {
    final next = (rebound + 2).clamp(0, 14);
    return SetupChangeSuggestion(
      title: 'Zugstufe Gabel: 2 Klicks schneller',
      content: 'Aktuell ca. $rebound Klicks → Ziel $next (weniger Dive).',
      reasoning: [
        if (feedback?.brakeDive == 'dives') 'Feedback „taucht ab“',
        if (feedback?.frontFeel == 'too_soft') 'Feedback „Front zu weich“',
      ].whereType<String>().join(' · ').ifEmpty('Front zu weich / Dive'),
      expectedEffect: 'Stabileres Anbremsen, weniger Durchschlag-Gefühl.',
      limits: 'Herstellerbereich typisch 0–14 Klicks von geschlossen.',
      confidence:
          feedback != null && !feedback.skipped ? 'high' : 'medium',
      adjusterKey: 'fork.rebound',
      suggestedDelta: 2,
    );
  }

  if (peakG >= 5 && km >= 5) {
    return const SetupChangeSuggestion(
      title: 'Luftdruck Front prüfen',
      content:
          'Sehr hohe Peak-g — Druck und Volumen-Spacer gegen Hersteller-Tabelle halten.',
      reasoning: 'Peak ≥ 5 g bei längerer Fahrt',
      expectedEffect: 'Weniger Bottom-out-Risiko, klareres Feedback.',
      limits: 'Nur im freigegebenen Druckbereich des Reifens/Gabel.',
      confidence: 'low',
      adjusterKey: 'fork.pressure',
    );
  }

  return null;
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
