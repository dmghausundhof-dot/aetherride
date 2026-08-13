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
import '../../data/routing/ride_to_saved.dart';
import '../../data/weather/weather_client.dart';
import '../../domain/ebike/assist_log.dart';
import '../../domain/post_ride/analyze.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/ride.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import 'post_ride_photos.dart';
import 'post_ride_track_map.dart';

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
  bool _stravaConfigured = false;
  bool _stravaConnected = false;
  String? _stravaHint;

  WeatherSnapshot? _weatherStart;
  WeatherSnapshot? _weatherEnd;
  bool _weatherLoading = false;
  List<String> _photoPaths = [];
  bool _savingAsTour = false;
  bool _savedAsTour = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await fetchStravaStatus();
      if (mounted) {
        setState(() {
          _stravaConfigured = s.configured;
          _stravaConnected = s.connected;
          _stravaHint = s.configured
              ? (s.connected
                  ? null
                  : 'Strava verbinden unter Daten & Privatsphäre.')
              : 'Strava-Keys fehlen — GPX/FIT nutzen.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stravaConfigured = false;
          _stravaConnected = false;
          _stravaHint = 'Strava-Status nicht erreichbar — GPX/FIT nutzen.';
        });
      }
    }
    final ride = await ref.read(rideRepositoryProvider).getById(widget.rideId);
    final bike = ride == null
        ? null
        : await ref.read(garageRepositoryProvider).getById(ride.bikeId);
    if (!mounted) return;
    setState(() {
      _ride = ride;
      _bikeName = bike?.name;
      _photoPaths = _photosFromSummary(ride?.summary);
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
      unawaited(_loadWeather(ride));
    }
  }

  List<String> _photosFromSummary(Map<String, dynamic>? summary) {
    final raw = summary?['photoPaths'];
    if (raw is! List) return [];
    return [
      for (final e in raw)
        if (e is String && e.isNotEmpty) e,
    ];
  }

  Future<void> _loadWeather(RideRecord ride) async {
    final cachedStart = _weatherFromSummary(ride.summary, 'weatherStart');
    final cachedEnd = _weatherFromSummary(ride.summary, 'weatherEnd');
    if (cachedStart != null || cachedEnd != null) {
      if (!mounted) return;
      setState(() {
        _weatherStart = cachedStart;
        _weatherEnd = cachedEnd ?? cachedStart;
        _weatherLoading = false;
      });
      return;
    }

    final pts = _latLngFromTrack(ride.track);
    if (pts.isEmpty) return;

    setState(() => _weatherLoading = true);
    final client = ref.read(weatherClientProvider);
    try {
      final start = await client.fetch(lat: pts.first.$1, lon: pts.first.$2);
      WeatherSnapshot? end;
      if (pts.length > 1) {
        final last = pts.last;
        final first = pts.first;
        final moved = (last.$1 - first.$1).abs() > 0.02 ||
            (last.$2 - first.$2).abs() > 0.02;
        end = moved
            ? await client.fetch(lat: last.$1, lon: last.$2)
            : start;
      } else {
        end = start;
      }
      if (!mounted) return;
      setState(() {
        _weatherStart = start;
        _weatherEnd = end;
        _weatherLoading = false;
      });
      if (start != null) {
        unawaited(
          ref.read(rideRepositoryProvider).mergeSummary(widget.rideId, {
            'weatherStart': _weatherToJson(start),
            if (end != null) 'weatherEnd': _weatherToJson(end),
          }),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  WeatherSnapshot? _weatherFromSummary(
    Map<String, dynamic> summary,
    String key,
  ) {
    final raw = summary[key];
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final temp = (m['tempC'] as num?)?.toDouble();
    if (temp == null) return null;
    return WeatherSnapshot(
      tempC: temp,
      precipMm: (m['precipMm'] as num?)?.toDouble() ?? 0,
      trailHint: (m['trailHint'] as String?) ?? 'dry_likely',
      summary: (m['summary'] as String?) ?? 'Open-Meteo',
    );
  }

  Map<String, dynamic> _weatherToJson(WeatherSnapshot w) => {
        'tempC': w.tempC,
        'precipMm': w.precipMm,
        'trailHint': w.trailHint,
        'summary': w.summary,
      };

  List<(double, double)> _latLngFromTrack(List<Map<String, dynamic>> track) {
    final out = <(double, double)>[];
    for (final p in track) {
      final lat = (p['lat'] as num?)?.toDouble();
      final lng = (p['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      out.add((lat, lng));
    }
    return out;
  }

  Future<void> _onPhotosChanged(List<String> paths) async {
    setState(() => _photoPaths = paths);
    final ride = _ride;
    if (ride == null) return;
    await ref.read(rideRepositoryProvider).mergeSummary(widget.rideId, {
      'photoPaths': paths,
    });
    final updated = await ref.read(rideRepositoryProvider).getById(widget.rideId);
    if (mounted && updated != null) {
      setState(() => _ride = updated);
    }
  }

  Future<void> _saveAsTour() async {
    final l10n = AppLocalizations.of(context);
    final ride = _ride;
    if (ride == null) return;
    if (ride.track.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRideSaveAsTourNeedTrack)),
      );
      return;
    }
    if (_savingAsTour || _savedAsTour) return;
    setState(() => _savingAsTour = true);
    try {
      await saveRideAsTour(
        routes: ref.read(routeRepositoryProvider),
        ride: ride,
        photoPaths: _photoPaths,
      );
      ref.invalidate(savedRoutesProvider);
      if (!mounted) return;
      setState(() {
        _savingAsTour = false;
        _savedAsTour = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.postRideSaveAsTourDone)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingAsTour = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
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

  String _fmtDistance(double km) =>
      km < 1 ? '${km.toStringAsFixed(2)} km' : '${km.toStringAsFixed(1)} km';

  String _fmtDuration(int sec) {
    if (sec < 60) return '$sec s';
    final m = sec ~/ 60;
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    return '${h}h ${rem.toString().padLeft(2, '0')}m';
  }

  String? _fmtPaceKmh(RideRecord ride) {
    if (ride.movingTimeSec <= 0 || ride.distanceKm <= 0) return null;
    final kmh = ride.distanceKm / (ride.movingTimeSec / 3600);
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ride = _ride;
    final analysis = _analysis;
    final track = ride?.track ?? const <Map<String, dynamic>>[];
    final isFreeride = ride != null &&
        (ride.routeId == null || ride.routeId!.isEmpty);
    final pace = ride == null ? null : _fmtPaceKmh(ride);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.postRideTitle),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ride.name ??
                            (isFreeride ? l10n.postRideFreeride : 'Fahrt'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (isFreeride)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          l10n.postRideFreeride,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                _StatsRow(
                  distance: _fmtDistance(ride.distanceKm),
                  duration: _fmtDuration(ride.movingTimeSec),
                  pace: pace,
                  elevation: '${ride.elevationM.round()} hm',
                  distanceLabel: l10n.postRideStatDistance,
                  durationLabel: l10n.postRideStatDuration,
                  paceLabel: l10n.postRideStatPace,
                  elevationLabel: l10n.postRideStatElevation,
                ),
                if (ride.summary['gpsStallSim'] == true) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      'Sim-Track war aktiv'
                      '${ride.summary['simDistanceM'] is num ? ' (~${((ride.summary['simDistanceM'] as num) / 1000).toStringAsFixed(1)} km simuliert)' : ''}'
                      ' — Distanz/Analyse ggf. unzuverlässig. Für echte Rides AETHER_SIM_MOTION aus.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
                if (() {
                  final hours = ride.movingTimeSec / 3600;
                  if (hours < 1 / 60) return false;
                  final avg = ride.distanceKm / hours;
                  return avg > 45;
                }()) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ungewöhnlich hohe Durchschnittsgeschwindigkeit — GPS/Sim prüfen.',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ],
                const SizedBox(height: AppSpacing.l),
                Text(
                  l10n.postRideTrackMap,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                if (track.length >= 2)
                  PostRideTrackMap(track: track)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.postRideNoTrack,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                const SizedBox(height: AppSpacing.l),
                _WeatherCard(
                  loading: _weatherLoading,
                  start: _weatherStart,
                  end: _weatherEnd,
                  title: l10n.postRideWeatherTitle,
                  startLabel: l10n.postRideWeatherStart,
                  endLabel: l10n.postRideWeatherEnd,
                  unavailable: l10n.postRideWeatherUnavailable,
                ),
                const SizedBox(height: AppSpacing.l),
                PostRidePhotosSection(
                  photoPaths: _photoPaths,
                  onChanged: (paths) => unawaited(_onPhotosChanged(paths)),
                ),
                const SizedBox(height: AppSpacing.l),
                FilledButton.icon(
                  onPressed: (_savingAsTour || _savedAsTour)
                      ? null
                      : () => unawaited(_saveAsTour()),
                  icon: _savingAsTour
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _savedAsTour ? Icons.check : Icons.bookmark_add_outlined,
                        ),
                  label: Text(
                    _savedAsTour
                        ? l10n.postRideSaveAsTourDone
                        : l10n.postRideSaveAsTour,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.postRideSaveAsTourHint,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
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
                        onPressed: (_stravaConfigured && _stravaConnected)
                            ? _uploadStrava
                            : null,
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('Strava'),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _stravaHint ??
                        'Strava: mit GPS-Track via Uploads-API; ohne Track nur Metadaten.',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
                                backgroundColor: AppColors.forestOnDark,
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
                      FilledButton.styleFrom(),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.distance,
    required this.duration,
    required this.pace,
    required this.elevation,
    required this.distanceLabel,
    required this.durationLabel,
    required this.paceLabel,
    required this.elevationLabel,
  });

  final String distance;
  final String duration;
  final String? pace;
  final String elevation;
  final String distanceLabel;
  final String durationLabel;
  final String paceLabel;
  final String elevationLabel;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[
      (label: distanceLabel, value: distance),
      (label: durationLabel, value: duration),
      if (pace != null) (label: paceLabel, value: pace!),
      (label: elevationLabel, value: elevation),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(
                  color: AppColors.muted.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    items[i].value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    items[i].label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.loading,
    required this.start,
    required this.end,
    required this.title,
    required this.startLabel,
    required this.endLabel,
    required this.unavailable,
  });

  final bool loading;
  final WeatherSnapshot? start;
  final WeatherSnapshot? end;
  final String title;
  final String startLabel;
  final String endLabel;
  final String unavailable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.s),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(minHeight: 3),
          )
        else if (start == null && end == null)
          Text(
            unavailable,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          )
        else ...[
          Builder(
            builder: (context) {
              final showEnd = end != null &&
                  start != null &&
                  (end!.tempC != start!.tempC ||
                      end!.summary != start!.summary ||
                      end!.trailHint != start!.trailHint);
              return Row(
                children: [
                  if (start != null)
                    Expanded(
                      child: _WeatherTile(label: startLabel, w: start!),
                    ),
                  if (showEnd) ...[
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: _WeatherTile(label: endLabel, w: end!),
                    ),
                  ] else if (end != null && start == null)
                    Expanded(
                      child: _WeatherTile(label: endLabel, w: end!),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _WeatherTile extends StatelessWidget {
  const _WeatherTile({required this.label, required this.w});

  final String label;
  final WeatherSnapshot w;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${w.tempC.toStringAsFixed(0)}° · ${w.summary}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${w.trailLabel} · ${w.precipMm.toStringAsFixed(1)} mm',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
