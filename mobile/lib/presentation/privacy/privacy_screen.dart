import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/export/export_trimmed.dart';
import '../../data/export/json_export.dart';
import '../../data/export/strava_client.dart';
import '../../data/export/strava_stub.dart';
import '../../data/local/ride_prefs.dart';
import '../../data/routing/heatmap_client.dart';
import '../../data/routing/saved_route_meta_store.dart';
import '../../data/sensor/manufacturer_ble_wipe.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/privacy/consents.dart';
import '../../domain/privacy/privacy_zone_map.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../shared/chrome_glyph.dart';
import 'privacy_zone_map_screen.dart';

({String title, String body}) _consentCopy(
  AppLocalizations l10n,
  ConsentPurpose purpose,
) {
  switch (purpose) {
    case ConsentPurpose.rawDataUpload:
      return (title: l10n.consentRawTitle, body: l10n.consentRawBody);
    case ConsentPurpose.heatmapContribution:
      return (title: l10n.consentHeatmapTitle, body: l10n.consentHeatmapBody);
    case ConsentPurpose.productRecommendations:
      return (title: l10n.consentRecoTitle, body: l10n.consentRecoBody);
    case ConsentPurpose.analytics:
      return (title: l10n.consentAnalyticsTitle, body: l10n.consentAnalyticsBody);
    case ConsentPurpose.healthData:
      return (title: l10n.consentHealthTitle, body: l10n.consentHealthBody);
  }
}

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
  bool _trimEnds = true;

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
          final l10n = AppLocalizations.of(context);
          final q = uri.queryParameters['strava'];
          setState(() {
            _message = q == 'connected'
                ? l10n.privacyStravaConnected
                : (q != null
                    ? l10n.privacyStravaStatus(q)
                    : l10n.privacyStravaCallback);
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
        final l10n = AppLocalizations.of(context);
        setState(() => _stravaStatus = l10n.privacyStravaUnreachable);
      }
    }
  }

  Future<void> _connectStrava() async {
    final l10n = AppLocalizations.of(context);
    final url = _stravaAuthorizeUrl;
    if (url == null) {
      setState(() => _message = l10n.privacyStravaUrlMissing);
      return;
    }
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      setState(() => _message = l10n.billingBrowserFailed);
    } else if (mounted) {
      setState(() => _message = l10n.privacyStravaBrowser);
    }
  }

  Future<void> _uploadStravaLive() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = l10n.privacyNoRideUpload);
        return;
      }
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final r = await uploadRideToStrava(
        rides.first,
        zones: zones,
        trimEndsM: _trimEndsM,
      );
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
    final trimEnds = await RidePrefs.privacyTrimEndsEnabled();
    final merged = defaultConsentGrants();
    merged.addAll(consents);
    final pending =
        await ref.read(rideChunkRepositoryProvider).pendingCount();
    if (mounted) {
      setState(() {
        _consents = merged;
        _zones = zones;
        _pendingChunks = pending;
        _trimEnds = trimEnds;
      });
    }
  }

  Future<void> _setTrimEnds(bool value) async {
    await RidePrefs.setPrivacyTrimEndsEnabled(value);
    if (mounted) setState(() => _trimEnds = value);
  }

  double get _trimEndsM => _trimEnds ? 200 : 0;

  Future<void> _uploadChunks() async {
    final l10n = AppLocalizations.of(context);
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
              ? l10n.privacyChunksUploaded(n, left)
              : left > 0
                  ? l10n.privacyChunksBlocked(left)
                  : l10n.privacyChunksNone;
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
      final metas = await SavedRouteMetaStore.listAll();
      for (final r in rides) {
        if (!RouteVisibility.mayContributeRide(r.routeId, metas[r.routeId])) {
          continue;
        }
        final res = await contributeHeatmapTrack(
          track: r.track,
          privacyZones: zones,
          trimEndsM: _trimEndsM,
        );
        n += res.upserted;
      }
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      if (n > 0) {
        setState(() => _message = l10n.privacyHeatmapCells(n));
      } else if (rides.isNotEmpty) {
        setState(() => _message = l10n.privacyHeatmapNone);
      }
    } catch (_) {}
  }

  Future<void> _openZoneEditor({PrivacyZone? existing}) async {
    final zone = await openPrivacyZoneMap(context, existing: existing);
    if (!mounted || zone == null) return;
    await ref.read(garageRepositoryProvider).upsertPrivacyZone(zone);
    await _load();
  }

  Future<void> _confirmDeleteZone(PrivacyZone zone) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.privacyZoneDelete),
          content: Text(loc.privacyZoneDeleteConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.delete),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    await ref.read(garageRepositoryProvider).removePrivacyZone(zone.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.privacyZoneDeleted)),
    );
  }

  Future<void> _sharePath(String path, {String? mime}) async {
    final l10n = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: mime)],
        subject: l10n.privacyExportSubject,
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
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = l10n.privacyNoRideExport);
        return;
      }
      final bike = await ref.read(garageRepositoryProvider).getActiveBike();
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final gpx = exportGpxTrimmed(
        rides.first,
        zones: zones,
        bikeName: bike?.name,
        trimEndsM: _trimEndsM,
      );
      final path = await _writeExport(
        'aetherride-${rides.first.id.substring(0, 8)}.gpx',
        gpx,
      );
      await _sharePath(path, mime: 'application/gpx+xml');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.privacySharedGpx(path))),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportFit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = l10n.privacyNoRideExport);
        return;
      }
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final bytes = exportFitTrimmed(
        rides.first,
        zones: zones,
        trimEndsM: _trimEndsM,
      );
      final path = await _writeBytes(
        'aetherride-${rides.first.id.substring(0, 8)}.fit',
        bytes,
      );
      await _sharePath(path, mime: 'application/octet-stream');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.privacySharedFit(path))),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportStravaStub() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final rides = await ref.read(rideRepositoryProvider).listRides(limit: 1);
      if (rides.isEmpty) {
        setState(() => _message = l10n.privacyNoRideExporting);
        return;
      }
      final zones = await ref.read(garageRepositoryProvider).listPrivacyZones();
      final json = rideToStravaActivityJson(
        rideWithTrimmedTrack(rides.first, zones, trimEndsM: _trimEndsM),
      );
      final path = await _writeExport(
        'aetherride-strava-${rides.first.id.substring(0, 8)}.json',
        json,
      );
      await _sharePath(path, mime: 'application/json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.privacySharedStravaStub(path))),
        );
      }
    } catch (e) {
      setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgetManufacturerBle() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogL10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(dialogL10n.privacyBleForget),
          content: Text(dialogL10n.privacyBleForgetBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(dialogL10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(dialogL10n.bleRemoveDevice),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await wipeManufacturerBleData(
        store: ref.read(bikeBleStoreProvider),
        ble: ref.read(bleCoreProvider),
      );
      if (mounted) {
        setState(() => _message = l10n.privacyBleForgotten);
      }
    } catch (e) {
      if (mounted) setState(() => _message = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() async {
    final l10n = AppLocalizations.of(context);
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
        for (final r in rides) rideWithTrimmedTrack(r, zones, trimEndsM: _trimEndsM),
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
          SnackBar(content: Text(l10n.privacySharedJson(path))),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.privacyHomePlacesTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _openZoneEditor(),
                icon: const ChromeGlyph('add', size: 18),
                label: Text(l10n.privacyZoneAdd),
              ),
            ],
          ),
          Text(
            l10n.privacyZonesLead,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.privacyTrimEndsTitle),
            subtitle: Text(
              l10n.privacyTrimEndsBody,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            value: _trimEnds,
            onChanged: _busy ? null : _setTrimEnds,
          ),
          const SizedBox(height: 8),
          if (_zones.isEmpty)
            Text(
              l10n.privacyNoZones,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.privacyZonePhotoHint,
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ),
          for (final z in _zones)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(z.label),
              subtitle: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: l10n.privacyZoneRadius(
                        privacyZoneRadiusLabel(z.radiusM),
                      ),
                    ),
                    const TextSpan(text: '\n'),
                    TextSpan(
                      text: privacyZoneCoordHint(z.lat, z.lng),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              isThreeLine: true,
              onTap: _busy ? null : () => _openZoneEditor(existing: z),
              trailing: IconButton(
                icon: const ChromeGlyph('trash', size: 22),
                tooltip: l10n.privacyZoneDelete,
                onPressed: _busy ? null : () => _confirmDeleteZone(z),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            l10n.privacyConsents,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          for (final purpose in ConsentPurpose.values)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_consentCopy(l10n, purpose).title),
              subtitle: Text(
                _consentCopy(l10n, purpose).body,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              value: _consents[purpose.apiId] ?? false,
              onChanged: _busy
                  ? null
                  : (v) => _setConsent(purpose, v),
            ),
          const SizedBox(height: 8),
          Text(
            _consents['raw_data_upload'] == true
                ? l10n.privacyChunksPending(_pendingChunks)
                : l10n.privacyChunksPendingConsentOff(_pendingChunks),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (_pendingChunks > 0)
            TextButton(
              onPressed: _busy ? null : _uploadChunks,
              child: Text(l10n.privacyUploadNow),
            ),
          const SizedBox(height: 20),
          Text(
            l10n.privacyBleTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.privacyBleForgetBody,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('privacy-ble-forget'),
            onPressed: _busy ? null : _forgetManufacturerBle,
            icon: const ChromeGlyph('bluetooth', size: 22),
            label: Text(l10n.privacyBleForget),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.privacyExportTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportGpx,
            icon: const ChromeGlyph('split', size: 20),
            label: Text(l10n.privacyExportGpx),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportFit,
            icon: const ChromeGlyph('nav', size: 20),
            label: Text(l10n.privacyExportFit),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _exportJson,
            icon: const ChromeGlyph('file', size: 20),
            label: Text(l10n.privacyExportJson),
          ),
          const SizedBox(height: 8),
          if (AppConfig.showRoutingDebug)
            OutlinedButton.icon(
              onPressed: _busy ? null : _exportStravaStub,
              icon: const ChromeGlyph('download', size: 20),
              label: Text(l10n.privacyExportStravaStub),
            ),
          if (_stravaConfigured) ...[
            const SizedBox(height: 8),
            if (!_stravaConnected && _stravaAuthorizeUrl != null)
              FilledButton.icon(
                onPressed: _busy ? null : _connectStrava,
                icon: const ChromeGlyph('link', size: 20),
                label: Text(l10n.privacyStravaConnect),
              ),
            if (_stravaConnected)
              FilledButton.icon(
                onPressed: _busy ? null : _uploadStravaLive,
                icon: const ChromeGlyph('cloud', size: 22),
                label: Text(l10n.privacyStravaUpload),
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
                    ? l10n.privacyStravaLiveHint
                    : l10n.privacyStravaOauthHint)
                : l10n.privacyStravaMissing,
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

Future<void> openPrivacyScreen(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
  );
}
