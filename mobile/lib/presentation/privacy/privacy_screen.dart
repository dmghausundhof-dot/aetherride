import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/export/export_trimmed.dart';
import '../../data/export/json_export.dart';
import '../../data/export/strava_client.dart';
import '../../data/export/strava_stub.dart';
import '../../data/routing/heatmap_client.dart';
import '../../domain/privacy/consents.dart';
import '../../providers/app_providers.dart';

/// Daten & Privatsphäre — Consents, Zonen, Export (F-ACC-003/005/006).
class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen>
    with WidgetsBindingObserver {
  Map<String, bool> _consents = {};
  List<PrivacyZone> _zones = [];
  bool _busy = false;
  String? _message;
  int _pendingChunks = 0;
  String? _stravaStatus;
  bool _stravaConfigured = false;
  bool _stravaConnected = false;
  String? _stravaAuthorizeUrl;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkStrava();
    _listenStravaDeepLinks();
  }

  void _listenStravaDeepLinks() {
    final links = AppLinks();
    _linkSub = links.uriLinkStream.listen((uri) {
      if (uri.host == 'strava-callback' ||
          uri.toString().contains('strava-callback')) {
        unawaited(_checkStrava());
        if (mounted) {
          final q = uri.queryParameters['strava'];
          setState(() {
            _message = q == 'connected'
                ? 'Strava verbunden'
                : (q != null ? 'Strava: $q' : 'Strava-Callback empfangen');
          });
        }
      }
    });
    unawaited(() async {
      final initial = await links.getInitialLink();
      if (initial != null &&
          (initial.host == 'strava-callback' ||
              initial.toString().contains('strava-callback'))) {
        await _checkStrava();
      }
    }());
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkStrava());
    }
  }

  Future<void> _checkStrava() async {
    try {
      final s = await fetchStravaStatus();
      if (!mounted) return;
      setState(() {
        _stravaConfigured = s.configured;
        _stravaConnected = s.connected;
        _stravaAuthorizeUrl = s.authorizeUrl;
        _stravaStatus = s.message;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _stravaStatus =
            'Strava-Status nicht erreichbar — Stub-Export bleibt lokal');
      }
    }
  }

  Future<void> _connectStrava() async {
    final url = _stravaAuthorizeUrl;
    if (url == null) {
      setState(() => _message =
          'Strava-Authorize-URL fehlt — einloggen und erneut versuchen.');
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      setState(() => _message = 'Browser konnte nicht geöffnet werden');
    } else if (mounted) {
      setState(() => _message =
          'Strava im Browser — nach Freigabe zurück zur App, Status aktualisiert sich.');
    }
  }

  Future<void> _uploadStravaLive() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = 'Kein Ride zum Upload');
        return;
      }
      final r = await uploadRideToStrava(rides.first);
      if (mounted) setState(() => _message = r.message);
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    final garage = ref.read(garageRepositoryProvider);
    final consents = await garage.listConsents();
    final zones = await garage.listPrivacyZones();
    final merged = defaultConsentGrants();
    merged.addAll(consents);
    final pending =
        await ref.read(rideChunkRepositoryProvider).pendingCount();
    if (mounted) {
      setState(() {
        _consents = merged;
        _zones = zones;
        _pendingChunks = pending;
      });
    }
  }

  Future<void> _uploadChunks() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final n = await ref.read(rideChunkRepositoryProvider).uploadPending();
      final left = await ref.read(rideChunkRepositoryProvider).pendingCount();
      if (mounted) {
        setState(() {
          _pendingChunks = left;
          _message = n > 0
              ? '$n Chunk(s) hochgeladen, $left ausstehend'
              : left > 0
                  ? 'Kein Upload (Login/Netz?) — $left ausstehend'
                  : 'Keine ausstehenden Chunks';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setConsent(ConsentPurpose purpose, bool granted) async {
    setState(() => _consents[purpose.apiId] = granted);
    await ref.read(garageRepositoryProvider).setConsent(
          purpose: purpose.apiId,
          granted: granted,
        );
    if (purpose == ConsentPurpose.heatmapContribution && granted) {
      unawaited(_contributeHeatmapBestEffort());
    }
  }

  Future<void> _contributeHeatmapBestEffort() async {
    try {
      final rides =
          await ref.read(rideRepositoryProvider).listRides(limit: 20);
      final zones =
          await ref.read(garageRepositoryProvider).listPrivacyZones();
      var n = 0;
      for (final r in rides) {
        final res = await contributeHeatmapTrack(
          track: r.track,
          privacyZones: zones,
        );
        n += res.upserted;
      }
      if (mounted && n > 0) {
        setState(() => _message =
            'Heatmap: $n Zellen beigetragen (sichtbar erst ab k≥5).');
      } else if (mounted && rides.isNotEmpty) {
        setState(() => _message =
            'Heatmap: kein Beitrag (Login/Consent/Track prüfen).');
      }
    } catch (_) {}
  }

  Future<void> _addZone() async {
    Position? lastPos;
    try {
      lastPos = await Geolocator.getLastKnownPosition();
    } catch (_) {}
    if (!mounted) return;
    final usedLastKnown = lastPos != null;
    final label = TextEditingController(text: 'Zuhause');
    final lat = TextEditingController(
      text: lastPos != null ? lastPos.latitude.toStringAsFixed(5) : '',
    );
    final lng = TextEditingController(
      text: lastPos != null ? lastPos.longitude.toStringAsFixed(5) : '',
    );
    final radius = TextEditingController(text: '200');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy-Zone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: label,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: lat,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Lat'),
              ),
              TextField(
                controller: lng,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(labelText: 'Lng'),
              ),
              TextField(
                controller: radius,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Radius (m)'),
              ),
              if (usedLastKnown) ...[
                const SizedBox(height: 8),
                const Text(
                  'Lat/Lng vorausgefüllt mit der zuletzt bekannten Position '
                  '(Geolocator). Bitte prüfen und ggf. anpassen.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'Keine zuletzt bekannte Position — Lat/Lng manuell eintragen.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final parsedLat = double.tryParse(lat.text.replaceAll(',', '.'));
    final parsedLng = double.tryParse(lng.text.replaceAll(',', '.'));
    if (parsedLat == null || parsedLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte gültige Lat/Lng angeben')),
        );
      }
      return;
    }
    final zone = PrivacyZone(
      id: const Uuid().v4(),
      label: label.text.trim().isEmpty ? 'Zone' : label.text.trim(),
      lat: parsedLat,
      lng: parsedLng,
      radiusM: double.tryParse(radius.text.replaceAll(',', '.')) ?? 200,
    );
    await ref.read(garageRepositoryProvider).upsertPrivacyZone(zone);
    await _load();
  }

  Future<void> _sharePath(String path, {String? mime}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mime)],
        subject: 'AetherRide Export',
      ),
    );
  }

  Future<String> _writeExport(String filename, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsString(content);
    return file.path;
  }

  Future<String> _writeBytes(String filename, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, filename));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _exportGpx() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = 'Kein Ride zum Exportieren.');
        return;
      }
      final bike = await ref.read(garageRepositoryProvider).getActiveBike();
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final gpx = exportGpxTrimmed(
        rides.first,
        zones: zones,
        bikeName: bike?.name,
      );
      final path = await _writeExport(
        'aetherride-${rides.first.id.substring(0, 8)}.gpx',
        gpx,
      );
      await _sharePath(path, mime: 'application/gpx+xml');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPX geteilt · $path')),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportFit() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = 'Kein Ride zum Exportieren.');
        return;
      }
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final bytes = exportFitTrimmed(rides.first, zones: zones);
      final path = await _writeBytes(
        'aetherride-${rides.first.id.substring(0, 8)}.fit',
        bytes,
      );
      await _sharePath(path, mime: 'application/octet-stream');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('FIT geteilt · $path')),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportStravaStub() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = 'Kein Ride zum Exportieren.');
        return;
      }
      final json = rideToStravaActivityJson(rides.first);
      final path = await _writeExport(
        'aetherride-strava-${rides.first.id.substring(0, 8)}.json',
        json,
      );
      await _sharePath(path, mime: 'application/json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Strava-Stub geteilt · $path')),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bikes = await ref.read(garageRepositoryProvider).listBikes();
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 50);
      final consents = await ref.read(garageRepositoryProvider).listConsents();
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final trimmedRides = [
        for (final r in rides) rideWithTrimmedTrack(r, zones),
      ];
      final json = fullJsonExport(
        bikes: bikes,
        rides: trimmedRides,
        consents: consents,
      );
      final path = await _writeExport('aetherride-export.json', json);
      await _sharePath(path, mime: 'application/json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('JSON geteilt · $path')),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daten & Privatsphäre')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Einwilligungen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          for (final purpose in ConsentPurpose.values)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(consentLabels[purpose]!.title),
              subtitle: Text(
                consentLabels[purpose]!.description,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              value: _consents[purpose.apiId] ?? false,
              onChanged: _busy
                  ? null
                  : (v) => _setConsent(purpose, v),
            ),
          const SizedBox(height: 8),
          Text(
            'Rohdaten-Chunks: $_pendingChunks ausstehend'
            '${_consents['raw_data_upload'] == true ? '' : ' (Consent aus)'}',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (_pendingChunks > 0)
            TextButton(
              onPressed: _busy ? null : _uploadChunks,
              child: const Text('Jetzt hochladen'),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Privacy-Zonen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _busy ? null : _addZone,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Zone'),
              ),
            ],
          ),
          if (_zones.isEmpty)
            const Text(
              'Keine Zonen — Start/Ziel-Umgebung kann getrimmt werden.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          for (final z in _zones)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(z.label),
              subtitle: Text(
                '${z.lat.toStringAsFixed(4)}, ${z.lng.toStringAsFixed(4)} · '
                '${z.radiusM.round()} m',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await ref
                      .read(garageRepositoryProvider)
                      .removePrivacyZone(z.id);
                  await _load();
                },
              ),
            ),
          const SizedBox(height: 12),
          const Text(
            'Familien-Link / Mitfahrer: unter Profil → Familien-Garage '
            'weitere Fahrer mit eigenem Gewicht anlegen.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Text(
            'Export (Art. 20)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportGpx,
            icon: const Icon(Icons.route),
            label: const Text('Letzter Ride als GPX'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportFit,
            icon: const Icon(Icons.directions_bike),
            label: const Text('Letzter Ride als FIT'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportJson,
            icon: const Icon(Icons.data_object),
            label: const Text('JSON-Vollexport'),
          ),
          const SizedBox(height: 8),
          if (kDebugMode)
            OutlinedButton.icon(
              onPressed: _busy ? null : _exportStravaStub,
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Strava-Payload (lokal, Entwickler)'),
            ),
          if (_stravaConfigured) ...[
            const SizedBox(height: 8),
            if (!_stravaConnected && _stravaAuthorizeUrl != null)
              FilledButton.icon(
                onPressed: _busy ? null : _connectStrava,
                icon: const Icon(Icons.link),
                label: const Text('Mit Strava verbinden'),
              ),
            if (_stravaConnected)
              FilledButton.icon(
                onPressed: _busy ? null : _uploadStravaLive,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Letzten Ride zu Strava'),
              ),
          ],
          if (_stravaStatus != null) ...[
            const SizedBox(height: 6),
            Text(
              _stravaStatus!,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            _stravaConfigured
                ? (_stravaConnected
                    ? 'Live-Upload nutzt gespeicherte OAuth-Tokens (Server).'
                    : 'OAuth öffnet den Browser; nach Freigabe App fortsetzen.')
                : 'Strava ist nicht eingerichtet. GPX, FIT und JSON sind die Exportwege.',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}
