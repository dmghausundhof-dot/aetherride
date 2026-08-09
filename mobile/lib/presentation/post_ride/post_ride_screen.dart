import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/export/fit.dart';
import '../../data/export/gpx.dart';
import '../../data/export/strava_client.dart';
import '../../data/routing/heatmap_client.dart';
import '../../domain/ebike/assist_log.dart';
import '../../domain/post_ride/analyze.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/ride.dart';
import '../../providers/app_providers.dart';

class PostRideScreen extends ConsumerStatefulWidget {
  const PostRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  ConsumerState<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends ConsumerState<PostRideScreen> {
  RideRecord? _ride;
  String? _bikeName;
  int _feel = 3;
  String? _front;
  String? _brake;
  String? _bump;
  bool _saving = false;
  PostRideAnalysis? _analysis;
  bool _acceptedSuggestion = false;
  AssistRideSummary? _assist;
  double _replayProgress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ride = await ref.read(rideRepositoryProvider).getById(widget.rideId);
    final bike = ride == null
        ? null
        : await ref.read(garageRepositoryProvider).getById(ride.bikeId);
    if (!mounted) return;
    setState(() {
      _ride = ride;
      _bikeName = bike?.name;
      if (ride != null) {
        _analysis = analyzePostRide(ride: ride, bikeName: bike?.name);
        _assist = buildEstimatedAssistLog(
          durationSec: ride.movingTimeSec > 0 ? ride.movingTimeSec : 600,
          distanceM: ride.distanceKm * 1000,
          elevationGainM: ride.elevationM,
          avgSpeedKmh: ride.movingTimeSec > 0
              ? ride.distanceKm / (ride.movingTimeSec / 3600)
              : null,
        );
        final fb = ride.feedback;
        if (fb != null && !fb.skipped) {
          _feel = fb.overallFeel.clamp(1, 5);
          _front = fb.frontFeel;
          _brake = fb.brakeDive;
          _bump = fb.smallBump;
        }
      }
    });
    if (ride != null) {
      unawaited(_postRideSideEffects(ride));
    }
  }

