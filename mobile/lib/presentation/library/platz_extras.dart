import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/public_profile_cloud.dart';
import '../../data/community/public_profile_store.dart';
import '../../data/community/ride_group_cloud.dart';
import '../../data/community/group_member_tour.dart';
import '../../data/community/ride_group_invite.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/local/ride_prefs.dart';
import '../../data/local/user_profile_store.dart';
import '../../data/routing/public_tours_client.dart';
import '../../data/routing/route_collections.dart';
import '../../domain/community/ride_group.dart';
import '../../domain/community/ride_group_picker.dart';
import '../../domain/community/ride_group_policy.dart';
import '../../domain/saved_route.dart';
import '../../domain/saved_route_note.dart';
import '../../domain/routing/tour_filters.dart';
import '../../domain/tours/route_visibility.dart';
import '../../domain/tours/tour_akte.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../providers/ride_providers.dart';
import '../auth/auth_screen.dart';
import '../profile/profile_screen.dart';
import '../ride/widgets/ride_group_extend_sheet.dart';
import '../shell/hof_threshold_nav.dart';
import '../shell/shell_tabs.dart';
import 'mappe_glyph.dart';
import 'platz_group_card.dart';
import 'platz_join_sheet.dart';

/// Gruppen, Sammlungen — orchestriert bestehende Stores. Keine Demo-Clubs.
class PlatzExtras extends ConsumerStatefulWidget {
  const PlatzExtras({
    super.key,
    required this.saved,
    required this.metas,
    required this.store,
    this.visibility = TourVisibilityKey.allMine,
    this.onOpenAkte,
  });

  final List<SavedRouteEntry> saved;
  final Map<String, SavedRouteMeta> metas;
  final RideGroupStore store;
  final TourVisibilityKey visibility;
  final Future<void> Function(SavedRouteEntry)? onOpenAkte;

  @override
  PlatzExtrasState createState() => PlatzExtrasState();
}

class PlatzExtrasState extends ConsumerState<PlatzExtras> {
  List<RideGroup> _groups = const [];
  List<RideGroup> _public = const [];
  Map<String, List<RideGroupMember>> _members = const {};
  Map<String, bool> _localOptIn = const {};
  List<RouteCollection> _cols = const [];
  String? _joinErr;
  Set<String> _selfIds = {};
  String? _syncNote;
  bool _signedIn = true;
  bool _collectionsOpen = false;
  bool _collectionsToggled = false;
  bool _groupsOpen = false;
  bool _groupsToggled = false;
  bool _inviteNamePrompted = false;

