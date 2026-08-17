import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/community_places_client.dart';
import '../../data/routing/ride_to_saved.dart';
import '../../data/routing/saved_route_meta_store.dart';
import '../../domain/community/map_place.dart';
import '../../domain/community/place_on_track.dart';
import '../../domain/community/stimme_pin.dart';
import '../../domain/ride.dart';
import '../../domain/saved_route_note.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';

const _ortKinds = <MapPlaceKind>[
  MapPlaceKind.cafe,
  MapPlaceKind.water,
  MapPlaceKind.viewpoint,
  MapPlaceKind.shop,
  MapPlaceKind.repair,
  MapPlaceKind.other,
];

/// Nach der Stimme: Ort immer privat; öffentlich nur mit Session + Linie.
class PostRideOrtCard extends ConsumerStatefulWidget {
  const PostRideOrtCard({
    super.key,
    required this.ride,
    this.stimmeTourId,
  });

  final RideRecord ride;
  final String? stimmeTourId;

  @override
  ConsumerState<PostRideOrtCard> createState() => _PostRideOrtCardState();
}

class _PostRideOrtCardState extends ConsumerState<PostRideOrtCard> {
  final _nameCtrl = TextEditingController();
  MapPlaceKind _kind = MapPlaceKind.cafe;
  bool _busy = false;
  bool _done = false;
  bool _skipped = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _nameCtrl.text.trim();
    if (name.length < 2) return;
    setState(() => _busy = true);
    try {
      final ride = widget.ride;
      final coords = trackMapsToLngLat(ride.track);
      final last = coords.isEmpty ? null : coords.last;
      final pin = last == null
          ? null
          : snapStimmePin(
              coordinates: coords,
              lat: last[1],
              lng: last[0],
            );
      var routeId = ride.routeId?.trim();
      if (routeId == null || routeId.isEmpty) {
        final entry = await saveRideAsTour(
          routes: ref.read(routeRepositoryProvider),
          ride: ride,
          id: 'recorded-${ride.id}',
        );
        routeId = entry.id;
        ref.invalidate(savedRoutesProvider);
      }
      final note = SavedRouteNote.create(
        text: name,
        kind: _kind.wire,
        lat: pin?.lat,
        lng: pin?.lng,
      );
      await SavedRouteMetaStore.addNote(routeId, note);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      var msg = l10n.postRideOrtDone;
      final publicTour = widget.stimmeTourId?.trim();
      if (pin == null) {
        msg = l10n.postRideOrtOffTrack;
      } else if (publicTour == null || publicTour.isEmpty) {
        msg = l10n.postRideOrtPrivateOnly;
      } else {
        final cloud = await CommunityPlacesClient().submitPending(
          name: name,
          kind: _kind.wire,
          lat: pin.lat,
          lng: pin.lng,
          rideId: ride.id,
          tourId: publicTour,
          track: coords,
        );
        msg = switch (cloud) {
          PlaceSubmitResult.pending => l10n.postRideOrtPending,
          PlaceSubmitResult.localOnly => l10n.postRideOrtPrivateOnly,
          PlaceSubmitResult.offTrack => l10n.postRideOrtOffTrack,
          PlaceSubmitResult.tableMissing ||
          PlaceSubmitResult.failed =>
            l10n.postRideOrtFailed,
        };
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_skipped) return const SizedBox.shrink();
    if (_done) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          l10n.postRideOrtDone,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.postRideOrtTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.postRideOrtHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final k in _ortKinds)
                ChoiceChip(
                  label: Text(l10n.mapPlaceKindLabel(k)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            maxLength: 80,
            decoration: InputDecoration(
              hintText: l10n.postRideOrtNameHint,
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_save()),
                child: Text(
                  _busy ? l10n.stimmenSaving : l10n.postRideOrtSave,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed:
                    _busy ? null : () => setState(() => _skipped = true),
                child: Text(l10n.postRideOrtSkip),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
