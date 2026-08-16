import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/community/public_profile_cloud.dart';
import '../../data/community/public_profile_store.dart';
import '../../data/community/ride_group_cloud.dart';
import '../../data/community/ride_group_invite.dart';
import '../../data/community/ride_group_store.dart';
import '../../data/local/user_profile_store.dart';
import '../../data/routing/route_collections.dart';
import '../../domain/community/ride_group.dart';
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
import '../shell/hof_threshold_nav.dart';
import '../shell/shell_tabs.dart';

/// Gruppen, Sammlungen — orchestriert bestehende Stores. Keine Demo-Clubs.
class PlatzExtras extends ConsumerStatefulWidget {
  const PlatzExtras({
    super.key,
    required this.saved,
    required this.metas,
    required this.store,
    this.visibility = TourVisibilityKey.allMine,
  });

  final List<SavedRouteEntry> saved;
  final Map<String, SavedRouteMeta> metas;
  final RideGroupStore store;
  final TourVisibilityKey visibility;

  @override
  ConsumerState<PlatzExtras> createState() => _PlatzExtrasState();
}

class _PlatzExtrasState extends ConsumerState<PlatzExtras> {
  List<RideGroup> _groups = const [];
  List<RideGroup> _public = const [];
  Map<String, List<RideGroupMember>> _members = const {};
  Map<String, bool> _localOptIn = const {};
  List<RouteCollection> _cols = const [];
  String? _joinErr;
  Set<String> _selfIds = {};
  bool _profileShareHint = false;
  String? _syncNote;
  bool _signedIn = true;

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

  bool get _listPublic => widget.visibility == TourVisibilityKey.sharedOnly;

  List<RideGroup> get _listedPublic {
    final mine = {for (final g in _groups) g.id};
    return [for (final g in _public) if (!mine.contains(g.id)) g];
  }

  List<RideGroup> get _mineVisible {
    switch (widget.visibility) {
      case TourVisibilityKey.allMine:
        return _groups;
      case TourVisibilityKey.privateOnly:
        return [
          for (final g in _groups)
            if (g.visibility == RideGroupVisibility.private) g,
        ];
      case TourVisibilityKey.sharedOnly:
        return [
          for (final g in _groups)
            if (g.visibility == RideGroupVisibility.public) g,
        ];
    }
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
    final profileOn = (await _selfProfileUrl()) != null;
    final pub = _listPublic ? await widget.store.publicGroups() : _public;
    if (!mounted) return;
    setState(() {
      _groups = groups;
      if (_listPublic) _public = pub;
      _members = members;
      _localOptIn = opt;
      _cols = cols;
      _selfIds = ids;
      _profileShareHint = profileOn;
      _syncNote = widget.store.lastNote;
    });
  }

  String _memberLine(RideGroupMember m, RideGroup g, AppLocalizations l10n) {
    final name = m.displayLabel.trim();
    final role = m.userId == g.hostUserId ? l10n.platzHost : l10n.platzGuest;
    final self = _selfIds.contains(m.userId) ? ' · ${l10n.platzYou}' : '';
    return name.isEmpty ? '$role$self' : '$name · $role$self';
  }

  Future<void> _checkSession() async {
    final state = await RideGroupCloud.sessionState();
    if (!mounted) return;
    setState(() => _signedIn = state != 'signedOut');
  }