  @override
  void initState() {
    super.initState();
    RideGroupStore.revision.addListener(_reload);
    unawaited(widget.store.pullCloud());
    unawaited(_reload());
    unawaited(_checkSession());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumePendingJoin(ref.read(platzPendingJoinProvider));
    });
  }

  @override
  void didUpdateWidget(PlatzExtras oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibility != widget.visibility) {
      unawaited(_reload());
    }
  }

  @override
  void dispose() {
    RideGroupStore.revision.removeListener(_reload);
    super.dispose();
  }

  /// Offene Gruppen anderer: immer auf dem Platz, nicht nur unter Freigegeben.
  List<RideGroup> get _listedPublic {
    final mine = {for (final g in _groups) g.id};
    return [
      for (final g in _public)
        if (!mine.contains(g.id)) g
    ];
  }

  Future<void> _reload() async {
    final label = await _selfLabel();
    final groups = await widget.store.activeGroups();
    final members = <String, List<RideGroupMember>>{};
    final opt = <String, bool>{};
    for (final g in groups) {
      await widget.store.relabelLocal(g.id, label);
      members[g.id] = await widget.store.membersOf(g.id);
      opt[g.id] = (await widget.store.localMember(g.id))?.liveOptIn ?? false;
    }
    final cols = await RouteCollectionsStore.list();
    final ids = await widget.store.selfIds();
    final pub = await widget.store.publicGroups();
    if (!mounted) return;
    setState(() {
      _groups = groups;
      _public = pub;
      _members = members;
      _localOptIn = opt;
      _cols = cols;
      _selfIds = ids;
      _syncNote = widget.store.lastNote;
      if (!_groupsToggled) {
        _groupsOpen = groups.isNotEmpty;
      }
      if (!_collectionsToggled) {
        _collectionsOpen = cols.isNotEmpty;
      }
    });
  }

  Future<void> _checkSession() async {
    final state = await RideGroupCloud.sessionState();
    if (!mounted) return;
    setState(() => _signedIn = state != 'signedOut');
  }

  DateTime _startFromPreset(int preset) {
    final n = DateTime.now();
    switch (preset) {
      case 1:
        return n.add(const Duration(hours: 1));
      case 2:
        final today18 = DateTime(n.year, n.month, n.day, 18);
        return today18.isAfter(n)
            ? today18
            : today18.add(const Duration(days: 1));
      case 3:
        return DateTime(n.year, n.month, n.day, 10)
            .add(const Duration(days: 1));
      default:
        return n;
    }
  }

  Future<RideGroupPickerOrigin?> _pickerOrigin() async {
    double? gpsLat;
    double? gpsLng;
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        gpsLat = last.latitude;
        gpsLng = last.longitude;
      } else {
        final perm = await Geolocator.checkPermission();
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 2),
            ),
          );
          gpsLat = pos.latitude;
          gpsLng = pos.longitude;
        }
      }
    } catch (_) {}
    final vp = await RidePrefs.discoverViewport();
    return RideGroupPicker.resolveOrigin(
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      mapLat: vp?.lat,
      mapLng: vp?.lng,
      saved: widget.saved,
    );
  }

  Future<({List<RideGroupPickerItem> items, RideGroupPickerOrigin? origin})>
      _loadPicker() async {
    final origin = await _pickerOrigin();
    var catalog = const <RideGroupCatalogHit>[];
    try {
      final hits = await PublicToursClient().fetchCatalog();
      catalog = [
        for (final t in hits)
          if (t.id.isNotEmpty)
            RideGroupCatalogHit(
              id: t.id,
              name: t.name,
              lat: t.centerLat,
              lng: t.centerLng,
            ),
      ];
    } catch (_) {}
    return (
      items: RideGroupPicker.build(
        saved: widget.saved,
        metas: widget.metas,
        catalog: catalog,
        originLat: origin?.lat,
        originLng: origin?.lng,
      ),
      origin: origin,
    );
  }

  Future<RideGroupPickerItem?> _promptPickTour() async {
    if (!mounted) return null;
    final loaded = await _loadPicker();
    if (!mounted) return null;
    final items = loaded.items;
    final origin = loaded.origin;
    return showModalBottomSheet<RideGroupPickerItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        final mine = [
          for (final i in items)
            if (i.section == RideGroupPickerSection.mine) i,
        ];
        final nearby = [
          for (final i in items)
            if (i.section == RideGroupPickerSection.nearby) i,
        ];
        final nearbyHint = origin == null
            ? loc.platzNearbyNeedGps
            : origin.kind == RideGroupPickerOriginKind.gps
                ? null
                : loc.platzNearbyFromMap;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: HofThresholdNav.sheetBottomInset(ctx),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                loc.platzCreateGroup,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loc.platzCreateGroupHint,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.route_outlined),
                title: Text(loc.platzPlanAsGroup),
                subtitle: Text(loc.platzPlanAsGroupHint),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(platzPendingPlanAsGroupProvider.notifier).state =
                      true;
                  ref.read(discoverLaunchModeProvider.notifier).state =
                      DiscoverLaunchMode.plan;
                  ref.read(shellTabIndexProvider.notifier).state =
                      ShellTabs.karte;
                },
              ),
              if (mine.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  loc.platzPickMine,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                for (final s in mine)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.name),
                    subtitle: s.privateTour ? Text(loc.discoverPrivate) : null,
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.pop(ctx, s),
                  ),
              ],
              if (nearby.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  loc.platzPickNearby,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                if (nearbyHint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    nearbyHint,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
                for (final s in nearby)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.name),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.pop(ctx, s),
                  ),
              ] else if (nearbyHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  loc.platzPickNearby,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nearbyHint,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              if (mine.isEmpty && nearby.isEmpty && origin != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    loc.platzNoSharedTours,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> createGroup({SavedRouteEntry? attach}) =>
      _createGroup(attach: attach);

  Future<void> _createGroup({SavedRouteEntry? attach}) async {
    if (!_signedIn) {
      if (!mounted) return;
      openAuthScreen(context);
      return;
    }
    late final RideGroupPickerItem chosen;
    if (attach != null) {
      final ok = RideGroupPolicy.canAttachSaved(
        attach,
        widget.metas[attach.id],
      );
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context).platzNeedSharedTour)),
        );
        return;
      }
      final meta = widget.metas[attach.id] ?? SavedRouteMeta.empty;
      final catalogId = catalogTourIdOf(attach.id, meta);
      chosen = RideGroupPickerItem(
        id: attach.id,
        name: attach.name,
        section: RideGroupPickerSection.mine,
        catalogTourId: catalogId,
        privateTour: !RouteVisibility.isShared(meta) && catalogId == null,
      );
    } else {
      final picked = await _promptPickTour();
      if (picked == null || !mounted) return;
      chosen = picked;
    }
    var listing = RideGroupVisibility.private;
    var startPreset = 0;
    DateTime? customStart;
    var durationH = 3.0;
    var durationCustom = false;
    var windowErr = false;
    final meetingCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final created = await showModalBottomSheet<({DateTime start, double hours})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: HofThresholdNav.sheetBottomInset(ctx) +
                MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              final loc = AppLocalizations.of(ctx);
              DateTime startOf() => startPreset == 4
                  ? (customStart ?? DateTime.now())
                  : _startFromPreset(startPreset);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      loc.platzTogetherTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.platzCreateGroupHint,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      chosen.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (chosen.privateTour)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          loc.discoverPrivate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [
                        ChoiceChip(
                          label: Text(loc.discoverPrivateCap),
                          selected: listing == RideGroupVisibility.private,
                          onSelected: (_) => setSheet(
                            () => listing = RideGroupVisibility.private,
                          ),
                        ),
                        ChoiceChip(
                          label: Text(loc.filterVisibilityPublic),
                          selected: listing == RideGroupVisibility.public,
                          onSelected: (_) => setSheet(
                            () => listing = RideGroupVisibility.public,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      listing == RideGroupVisibility.public
                          ? loc.platzGroupPublicHint
                          : loc.platzGroupPrivateHint,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.platzStartLabel,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final e in [
                          (0, loc.platzStartNow),
                          (1, loc.platzStartIn1h),
                          (2, loc.platzStartToday18),
                          (3, loc.platzStartTomorrow10),
                          (
                            4,
                            customStart == null
                                ? loc.platzStartCustom
                                : formatRideGroupLocalWhen(customStart!),
                          ),
                        ])
                          ChoiceChip(
                            key: e.$1 == 4
                                ? const Key('platz-start-custom')
                                : null,
                            label: Text(e.$2),
                            selected: startPreset == e.$1,
                            onSelected: (_) async {
                              if (e.$1 == 4) {
                                final picked = await pickRideGroupDateTime(
                                  ctx,
                                  initial: customStart ??
                                      DateTime.now()
                                          .add(const Duration(hours: 1)),
                                );
                                if (picked == null) return;
                                setSheet(() {
                                  startPreset = 4;
                                  customStart = picked;
                                  windowErr = false;
                                });
                                return;
                              }
                              setSheet(() {
                                startPreset = e.$1;
                                windowErr = false;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.platzDurationLabel,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final h in [2.0, 3.0, 4.0])
                          ChoiceChip(
                            label: Text('${h.toInt()} h'),
                            selected: !durationCustom && durationH == h,
                            onSelected: (_) => setSheet(() {
                              durationH = h;
                              durationCustom = false;
                              windowErr = false;
                            }),
                          ),
                        ChoiceChip(
                          key: const Key('platz-duration-custom'),
                          label: Text(loc.platzDurationCustom),
                          selected: durationCustom,
                          onSelected: (_) => setSheet(() {
                            durationCustom = true;
                            windowErr = false;
                          }),
                        ),
                      ],
                    ),
                    if (durationCustom) ...[
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('platz-duration-hours'),
                        controller: durationCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: loc.platzDurationHoursHint,
                          isDense: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      loc.platzWindowCapHint,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    if (windowErr)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          loc.rideGroupExtendInvalid,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: meetingCtrl,
                      decoration: InputDecoration(
                        labelText: loc.platzMeetingPlaceholder,
                        hintText: loc.platzMeetingHint,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        final hours = durationCustom
                            ? RideGroupPolicy.parseDurationHours(
                                durationCtrl.text,
                              )
                            : durationH;
                        final start = startOf();
                        final parsed = hours == null
                            ? null
                            : RideGroupPolicy.parseWindow(
                                startsAt: start,
                                durationHours: hours,
                                now: DateTime.now(),
                              );
                        if (parsed == null) {
                          setSheet(() => windowErr = true);
                          return;
                        }
                        Navigator.pop(
                          ctx,
                          (start: parsed.start, hours: parsed.durationHours),
                        );
                      },
                      child: Text(loc.platzCreateGroup),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    final meeting = meetingCtrl.text.trim();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      meetingCtrl.dispose();
      durationCtrl.dispose();
    });
    if (created == null) return;
    final start = created.start;
    final durationHOut = created.hours;
    final meta = widget.metas[chosen.id] ??
        (chosen.catalogTourId != null
            ? SavedRouteMeta(catalogTourId: chosen.catalogTourId)
            : SavedRouteMeta.empty);
    try {
      final group = await widget.store.createGroup(
        savedRouteId: chosen.id,
        title: chosen.name,
        catalogTourId: chosen.catalogTourId ??
            catalogTourIdOf(chosen.id, meta),
        meta: meta,
        displayLabel: await _selfLabel(),
        visibility: listing,
        windowStart: start,
        windowEnd: start.add(RideGroupPolicy.durationFromHours(durationHOut)),
        durationHours: durationHOut,
        meetingPoint: meeting.isEmpty ? null : meeting,
      );
      if (!mounted) return;
      final note = widget.store.lastNote;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(note ?? l10n.platzInviteShares),
        ),
      );
      await _invite(group);
    } on StateError catch (e) {
      if (!mounted) return;
      final msg = e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (msg.contains('Anmelden')) openAuthScreen(context);
    }
  }

  void _consumePendingJoin(PlatzPendingJoin? pending) {
    if (pending == null || pending.code.trim().isEmpty) return;
    ref.read(platzPendingJoinProvider.notifier).state = null;
    unawaited(() async {
      if (!await _requireSignInForJoin()) return;
      if (!mounted) return;
      await _applyJoin(pending.code, token: pending.token);
    }());
  }

  Future<bool> _requireSignInForJoin() async {
    await _checkSession();
    if (_signedIn) return true;
    if (!mounted) return false;
    openAuthScreen(context);
    setState(() {
      _joinErr = AppLocalizations.of(context).platzJoinSignInFirst;
    });
    return false;
  }

  Future<void> _joinWithLink() async {
    final pasted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PlatzJoinSheet(
        signedIn: _signedIn,
        onSignIn: () => openAuthScreen(context),
      ),
    );
    if (pasted == null || !mounted) return;
    final parsed = RideGroupInvite.parsePastedJoin(pasted);
    if (parsed == null) {
      setState(() => _joinErr = AppLocalizations.of(context).platzJoinInvalid);
      return;
    }
    if (!await _requireSignInForJoin()) return;
    await _applyJoin(parsed.code, token: parsed.token);
  }

  Future<String> _selfLabel() async {
    try {
      final pub = await PublicProfileStore().load();
      if (pub.enabled) {
        final name = pub.displayName.trim();
        if (name.isNotEmpty) return name;
        final handle = pub.handle.trim();
        if (handle.isNotEmpty) return '@$handle';
      }
      final user = UserProfileStore();
      await user.load();
      final n = user.displayName?.trim() ?? '';
      if (n.isNotEmpty) return n;
    } catch (_) {}
    if (!mounted) return '';
    return AppLocalizations.of(context).platzYou;
  }

  Future<String?> _selfProfileUrl() async {
    try {
      var pub = await PublicProfileStore().load();
      if (!pub.enabled || pub.handle.trim().isEmpty) {
        final cloud = await PublicProfileCloud.pullMine();
        if (cloud != null) pub = await PublicProfileStore().save(cloud);
      }
      if (!pub.enabled) return null;
      return RideGroupInvite.profileHttpsUrl(handle: pub.handle);
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyJoin(String code, {String? token}) async {
    final out = await widget.store.tryJoin(
      code: code,
      token: token,
      displayLabel: await _selfLabel(),
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _joinErr = out.fail != null ? out.message : null);
      if (out.fail == RideGroupJoinFail.needLogin) {
        openAuthScreen(context);
      }
      if (out.fail != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(out.message)),
        );
      }
      if (out.group != null) {
        unawaited(_importInviteTour(token));
        final g = out.group!;
        final text = g.onServer
            ? out.message
            : AppLocalizations.of(context).platzJoinLocal(g.title);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text),
            action: (!g.onServer && !_signedIn)
                ? SnackBarAction(
                    label: AppLocalizations.of(context).signIn,
                    onPressed: () => openAuthScreen(context),
                  )
                : null,
          ),
        );
      }
    });
  }

  Future<void> _startRideFromGroup(RideGroup g) async {
    final pending = startRidePendingIdForGroup(
      savedRouteId: g.savedRouteId,
      catalogTourId: g.catalogTourId,
      saved: widget.saved,
      metas: widget.metas,
    );
    if (pending == null || pending.isEmpty) {
      await _explainTourMissing();
      return;
    }
    ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.mine;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
    ref.read(ridePendingGroupIdProvider.notifier).state = g.id;
    ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = pending;
  }

  Future<void> _explainTourMissing() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            HofThresholdNav.sheetBottomInset(ctx),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.platzTourNotInMappe,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                loc.platzTourNotInMappeHint,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.ok),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toast(String text) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    });
  }

  Future<void> _invite(RideGroup g) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    var profileUrl = await _selfProfileUrl();
    if (profileUrl == null && !_inviteNamePrompted) {
      _inviteNamePrompted = true;
      final openProfile = await _offerProfileBeforeInvite();
      if (!mounted) return;
      if (openProfile) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
        );
        if (!mounted) return;
        profileUrl = await _selfProfileUrl();
      }
    }
    final token = _inviteToken(g);
    final url = RideGroupInvite.httpsUrl(groupId: g.id, token: token);
    final appUrl = RideGroupInvite.customSchemeUrl(groupId: g.id, token: token);
    await SharePlus.instance.share(
      ShareParams(
        text: RideGroupInvite.shareText(
          title: g.title,
          url: url,
          appUrl: appUrl,
          code: RideGroupPolicy.canJoinByTypedCode(g.visibility)
              ? g.joinCode
              : null,
          profileUrl: profileUrl,
          visibility: g.visibility,
          when: RideGroupPolicy.formatWhen(
            g.startWindowStart,
            g.startWindowEnd,
          ),
          meetingPoint: g.meetingPoint,
        ),
        subject: l10n.platzShareSubject(g.title),
      ),
    );
  }

  Future<bool> _offerProfileBeforeInvite() async {
    if (!mounted) return false;
    final go = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            HofThresholdNav.sheetBottomInset(ctx),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.platzInviteAsYou,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(loc.platzInviteOpenProfile),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(loc.platzInviteAsYouLater),
              ),
            ],
          ),
        );
      },
    );
    return go == true;
  }

  Future<void> _leaveOrClose(RideGroup g) async {
    final host = _selfIds.contains(g.hostUserId);
    await widget.store.leaveGroup(g.id);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    _toast(
      widget.store.lastNote ?? (host ? l10n.platzDissolve : l10n.platzLeave),
    );
  }

  Future<void> _extendWindow(RideGroup g) async {
    final choice = await showRideGroupExtendSheet(
      context,
      currentWhen: formatRideGroupWhenLine(
        start: g.startWindowStart,
        end: g.startWindowEnd,
        l10n: AppLocalizations.of(context),
      ),
    );
    if (choice == null || !mounted) return;
    final ok = await widget.store.extendWindow(
      g.id,
      hours: choice.addHours ?? 1,
      newEnd: choice.newEnd,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    _toast(
      widget.store.lastNote ??
          (ok ? l10n.rideGroupWindowExtended : l10n.rideGroupExtendInvalid),
    );
    if (ok) await _reload();
  }

  Future<void> _setPins(String groupId, bool on) async {
    await widget.store.setLiveOptIn(groupId, on);
    if (!mounted) return;
    setState(() => _localOptIn = {..._localOptIn, groupId: on});
    if (on) _toast(AppLocalizations.of(context).platzPinsHint);
  }

  Future<void> _toggleListing(RideGroup g) async {
    final next = g.visibility == RideGroupVisibility.public
        ? RideGroupVisibility.private
        : RideGroupVisibility.public;
    await widget.store.setVisibility(g.id, next);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    _toast(
      next == RideGroupVisibility.public
          ? l10n.platzGroupListedNote
          : l10n.platzGroupUnlistedNote,
    );
  }

  String _inviteToken(RideGroup g) {
    SavedRouteEntry? route;
    for (final s in widget.saved) {
      if (s.id == g.savedRouteId) {
        route = s;
        break;
      }
    }
    return RideGroupInvite.encode(
      g,
      route: route,
      meta: widget.metas[g.savedRouteId],
    );
  }

  Future<void> _importInviteTour(String? token) async {
    if (token == null || token.isEmpty) return;
    final entry = importMemberTourFromInvite(
      payload: RideGroupInvite.decode(token),
      existing: widget.saved,
    );
    if (entry == null) return;
    await ref.read(routeRepositoryProvider).saveEntry(entry);
    ref.invalidate(savedRoutesProvider);
  }

  Future<void> _copyInvite(RideGroup g) async {
    final token = _inviteToken(g);
    final url = RideGroupInvite.httpsUrl(groupId: g.id, token: token);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _toast(AppLocalizations.of(context).platzLinkCopied);
  }

  Future<void> _copyCode(RideGroup g) async {
    await Clipboard.setData(ClipboardData(text: g.joinCode));
    if (!mounted) return;
    _toast(AppLocalizations.of(context).platzCodeCopied);
  }

  Future<void> _shareCollection(RouteCollection c) async {
    final ids = RouteVisibility.shareableRouteIds(c.routeIds, widget.metas);
    if (ids.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).platzNoSharedTours),
        ),
      );
      return;
    }
    final names = <String>[];
    for (final id in ids) {
      String? name;
      for (final s in widget.saved) {
        if (s.id == id) {
          name = s.name;
          break;
        }
      }
      names.add(name ?? id);
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await SharePlus.instance.share(
      ShareParams(
        text: l10n.platzCollectionShare(c.name, names.join(', ')),
        subject: c.name,
      ),
    );
  }

  Future<void> _createCollection() async {
    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return Padding(
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
                loc.mappeCollectionNew,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: loc.platzCollectionDefaultName(
                    DateTime.now().day,
                    DateTime.now().month,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(loc.mappeCollectionNew),
              ),
            ],
          ),
        );
      },
    );
    final name = ctrl.text.trim();
    Future<void>.delayed(const Duration(milliseconds: 400), ctrl.dispose);
    if (ok != true || name.isEmpty) return;
    await RouteCollectionsStore.create(name);
    setState(() {
      _collectionsOpen = true;
      _collectionsToggled = true;
    });
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlatzPendingJoin?>(platzPendingJoinProvider, (prev, next) {
      _consumePendingJoin(next);
    });
    ref.listen<String?>(platzPendingCreateGroupRouteIdProvider, (prev, next) {
      if (next == null || next.isEmpty) return;
      ref.read(platzPendingCreateGroupRouteIdProvider.notifier).state = null;
      SavedRouteEntry? hit;
      for (final s in widget.saved) {
        if (s.id == next) {
          hit = s;
          break;
        }
      }
      if (hit != null) unawaited(createGroup(attach: hit));
    });
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 6),
          child: PlatzFoldHeader(
            label: l10n.platzTogetherKicker,
            glyph: 'meet',
            count: _groups.isEmpty ? null : _groups.length,
            expanded: _groupsOpen,
            onTap: () => setState(() {
              _groupsToggled = true;
              _groupsOpen = !_groupsOpen;
            }),
          ),
        ),
        if (_groupsOpen) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.platzTogetherHint,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          if (!_signedIn)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.platzJoinSignInFirst,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                  TextButton(
                    onPressed: () => openAuthScreen(context),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(l10n.signIn),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.icon(
                  key: const Key('platz-group-create'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    if (_signedIn) {
                      unawaited(_createGroup());
                    } else {
                      openAuthScreen(context);
                    }
                  },
                  icon:
                      Icon(_signedIn ? Icons.group_add : Icons.login, size: 18),
                  label: Text(_signedIn ? l10n.platzCreateGroup : l10n.signIn),
                ),
                OutlinedButton.icon(
                  key: const Key('platz-group-join'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => unawaited(_joinWithLink()),
                  icon: const Icon(Icons.link, size: 18),
                  label: Text(l10n.platzJoinWithCode),
                ),
              ],
            ),
          ),
          if (_joinErr != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _joinErr!,
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            )
          else if (_syncNote != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _syncNote!,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  if (_syncNote!.contains('Nicht eingeloggt'))
                    TextButton(
                      onPressed: () => openAuthScreen(context),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.signIn),
                    ),
                ],
              ),
            ),
          if (_groups.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l10n.platzNoGroup,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            )
          else
            for (final g in _groups)
              PlatzGroupCard(
                group: g,
                members: _members[g.id] ?? const <RideGroupMember>[],
                selfIds: _selfIds,
                signedIn: _signedIn,
                optIn: _localOptIn[g.id] ?? false,
                onInvite: () => unawaited(_invite(g)),
                onRide: () => unawaited(_startRideFromGroup(g)),
                onLeave: () => unawaited(_leaveOrClose(g)),
                onCopyLink: () => unawaited(_copyInvite(g)),
                onCopyCode: () => unawaited(_copyCode(g)),
                onToggleListing: () => unawaited(_toggleListing(g)),
                onEditTime: () => unawaited(_extendWindow(g)),
                onOptIn: (on) => unawaited(_setPins(g.id, on)),
                onSignIn: () => openAuthScreen(context),
              ),
          if (_listedPublic.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Text(
                l10n.platzPublicGroupsHint,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            for (final g in _listedPublic)
              Card(
                key: Key('platz-public-${g.id}'),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              l10n.platzListedPublic,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => unawaited(() async {
                          if (!await _requireSignInForJoin()) return;
                          await _applyJoin(g.id, token: null);
                        }()),
                        child: Text(
                          _signedIn ? l10n.platzJoin : l10n.platzJoinLocalCta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: PlatzFoldHeader(
            label: l10n.platzCollectionsKicker,
            glyph: 'collection',
            count: _cols.isEmpty ? null : _cols.length,
            expanded: _collectionsOpen,
            onTap: () => setState(() {
              _collectionsToggled = true;
              _collectionsOpen = !_collectionsOpen;
            }),
          ),
        ),
        if (_collectionsOpen) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.platzCollectionsHint,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
          for (final c in _cols)
            ListTile(
              leading: const MappeGlyph('collection', size: 18),
              title: Text(c.name),
              subtitle: Text(l10n.platzCollectionTours(c.routeIds.length)),
              trailing: TextButton(
                onPressed: () => unawaited(_shareCollection(c)),
                child: Text(l10n.share),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => unawaited(_createCollection()),
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: Text(l10n.mappeCollectionNew),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class PlatzFoldHeader extends StatelessWidget {
  const PlatzFoldHeader({
    super.key,
    required this.label,
    this.count,
    this.expanded = false,
    this.onTap,
    this.glyph,
  });

  final String label;
  final int? count;
  final bool expanded;
  final VoidCallback? onTap;
  final String? glyph;

  @override
  Widget build(BuildContext context) {
    final text = count == null ? label : '$label · $count';
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: AppColors.muted,
    );
    final labelRow = Row(
      children: [
        if (glyph != null) ...[
          MappeGlyph(glyph!, size: 16),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(text, style: style)),
      ],
    );
    if (onTap == null) {
      return labelRow;
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: labelRow),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