  Future<void> _postRideSideEffects(RideRecord ride) async {
    try {
      final consents =
          await ref.read(garageRepositoryProvider).listConsents();
      if (consents[ConsentPurpose.heatmapContribution.apiId] != true) {
        return;
      }
      final zones =
          await ref.read(garageRepositoryProvider).listPrivacyZones();
      final r = await contributeHeatmapTrack(
        track: ride.track,
        privacyZones: zones,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Heatmap: $e')),
        );
      }
    }
  }

  Future<void> _uploadStrava() async {
    final ride = _ride;
    if (ride == null) return;
    try {
      final r = await uploadRideToStrava(ride);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Strava: $e')),
        );
      }
    }
  }

  void _reanalyze(RideFeedback feedback) {
    final ride = _ride;
    if (ride == null) return;
    setState(() {
      _analysis = analyzePostRide(
        ride: ride,
        bikeName: _bikeName,
        feedback: feedback,
      );
    });
  }

  Future<void> _acceptSuggestion() async {
    final ride = _ride;
    final suggestion = _analysis?.setupSuggestion;
    if (ride == null || suggestion == null || _acceptedSuggestion) return;
    setState(() => _saving = true);
    try {
      await ref.read(setupRepositoryProvider).applySuggestion(
            bikeId: ride.bikeId,
            suggestion: suggestion,
            linkedRideId: ride.id,
          );
      ref.invalidate(currentSetupProvider(ride.bikeId));
      if (!mounted) return;
      setState(() {
        _acceptedSuggestion = true;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setup-Version gespeichert')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Setup speichern fehlgeschlagen: $e')),
      );
    }
  }

  Future<void> _submit({bool skip = false}) async {
    setState(() => _saving = true);
    final feedback = RideFeedback(
      overallFeel: _feel,
      frontFeel: skip ? null : _front,
      brakeDive: skip ? null : _brake,
      smallBump: skip ? null : _bump,
      skipped: skip,
    );
    await ref
        .read(rideRepositoryProvider)
        .submitFeedback(widget.rideId, feedback);
    _reanalyze(feedback);
    if (!mounted) return;
    // Kurz Analyse zeigen, dann zurück
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _shareGpx() async {
    final ride = _ride;
    if (ride == null) return;
    if (!rideHasExportableTrack(ride)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kein GPS-Track — GPX wäre leer'),
        ),
      );
      return;
    }
    try {
      final gpx = rideToGpx(ride, bikeName: _bikeName);
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'aetherride-${ride.id.substring(0, math.min(8, ride.id.length))}.gpx',
      );
      await File(path).writeAsString(gpx);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: 'application/gpx+xml')]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GPX-Export: $e')),
      );
    }
  }

  Future<void> _shareFit() async {
    final ride = _ride;
    if (ride == null) return;
    try {
      final bytes = rideToFit(ride);
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'aetherride-${ride.id.substring(0, math.min(8, ride.id.length))}.fit',
      );
      await File(path).writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: 'application/octet-stream')]),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FIT-Export: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final analysis = _analysis;
    final track = ride?.track ?? const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post-Ride'),
        actions: [
          if (ride != null)
            IconButton(
              tooltip: 'GPX teilen',
              onPressed: _shareGpx,
              icon: const Icon(Icons.ios_share),
            ),
        ],
      ),
      body: ride == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  ride.name ?? 'Ride',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${ride.distanceKm < 1 ? ride.distanceKm.toStringAsFixed(2) : ride.distanceKm.toStringAsFixed(1)} km · '
                  '${ride.movingTimeSec < 60 ? '${ride.movingTimeSec} s' : '${(ride.movingTimeSec / 60).round()} min'} · '
                  '${ride.elevationM.round()} hm',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                Text(
                  'Track-Replay',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.muted.withValues(alpha: 0.35),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _TrackReplayPainter(
                          track: track,
                          progress: _replayProgress,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                if (track.length >= 2) ...[
                  Slider(
                    value: _replayProgress,
                    onChanged: (v) => setState(() => _replayProgress = v),
                  ),
                  Text(
                    'Position ${(100 * _replayProgress).round()} %',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Kein GPS-Track — Replay zeigt Platzhalter.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareGpx,
                        icon: const Icon(Icons.download),
                        label: const Text('GPX'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareFit,
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('FIT'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _uploadStrava,
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('Strava'),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Strava: mit GPS-Track via Uploads-API; ohne Track nur Metadaten '
                    '(braucht OAuth + STRAVA_* Keys).',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
                if (analysis != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Analyse',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  for (final f in analysis.facts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('· $f', style: const TextStyle(fontSize: 13)),
                    ),
                  for (final o in analysis.observations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        o.text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _MetricBars(
                    feel: _feel,
                    brake: _brake,
                    ride: ride,
                  ),
                  if (analysis.setupSuggestion != null) ...[
                    const SizedBox(height: 12),
                    Card(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    analysis.setupSuggestion!.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                _ConfidenceBadge(
                                  confidence:
                                      analysis.setupSuggestion!.confidence,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(analysis.setupSuggestion!.content),
                            const SizedBox(height: 4),
                            Text(
                              'Erwartung: ${analysis.setupSuggestion!.expectedEffect}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Grenze: ${analysis.setupSuggestion!.limits}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                            if (analysis
                                .setupSuggestion!.reasoning
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Evidenz',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              for (final line in _evidenceLines(
                                analysis.setupSuggestion!.reasoning,
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '· $line',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                              ),
                              onPressed: _acceptedSuggestion || _saving
                                  ? null
                                  : _acceptSuggestion,
                              child: Text(
                                _acceptedSuggestion
                                    ? 'Übernommen'
                                    : 'Empfehlung annehmen',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
                if (_assist != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Assist (Schätzung)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Dominant: ${_assist!.dominantMode.toUpperCase()} · '
                    '~${_assist!.estimatedTotalWh} Wh',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    [
                      for (final e in _assist!.modeSharePct.entries)
                        if (e.value > 0) '${e.key} ${e.value}%',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  for (final s in _assist!.segments.take(3))
                    Text(
                      '· ${s.label}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _assist!.disclaimer,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Wie hat es sich angefühlt?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      ChoiceChip(
                        label: Text('$i'),
                        selected: _feel == i,
                        onSelected: (_) => setState(() => _feel = i),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Federung vorne', style: _labelStyle),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in const [
                      ('too_soft', 'zu weich'),
                      ('ok', 'ok'),
                      ('too_firm', 'zu fest'),
                    ])
                      ChoiceChip(
                        label: Text(e.$2),
                        selected: _front == e.$1,
                        onSelected: (_) => setState(() => _front = e.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Bremsnick', style: _labelStyle),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in const [
                      ('dives', 'taucht'),
                      ('neutral', 'neutral'),
                      ('harsh', 'hart'),
                    ])
                      ChoiceChip(
                        label: Text(e.$2),
                        selected: _brake == e.$1,
                        onSelected: (_) => setState(() => _brake = e.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Kleine Schläge', style: _labelStyle),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in const [
                      ('harsh', 'hart'),
                      ('ok', 'ok'),
                      ('vague', 'schwammig'),
                    ])
                      ChoiceChip(
                        label: Text(e.$2),
                        selected: _bump == e.$1,
                        onSelected: (_) => setState(() => _bump = e.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: _saving ? null : () => _submit(),
                  child: const Text('Feedback speichern'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : () => _submit(skip: true),
                  child: const Text('Überspringen'),
                ),
              ],
            ),
    );
  }
}

List<String> _evidenceLines(String reasoning) {
  return reasoning
      .split(' · ')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

String _confidenceLabel(String confidence) {
  return switch (confidence) {
    'high' => 'hoch',
    'medium' => 'mittel',
    'low' => 'niedrig',
    _ => confidence,
  };
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final String confidence;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    switch (confidence) {
      case 'high':
        bg = AppColors.trail.withValues(alpha: 0.18);
        fg = AppColors.trail;
      case 'medium':
        bg = AppColors.accent.withValues(alpha: 0.18);
        fg = AppColors.accent;
      default:
        bg = AppColors.muted.withValues(alpha: 0.12);
        fg = AppColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Konfidenz ${_confidenceLabel(confidence)}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }
}

class _MetricBars extends StatelessWidget {
  const _MetricBars({
    required this.feel,
    required this.brake,
    required this.ride,
  });

  final int feel;
  final String? brake;
  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    final m = ride.summary;
    final km = ride.distanceKm;
    final impacts = (m['impactCount'] as num?)?.toInt() ?? 0;
    final shortRide = km < 0.5;
    final impactsPerKm = shortRide
        ? 0.0
        : (km > 0 ? impacts / km : 0.0);
    final impactPct = shortRide ? 0.0 : (impactsPerKm / 6).clamp(0.0, 1.0);

    final rows = <({String label, String value, double pct, bool accent})>[
      (
        label: 'Feel',
        value: '$feel / 5',
        pct: (feel / 5).clamp(0.0, 1.0),
        accent: true,
      ),
    ];

    if (brake != null) {
      final brakePct = switch (brake) {
        'dives' => 0.35,
        'neutral' => 0.65,
        'harsh' => 0.9,
        _ => 0.5,
      };
      final brakeLabel = switch (brake) {
        'dives' => 'taucht',
        'neutral' => 'neutral',
        'harsh' => 'hart',
        _ => brake!,
      };
      rows.add((
        label: 'Brake',
        value: brakeLabel,
        pct: brakePct,
        accent: false,
      ));
    }

    rows.add((
      label: 'Impact',
      value: shortRide ? 'n/a' : impactsPerKm.toStringAsFixed(1),
      pct: impactPct,
      accent: false,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shortRide)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Kurzride — Metriken eingeschränkt (< 0,5 km).',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        Text(
          'Metriken',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        for (final r in rows) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  r.label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              Text(
                r.value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: r.pct,
              minHeight: 6,
              backgroundColor: AppColors.forest.withValues(alpha: 0.08),
              color: r.accent ? AppColors.accent : AppColors.trail,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

const _labelStyle = TextStyle(
  fontWeight: FontWeight.w600,
  fontSize: 13,
);

class _TrackReplayPainter extends CustomPainter {
  _TrackReplayPainter({required this.track, required this.progress});

  final List<Map<String, dynamic>> track;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[];
    for (final p in track) {
      final lat = (p['lat'] as num?)?.toDouble();
      final lng = (p['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      pts.add(Offset(lng, lat));
    }
    if (pts.length < 2) {
      final paint = Paint()
        ..color = AppColors.muted.withValues(alpha: 0.35)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(24, 40, size.width - 48, size.height - 80),
          const Radius.circular(40),
        ),
        paint,
      );
      return;
    }

    double minX = pts.first.dx, maxX = pts.first.dx;
    double minY = pts.first.dy, maxY = pts.first.dy;
    for (final o in pts) {
      minX = math.min(minX, o.dx);
      maxX = math.max(maxX, o.dx);
      minY = math.min(minY, o.dy);
      maxY = math.max(maxY, o.dy);
    }
    final dx = (maxX - minX).abs() < 1e-9 ? 1e-5 : maxX - minX;
    final dy = (maxY - minY).abs() < 1e-9 ? 1e-5 : maxY - minY;
    final pad = 16.0;
    Offset map(Offset o) {
      final x = pad + (o.dx - minX) / dx * (size.width - 2 * pad);
      final y = size.height - pad - (o.dy - minY) / dy * (size.height - 2 * pad);
      return Offset(x, y);
    }

    final path = Path()..moveTo(map(pts.first).dx, map(pts.first).dy);
    for (var i = 1; i < pts.length; i++) {
      final m = map(pts[i]);
      path.lineTo(m.dx, m.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.trail.withValues(alpha: 0.85)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final idx =
        ((pts.length - 1) * progress.clamp(0.0, 1.0)).round().clamp(0, pts.length - 1);
    final cursor = map(pts[idx]);
    canvas.drawCircle(cursor, 6, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(covariant _TrackReplayPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.track != track;
}

