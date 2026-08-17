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
import '../../data/routing/saved_route_meta_store.dart';
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
import '../profile/profile_screen.dart';
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
    this.onOpenAkte,
  });

  final List<SavedRouteEntry> saved;
  final Map<String, SavedRouteMeta> metas;
  final RideGroupStore store;
  final TourVisibilityKey visibility;
  final Future<void> Function(SavedRouteEntry)? onOpenAkte;

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
  String? _syncNote;
  bool _signedIn = true;
  bool _collectionsOpen = false;
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

  /// Offene Gruppen anderer: nur unter Chip „Freigegeben“.
  bool get _listPublic => widget.visibility == TourVisibilityKey.sharedOnly;

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
    final pub = _listPublic ? await widget.store.publicGroups() : _public;
    if (!mounted) return;
    setState(() {
      _groups = groups;
      if (_listPublic) _public = pub;
      _members = members;
      _localOptIn = opt;
      _cols = cols;
      _selfIds = ids;
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
        return DateTime(n.year, n.month, n.day, 10)
            .add(const Duration(days: 1));
      default:
        return n;
    }
  }

  Future<SavedRouteEntry?> _promptShareTourFirst() async {
    final l10n = AppLocalizations.of(context);
    final locked = [
      for (final s in widget.saved)
        if (!RideGroupPolicy.canAttachSaved(s, widget.metas[s.id])) s,
    ];
    if (locked.isEmpty) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.platzNeedSharedTour)),
      );
      return null;
    }
    final chosen = await showModalBottomSheet<SavedRouteEntry>(
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
            bottom: HofThresholdNav.sheetBottomInset(ctx),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                loc.platzShareTourFirst,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                loc.platzShareTourFirstHint,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              for (final s in locked.take(8))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.name),
                  subtitle: Text(loc.discoverPrivate),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.pop(ctx, s),
                ),
            ],
          ),
        );
      },
    );
    return chosen;
  }

  Future<void> _createGroup() async {
    if (!_signedIn) {
      if (!mounted) return;
      openAuthScreen(context);
      return;
    }
    var attachable = [
      for (final s in widget.saved)
        if (RideGroupPolicy.canAttachSaved(s, widget.metas[s.id])) s,
    ];
    if (attachable.isEmpty) {
      final pending = await _promptShareTourFirst();
      if (pending == null || !mounted) return;
      await widget.onOpenAkte?.call(pending);
      if (!mounted) return;
      final meta = await SavedRouteMetaStore.get(pending.id);
      if (!mounted) return;
      if (!RideGroupPolicy.canAttachSaved(pending, meta)) return;
      attachable = [pending];
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
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
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
                      ])
                        ChoiceChip(
                          label: Text(e.$2),
                          selected: startPreset == e.$1,
                          onSelected: (_) => setSheet(() => startPreset = e.$1),
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
                      Navigator.pop(ctx, true);
                    },
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
    Future<void>.delayed(
        const Duration(milliseconds: 600), meetingCtrl.dispose);
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

  Future<void> _joinWithLink() async {
    final pasted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlatzJoinSheet(signedIn: _signedIn),
    );
    if (pasted == null || !mounted) return;
    final parsed = RideGroupInvite.parsePastedJoin(pasted);
    if (parsed == null) {
      setState(() => _joinErr = AppLocalizations.of(context).platzJoinInvalid);
      return;
    }
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
      if (out.group != null) {
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
    final token = RideGroupInvite.encode(g);
    final url = RideGroupInvite.httpsUrl(groupId: g.id, token: token);
    final appUrl = RideGroupInvite.customSchemeUrl(groupId: g.id, token: token);
    await SharePlus.instance.share(
      ShareParams(
        text: RideGroupInvite.shareText(
          title: g.title,
          url: url,
          appUrl: appUrl,
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
                icon: Icon(_signedIn ? Icons.group_add : Icons.login, size: 18),
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
                    if (!g.onServer) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.platzHostCannotSee,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                        ),
                      ),
                      if (!_signedIn)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton(
                            onPressed: () => openAuthScreen(context),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(l10n.signIn),
                          ),
                        ),
                    ],
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
                        if (_selfIds.contains(g.hostUserId))
                          FilledButton(
                            key: Key('platz-group-invite-${g.id}'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => unawaited(_invite(g)),
                            child: Text(l10n.platzInvite),
                          )
                        else
                          FilledButton(
                            key: Key('platz-group-ride-${g.id}'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () =>
                                unawaited(_startRideFromGroup(g)),
                            child: Text(l10n.goRide),
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
                        if (_selfIds.contains(g.hostUserId) || g.onServer)
                          TextButton(
                            onPressed: () => unawaited(_copyInvite(g)),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(l10n.platzCopyLink),
                          ),
                        if (_selfIds.contains(g.hostUserId))
                          TextButton(
                            onPressed: () => unawaited(_toggleListing(g)),
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
                    if (_selfIds.contains(g.hostUserId) || g.onServer) ...[
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
                                  ? l10n.platzPinsOnHud
                                  : l10n.platzPinsOff,
                            ),
                            onSelected: (on) =>
                                unawaited(_setPins(g.id, on)),
                          ),
                          if (_selfIds.contains(g.hostUserId))
                            FilledButton.tonal(
                              key: Key('platz-group-ride-${g.id}'),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () =>
                                  unawaited(_startRideFromGroup(g)),
                              child: Text(l10n.goRide),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.platzPinsHint,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
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
                      child: Text(
                        _signedIn ? l10n.platzJoin : l10n.platzJoinLocalCta,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (_cols.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
            child: PlatzFoldHeader(
              label: l10n.platzCollectionsKicker,
              count: _cols.length,
              expanded: _collectionsOpen,
              onTap: () =>
                  setState(() => _collectionsOpen = !_collectionsOpen),
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
                title: Text(c.name),
                subtitle: Text(l10n.platzCollectionTours(c.routeIds.length)),
                trailing: TextButton(
                  onPressed: () => unawaited(_shareCollection(c)),
                  child: Text(l10n.share),
                ),
              ),
          ],
        ],
        const SizedBox(height: 48),
      ],
    );
  }
}

class _PlatzJoinSheet extends StatefulWidget {
  const _PlatzJoinSheet({required this.signedIn});

  final bool signedIn;

  @override
  State<_PlatzJoinSheet> createState() => _PlatzJoinSheetState();
}

class _PlatzJoinSheetState extends State<_PlatzJoinSheet> {
  late final TextEditingController _ctrl;
  String? _err;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final loc = AppLocalizations.of(context);
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _err = loc.platzJoinEmpty);
      return;
    }
    if (RideGroupInvite.parsePastedJoin(raw) == null) {
      setState(() => _err = loc.platzJoinInvalid);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, raw);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: HofThresholdNav.sheetBottomInset(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.platzJoinWithCode,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.platzJoinLinkHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          if (!widget.signedIn) ...[
            const SizedBox(height: 8),
            Text(
              loc.platzJoinUnsignedHint,
              style: const TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('platz-join-field'),
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: loc.platzJoinCodeField,
              isDense: true,
              errorText: _err,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('platz-join-submit'),
            onPressed: _submit,
            child: Text(
              widget.signedIn ? loc.platzJoin : loc.platzJoinLocalCta,
            ),
          ),
        ],
      ),
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
  });

  final String label;
  final int? count;
  final bool expanded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = count == null ? label : '$label · $count';
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: AppColors.muted,
    );
    if (onTap == null) {
      return Text(text, style: style);
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(text, style: style)),
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