  String _windowHint(RideGroup g, AppLocalizations l10n) {
    return RideGroupPolicy.formatWhen(g.startWindowStart, g.startWindowEnd);
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
        return DateTime(n.year, n.month, n.day, 10).add(const Duration(days: 1));
      default:
        return n;
    }
  }

  Future<void> _createGroup() async {
    if (!_signedIn) {
      if (!mounted) return;
      openAuthScreen(context);
      return;
    }
    final attachable = [
      for (final s in widget.saved)
        if (RideGroupPolicy.canAttachSaved(s, widget.metas[s.id])) s,
    ];
    if (attachable.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).platzNeedSharedTour),
        ),
      );
      return;
    }
    SavedRouteEntry chosen = attachable.first;
    var listing = RideGroupVisibility.private;
    var startPreset = 0;
    var durationH = 3;
    final meetingCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: HofThresholdNav.sheetBottomInset(ctx),
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              final loc = AppLocalizations.of(ctx);
              return Column(
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
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: chosen.id,
                    items: [
                      for (final s in attachable)
                        DropdownMenuItem(value: s.id, child: Text(s.name)),
                    ],
                    onChanged: (id) {
                      if (id == null) return;
                      setSheet(() {
                        chosen = attachable.firstWhere((s) => s.id == id);
                      });
                    },
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
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final e in [
                        (0, 'Jetzt'),
                        (1, 'In 1 h'),
                        (2, 'Heute 18:00'),
                        (3, 'Morgen 10:00'),
                      ])
                        ChoiceChip(
                          label: Text(e.$2),
                          selected: startPreset == e.$1,
                          onSelected: (_) =>
                              setSheet(() => startPreset = e.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dauer',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final h in [2, 3, 4])
                        ChoiceChip(
                          label: Text('$h h'),
                          selected: durationH == h,
                          onSelected: (_) => setSheet(() => durationH = h),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: meetingCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Treffpunkt (optional)',
                      hintText: 'Parkplatz Schwimmbad',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(loc.platzCreateGroup),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    final meeting = meetingCtrl.text.trim();
    meetingCtrl.dispose();
    if (created != true) return;
    final start = _startFromPreset(startPreset);
    final meta = widget.metas[chosen.id];
    try {
      final group = await widget.store.createGroup(
        savedRouteId: chosen.id,
        title: chosen.name,
        catalogTourId: catalogTourIdOf(chosen.id, meta ?? SavedRouteMeta.empty),
        meta: meta,
        displayLabel: await _selfLabel(),
        visibility: listing,
        windowStart: start,
        windowEnd: start.add(Duration(hours: durationH)),
        durationHours: durationH,
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
    unawaited(_applyJoin(pending.code, token: pending.token));
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
      if (out.group != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(out.message)),
        );
      }
    });
  }

  void _startRideFromGroup(RideGroup g) {
    final pending = startRidePendingIdForGroup(
      savedRouteId: g.savedRouteId,
      catalogTourId: g.catalogTourId,
      saved: widget.saved,
      metas: widget.metas,
    );
    ref.read(discoverLaunchModeProvider.notifier).state =
        DiscoverLaunchMode.mine;
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.karte;
    if (pending == null || pending.isEmpty) {
      _toast('Tour nicht in der Mappe — auf der Karte öffnen.');
      return;
    }
    ref.read(discoverPendingStartRideRouteIdProvider.notifier).state = pending;
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
    final token = RideGroupInvite.encode(g);
    final url = RideGroupInvite.httpsUrl(groupId: g.id, token: token);
    final appUrl = RideGroupInvite.customSchemeUrl(groupId: g.id, token: token);
    await SharePlus.instance.share(
      ShareParams(
        text: RideGroupInvite.shareText(
          title: g.title,
          url: url,
          appUrl: appUrl,
          profileUrl: await _selfProfileUrl(),
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

  Future<void> _leaveOrClose(RideGroup g) async {
    final host = _selfIds.contains(g.hostUserId);
    await widget.store.leaveGroup(g.id);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    _toast(
      widget.store.lastNote ??
          (host ? l10n.platzDissolve : l10n.platzLeave),
    );
  }

  Future<void> _copyInvite(RideGroup g) async {
    final token = RideGroupInvite.encode(g);
    final url = RideGroupInvite.httpsUrl(groupId: g.id, token: token);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    _toast(AppLocalizations.of(context).platzLinkCopied);
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

  @override
  Widget build(BuildContext context) {
    ref.listen<PlatzPendingJoin?>(platzPendingJoinProvider, (prev, next) {
      _consumePendingJoin(next);
    });
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 6),
          child: Text(
            l10n.platzTogetherKicker,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.muted,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.platzTogetherHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
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
              icon: Icon(_signedIn ? Icons.group_add : Icons.login, size: 18),
              label: Text(_signedIn ? l10n.platzCreateGroup : l10n.signIn),
            ),
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
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
        if (_mineVisible.isEmpty && !_listPublic)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              widget.visibility == TourVisibilityKey.privateOnly
                  ? l10n.platzNoPrivateGroups
                  : l10n.platzNoGroup,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          )
        else
          for (final g in _mineVisible)
            Card(
              key: Key('platz-group-${g.id}'),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            g.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _selfIds.contains(g.hostUserId)
                              ? l10n.platzHost
                              : l10n.platzGuest,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${g.visibility == RideGroupVisibility.public ? l10n.platzListedPublic : l10n.discoverPrivate} · '
                      '${l10n.platzMembersCount(_members[g.id]?.length ?? 0)} · '
                      '${_windowHint(g, l10n)}'
                      '${g.meetingPoint != null && g.meetingPoint!.isNotEmpty ? ' · ${g.meetingPoint}' : ''} · '
                      '${g.onServer ? l10n.platzOnServer : l10n.platzOnDevice}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    if ((_members[g.id] ?? const <RideGroupMember>[])
                        .isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          for (final m
                              in _members[g.id] ?? const <RideGroupMember>[])
                            _memberLine(m, g, l10n),
                        ].join('  ·  '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton(
                          key: Key('platz-group-invite-${g.id}'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => unawaited(_invite(g)),
                          child: Text(l10n.platzInvite),
                        ),
                        TextButton(
                          onPressed: () => unawaited(_leaveOrClose(g)),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(
                            _selfIds.contains(g.hostUserId)
                                ? l10n.platzDissolve
                                : l10n.platzLeave,
                          ),
                        ),
                        TextButton(
                          onPressed: () => unawaited(_copyInvite(g)),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Text(l10n.platzCopyLink),
                        ),
                        if (_selfIds.contains(g.hostUserId))
                          TextButton(
                            onPressed: () => unawaited(
                              widget.store.setVisibility(
                                g.id,
                                g.visibility == RideGroupVisibility.public
                                    ? RideGroupVisibility.private
                                    : RideGroupVisibility.public,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              g.visibility == RideGroupVisibility.public
                                  ? l10n.platzMakePrivate
                                  : l10n.platzMakePublic,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        FilterChip(
                          key: Key('platz-group-pins-${g.id}'),
                          selected: _localOptIn[g.id] ?? false,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            (_localOptIn[g.id] ?? false)
                                ? 'Pins an — HUD'
                                : 'Pins im HUD',
                          ),
                          onSelected: (on) => unawaited(
                            widget.store.setLiveOptIn(g.id, on),
                          ),
                        ),
                        FilledButton.tonal(
                          key: Key('platz-group-ride-${g.id}'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _startRideFromGroup(g),
                          child: const Text('Losfahren'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        if (_listPublic && _listedPublic.isEmpty && _mineVisible.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              l10n.platzNoPublicGroups,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
        if (_listPublic && _listedPublic.isNotEmpty) ...[
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
                      onPressed: () => unawaited(
                        _applyJoin(g.id, token: null),
                      ),
                      child: Text(l10n.platzJoin),
                    ),
                  ],
                ),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            l10n.platzCollectionsKicker,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.muted,
            ),
          ),
        ),
        if (_cols.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.platzNoCollection,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          )
        else
          for (final c in _cols)
            ListTile(
              title: Text(c.name),
              subtitle: Text(l10n.platzCollectionTours(c.routeIds.length)),
              trailing: TextButton(
                onPressed: () => unawaited(_shareCollection(c)),
                child: Text(l10n.share),
              ),
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: OutlinedButton(
            onPressed: () async {
              final now = DateTime.now();
              await RouteCollectionsStore.create(
                l10n.platzCollectionDefaultName(now.day, now.month),
              );
              await _reload();
            },
            child: Text(l10n.platzCreateCollection),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
