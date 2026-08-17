import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/user_profile_store.dart';
import '../../data/sync/sync_engine.dart'
    show SyncConflictException, SyncConflictStrategy;
import '../../domain/bike.dart';
import '../../domain/home/greeting.dart';
import '../../domain/ride.dart';
import '../../domain/rider_profile.dart';
import '../../domain/ai/coach_inbox.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../auth/auth_screen.dart';
import '../billing/upgrade_screen.dart';
import '../chat/chat_screen.dart';
import '../privacy/privacy_screen.dart';
import '../shell/shell_tabs.dart';
import 'hud_media_connection_tile.dart';
import 'public_profile_section.dart';

/// Profil: Identität + Aktivität (Komoot/AllTrails-Stil) oben, darunter
/// Fahrerdaten (View/Edit statt Dauer-Formular), Konto/Abo, Familie, Recht.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  String _style = 'flow';
  int _skill = 3;
  BikeCategory _discipline = BikeCategory.urban;

  /// Fahrerdaten sind standardmäßig eine Zusammenfassung (View), kein
  /// Dauer-Formular — wie Komoot/AllTrails „Profil bearbeiten" als
  /// bewusste Aktion, nicht als Default-Zustand. Siehe UX-Review.
  bool _editingRider = false;
  bool _ignoreChipToggle = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _weightCtrl = TextEditingController(text: '75');
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  List<String> get _styleIds {
    switch (_discipline) {
      case BikeCategory.road:
      case BikeCategory.gravel:
        return const ['efficient', 'flow', 'explorative'];
      case BikeCategory.urban:
      case BikeCategory.etrekking:
      case BikeCategory.cargo:
      case BikeCategory.folding:
      case BikeCategory.kids:
        return const ['efficient', 'explorative', 'flow'];
      case BikeCategory.mtbEnduro:
      case BikeCategory.dh:
        return const ['aggressive', 'flow', 'explorative'];
      case BikeCategory.emtb:
      case BikeCategory.mtbTrail:
      case BikeCategory.mtbAm:
      case BikeCategory.hiking:
        return const ['flow', 'aggressive', 'efficient', 'explorative'];
    }
  }

  List<({String id, String label})> _styleOptions(AppLocalizations l10n) {
    String labelFor(String id) {
      switch (_discipline) {
        case BikeCategory.road:
        case BikeCategory.gravel:
          return switch (id) {
            'efficient' => l10n.profileStyleEfficientPace,
            'flow' => l10n.profileStyleSteady,
            'explorative' => l10n.profileStyleExploring,
            _ => id,
          };
        case BikeCategory.urban:
        case BikeCategory.etrekking:
        case BikeCategory.cargo:
        case BikeCategory.folding:
        case BikeCategory.kids:
          return switch (id) {
            'efficient' => l10n.profileStyleCommute,
            'explorative' => l10n.profileStyleTours,
            'flow' => l10n.profileStyleRelaxed,
            _ => id,
          };
        case BikeCategory.mtbEnduro:
        case BikeCategory.dh:
          return switch (id) {
            'aggressive' => l10n.profileStyleAggressive,
            'flow' => l10n.profileStyleFlow,
            'explorative' => l10n.profileStyleLines,
            _ => id,
          };
        case BikeCategory.emtb:
        case BikeCategory.mtbTrail:
        case BikeCategory.mtbAm:
        case BikeCategory.hiking:
          return switch (id) {
            'flow' => l10n.profileStyleFlow,
            'aggressive' => l10n.profileStyleAggressive,
            'efficient' => l10n.profileStyleEfficient,
            'explorative' => l10n.profileStyleExploring,
            _ => id,
          };
      }
    }

    return [for (final id in _styleIds) (id: id, label: labelFor(id))];
  }

  Future<void> _load() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    if (!mounted) return;
    final styles = _styleIds.toSet();
    var style = store.riderProfile.style;
    if (!styles.contains(style)) style = _styleIds.first;
    setState(() {
      _nameCtrl.text = store.displayName ?? '';
      _weightCtrl.text = store.riderProfile.riderWeightKg.toStringAsFixed(0);
      _style = style;
      _skill = store.riderProfile.skillLevel;
      _discipline = store.preferredSport ?? BikeCategory.urban;
    });
  }

  /// Zentrale Rückmeldung — ersetzt das alte, leicht übersehene
  /// Dauer-Textfeld am Seitenende durch eine SnackBar (wie im Rest der App).
  void _notify(String text) {
    if (!mounted) return;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.m + bottom,
          ),
        ),
      );
  }

  String? _accessTokenOrNull() {
    if (!AppConfig.isSupabaseConfigured) return null;
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    final store = ref.read(userProfileStoreProvider);
    await store.setProfilePhoto(file.path);
    if (!mounted) return;
    setState(() {});
    _notify(AppLocalizations.of(context).profilePictureSet);
  }

  Future<void> _saveProfile() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    store.displayName =
        _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim();
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 75;
    await store.setRiderProfile(
      store.riderProfile.copyWith(
        style: _style,
        skillLevel: _skill,
        riderWeightKg: w,
      ),
    );
    await store.save();
    await ref.read(garageRepositoryProvider).touchLocalSync();
    if (!mounted) return;
    setState(() => _editingRider = false);
    ref.invalidate(riderProfileProvider);
    _notify(AppLocalizations.of(context).profileSaved);
  }

  void _cancelEditRider() {
    unawaited(_load());
    setState(() => _editingRider = false);
  }

  Future<void> _sync() async {
    final l10n = AppLocalizations.of(context);
    if (!AppConfig.isSupabaseConfigured || _accessTokenOrNull() == null) {
      _notify(l10n.profileLocalOnly);
      return;
    }
    setState(() => _busy = true);
    try {
      final engine = ref.read(syncEngineProvider);
      try {
        final r = await engine.syncNow(onConflict: SyncConflictStrategy.ask);
        _notify(
          r.direction == 'pulled'
              ? l10n.profileSyncCloudKept
              : r.direction == 'pushed'
                  ? l10n.profileSyncDeviceUploaded
                  : l10n.profileSyncCurrent,
        );
      } on SyncConflictException catch (c) {
        if (!mounted) return;
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final loc = AppLocalizations.of(ctx);
            return AlertDialog(
              title: Text(loc.profileSyncConflictTitle),
              content: Text(
                loc.profileSyncConflictBody(c.remoteUpdatedAt ?? '—'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'remote'),
                  child: Text(loc.profileKeepCloud),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'local'),
                  child: Text(loc.profileForceDevice),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(loc.cancel),
                ),
              ],
            );
          },
        );
        if (choice == 'remote' || choice == 'local') {
          final r = await engine.resolveConflict(
            conflict: c,
            keepLocal: choice == 'local',
          );
          _notify(
            r.direction == 'pulled'
                ? l10n.profileConflictCloud
                : l10n.profileConflictDevice,
          );
        } else {
          _notify(l10n.profileSyncCancelled);
        }
      }
    } catch (e) {
      _notify('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPortal() async {
    final l10n = AppLocalizations.of(context);
    final token = _accessTokenOrNull();
    if (token == null) {
      _notify(l10n.profileSignInForBilling);
      if (!mounted) return;
      openAuthScreen(context);
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/billing/portal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode != 200) {
        final body = jsonDecode(res.body);
        final map = body is Map ? body : const {};
        final code = map['error'] as String?;
        if (code == 'no_stripe_customer') {
          if (!mounted) return;
          openUpgradeScreen(context);
          return;
        }
        _notify(
          (map['message'] as String?) ??
              code ??
              l10n.profilePortalError(res.statusCode),
        );
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        _notify(l10n.profileNoPortalUrl);
        return;
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _notify('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFamilyRider() async {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '70');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.profileFamilyRiderTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: loc.profileName),
              ),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.profileWeightKg),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.add),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final riders = [...store.familyRiders];
    riders.add(
      FamilyRider(
        id: const Uuid().v4(),
        displayName: nameCtrl.text.trim().isEmpty
            ? l10n.profileRiderFallback
            : nameCtrl.text.trim(),
        weightKg: double.tryParse(weightCtrl.text) ?? 70,
      ),
    );
    await store.setFamilyRiders(riders);
    await ref.read(garageRepositoryProvider).touchLocalSync();
    if (!mounted) return;
    setState(() {});
    _notify(l10n.profileRiderAdded);
  }

  void _openStatsTarget() {
    ref.read(shellTabIndexProvider.notifier).state = ShellTabs.hof;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String? _garageVsDisciplineHint(
    List<Bike>? bikes,
    UserProfileStore store,
    AppLocalizations l10n,
  ) {
    if (bikes == null || bikes.isEmpty) return null;
    final preferred = store.preferredSport;
    if (preferred == null) return null;
    Bike? active;
    for (final b in bikes) {
      if (b.isActive) {
        active = b;
        break;
      }
    }
    active ??= bikes.first;
    if (active.category == preferred) return null;
    final brand = active.brand?.trim();
    final name = [
      if (brand != null && brand.isNotEmpty) brand,
      active.name,
    ].join(' ');
    return l10n.profileActiveBike(name, l10n.bikeCategoryShort(active.category));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final tier = ref.watch(subscriptionTierProvider);
    final store = ref.watch(userProfileStoreProvider);
    final bikesAsync = ref.watch(bikesProvider);
    final statsAsync = ref.watch(rideStatsProvider);
    final email = session?.user.email;
    final initials = avatarInitials(displayName: _nameCtrl.text, email: email);
    final photo = store.profilePhotoPath;
    final isPro = tier == 'pro';
    final l10n = AppLocalizations.of(context);
    final styleOptions = _styleOptions(l10n);

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.l,
          AppSpacing.xl,
          AppSpacing.xxxl + bottomInset,
        ),
        children: [
          _ProfileHeader(
            initials: initials,
            photo: photo,
            name: _nameCtrl.text.trim(),
            email: email,
            busy: _busy,
            onTapPhoto: _pickPhoto,
            onSignIn: () => openAuthScreen(context),
          ),
          const SizedBox(height: AppSpacing.l),
          _StatsRow(
            bikeCount: bikesAsync.valueOrNull?.length,
            rideCount: statsAsync.valueOrNull?.rideCount,
            totalKm: statsAsync.valueOrNull?.totalKm,
            totalElevationM: statsAsync.valueOrNull?.totalElevationM,
            distanceKnown: statsAsync.valueOrNull?.distanceKnown ?? true,
            onTap: _openStatsTarget,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SubscriptionCard(
            isPro: isPro,
            busy: _busy,
            onManage: _openPortal,
            onUpgrade: () => openUpgradeScreen(context),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Disziplin immer sichtbar — Kern für Multi-Sport-Defaults
          // (Touren-Profil, Home-Copy, Fahren-Fahrwerk).
          _SectionCard(
            title: l10n.profileDisciplines,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileDisciplinesHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    for (final d in _quickDisciplines)
                      _disciplineChip(store, d, l10n),
                  ],
                ),
                if (store.preferredSports.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    l10n.sportsSummaryLine(
                      primary: store.preferredSport,
                      sports: store.preferredSports,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: l10n.profileRiderCard,
            trailing: _editingRider
                ? null
                : TextButton(
                    onPressed: () => setState(() => _editingRider = true),
                    child: Text(l10n.edit),
                  ),
            child: _editingRider
                ? _RiderEditForm(
                    nameCtrl: _nameCtrl,
                    weightCtrl: _weightCtrl,
                    style: _style,
                    skill: _skill,
                    styleOptions: styleOptions,
                    busy: _busy,
                    onStyleChanged: (v) => setState(() => _style = v ?? _style),
                    onSkillChanged: (v) => setState(() => _skill = v.round()),
                    onCancel: _cancelEditRider,
                    onSave: _saveProfile,
                  )
                : _RiderSummary(
                    weightKg: double.tryParse(
                          _weightCtrl.text.replaceAll(',', '.'),
                        ) ??
                        75,
                    disciplineLabel: store.preferredSport != null
                        ? l10n.bikeCategoryShort(store.preferredSport!)
                        : '—',
                    alsoLabels: [
                      for (final s in store.preferredSports)
                        if (s != store.preferredSport) l10n.bikeCategoryShort(s),
                    ],
                    styleLabel: styleOptions
                        .firstWhere(
                          (s) => s.id == _style,
                          orElse: () => styleOptions.first,
                        )
                        .label,
                    skill: _skill,
                    activeBikeHint: _garageVsDisciplineHint(
                      bikesAsync.valueOrNull,
                      store,
                      l10n,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: l10n.profilePublic,
            child: const PublicProfileSection(),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: l10n.profileAccountSync,
            padded: false,
            child: Column(
              children: [
                const HudMediaConnectionTile(),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: Text(l10n.authSyncNow),
                  subtitle: session == null || !AppConfig.isSupabaseConfigured
                      ? Text(l10n.profileLocalOnly)
                      : null,
                  onTap: _busy ? null : _sync,
                ),
                ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: Text(session == null ? l10n.signIn : l10n.account),
                  subtitle: Text(
                    session == null
                        ? l10n.profileCloudBilling
                        : (email ?? l10n.profileSignedIn),
                  ),
                  onTap: () => openAuthScreen(context),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(l10n.chatAssistant),
                  subtitle: Builder(
                    builder: (context) {
                      final unread = unreadCoachCount(
                        ref.watch(coachWatchProvider).valueOrNull ?? const [],
                      );
                      return Text(
                        unread > 0
                            ? l10n.coachHintsTooltip(unread)
                            : l10n.chatSubtitleDue,
                      );
                    },
                  ),
                  trailing: Builder(
                    builder: (context) {
                      final unread = unreadCoachCount(
                        ref.watch(coachWatchProvider).valueOrNull ?? const [],
                      );
                      if (unread <= 0) return const Icon(Icons.chevron_right);
                      return Badge(
                        label: Text('$unread'),
                        child: const Icon(Icons.chevron_right),
                      );
                    },
                  ),
                  onTap: () => openChatScreen(context),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.authPrivacy),
                  onTap: () => openPrivacyScreen(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: l10n.profileFamilyGarage,
            trailing: TextButton(
              onPressed: _addFamilyRider,
              child: Text(l10n.add),
            ),
            child: store.familyRiders.isEmpty
                ? Text(
                    l10n.profileFamilyHint,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
                  )
                : Column(
                    children: [
                      for (final r in store.familyRiders)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          selected: store.activeFamilyRiderId == r.id,
                          leading: Icon(
                            store.activeFamilyRiderId == r.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: store.activeFamilyRiderId == r.id
                                ? AppColors.accent
                                : AppColors.muted,
                          ),
                          title: Text(r.displayName),
                          subtitle: Text('${r.weightKg.toStringAsFixed(0)} kg'),
                          onTap: () async {
                            await store.setActiveFamilyRider(
                              store.activeFamilyRiderId == r.id ? null : r.id,
                            );
                            setState(() {});
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await store.load();
                              await store.setFamilyRiders(
                                store.familyRiders
                                    .where((x) => x.id != r.id)
                                    .toList(),
                              );
                              setState(() {});
                            },
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          // Rechtliches bewusst als schmales Kleingedrucktes — wie bei
          // Komoot/AllTrails am Seitenende, nicht als gleichwertiger
          // Abschnitt neben Fahrerprofil/Abo.
          Text(
            l10n.profileLegal,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.m,
            runSpacing: AppSpacing.xs,
            children: [
              _LegalLink(l10n.profilePrivacyPolicy, AppConfig.privacyPolicyUrl),
              _LegalLink(l10n.profileImprint, AppConfig.impressumUrl),
              _LegalLink(l10n.profileWithdrawal, AppConfig.widerrufUrl),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }

  static const _quickDisciplines = <BikeCategory>[
    BikeCategory.urban,
    BikeCategory.cargo,
    BikeCategory.folding,
    BikeCategory.kids,
    BikeCategory.etrekking,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.emtb,
    BikeCategory.mtbTrail,
    BikeCategory.mtbAm,
    BikeCategory.mtbEnduro,
  ];

  Widget _disciplineChip(
    UserProfileStore store,
    BikeCategory d,
    AppLocalizations l10n,
  ) {
    final selected = store.prefersSport(d);
    final isPrimary = store.preferredSport == d;
    return FilterChip(
      showCheckmark: false,
      selected: selected,
      selectedColor: AppColors.accent.withValues(alpha: 0.28),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.accent : AppColors.chipIdleText,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            GestureDetector(
              onTap: _busy || isPrimary
                  ? null
                  : () {
                      _ignoreChipToggle = true;
                      unawaited(
                        _setPrimaryDiscipline(d).whenComplete(() {
                          _ignoreChipToggle = false;
                        }),
                      );
                    },
              child: Tooltip(
                message: l10n.profileSetPrimary,
                child: Icon(
                  isPrimary ? Icons.star : Icons.star_border,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            isPrimary
                ? l10n.profilePrimarySuffix(l10n.bikeCategoryShort(d))
                : l10n.bikeCategoryShort(d),
          ),
        ],
      ),
      onSelected: _busy
          ? null
          : (_) {
              if (_ignoreChipToggle) return;
              unawaited(_onDisciplineChipTap(d));
            },
    );
  }

  Future<void> _onDisciplineChipTap(BikeCategory d) async {
    final store = ref.read(userProfileStoreProvider);
    if (store.prefersSport(d)) {
      if (store.preferredSport == d) {
        _notify(AppLocalizations.of(context).profileNeedOneDiscipline);
        return;
      }
      store.togglePreferredSport(d);
    } else {
      store.togglePreferredSport(d);
    }
    _syncDisciplineStyle(store.preferredSport ?? d);
    await _persistDisciplines();
  }

  Future<void> _setPrimaryDiscipline(BikeCategory d) async {
    final store = ref.read(userProfileStoreProvider);
    if (store.preferredSport == d) return;
    store.setPrimarySport(d);
    _syncDisciplineStyle(d);
    await _persistDisciplines();
  }

  void _syncDisciplineStyle(BikeCategory d) {
    setState(() {
      _discipline = d;
      if (!_styleIds.contains(_style)) {
        _style = _styleIds.first;
      }
    });
  }

  Future<void> _persistDisciplines() async {
    final store = ref.read(userProfileStoreProvider);
    await store.setRiderProfile(
      store.riderProfile.copyWith(style: _style, skillLevel: _skill),
    );
    await store.save();
    await ref.read(garageRepositoryProvider).touchLocalSync();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ref.invalidate(riderProfileProvider);
    final parts = [
      for (final s in store.preferredSports)
        s == store.preferredSport
            ? l10n.profilePrimarySuffix(l10n.bikeCategoryShort(s))
            : l10n.bikeCategoryShort(s),
    ];
    _notify(l10n.profileDisciplinesSaved(parts.join(', ')));
  }
}

/// Kopf: Avatar + Name + Sync-Status — Identität, wie bei Komoot/AllTrails.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.photo,
    required this.name,
    required this.email,
    required this.busy,
    required this.onTapPhoto,
    required this.onSignIn,
  });

  final String initials;
  final String? photo;
  final String name;
  final String? email;
  final bool busy;
  final VoidCallback onTapPhoto;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPhoto = photo != null &&
        (photo!.startsWith('http') || File(photo!).existsSync());
    return Row(
      children: [
        InkWell(
          onTap: busy ? null : onTapPhoto,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.trail,
            backgroundImage: hasPhoto
                ? (photo!.startsWith('http')
                    ? NetworkImage(photo!)
                    : FileImage(File(photo!)) as ImageProvider)
                : null,
            child: hasPhoto
                ? null
                : (initials == '?'
                    ? const Icon(Icons.person_outline,
                        color: Colors.white, size: 32)
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      )),
          ),
        ),
        const SizedBox(width: AppSpacing.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? l10n.profileRiderCard : name,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              if (email != null)
                Text(
                  email!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                )
              else
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.s,
                  children: [
                    Text(
                      l10n.profileLocalUntilSignIn,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: busy ? null : onSignIn,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l10n.signIn),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: busy ? null : onTapPhoto,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.profileChangePhoto),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aktivitäts-Kennzahlen — die Zeile, die Komoot/AllTrails haben und
/// FlowLine bisher nicht: bestätigt „ich habe hier eine Geschichte",
/// nutzt Daten, die die App längst hat (Garage-Odometer, Ride-Log).
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    this.bikeCount,
    this.rideCount,
    this.totalKm,
    this.totalElevationM,
    this.distanceKnown = true,
    this.onTap,
  });

  final int? bikeCount;
  final int? rideCount;
  final double? totalKm;
  final double? totalElevationM;
  final bool distanceKnown;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rides = rideCount ?? 0;
    final kmLabel = totalKm == null
        ? '–'
        : formatProfileDistanceKm(
            rideCount: rides,
            totalKm: totalKm!,
            distanceKnown: distanceKnown,
          );
    final hm = totalElevationM ?? 0;
    final kmCaption =
        hm >= 1 ? l10n.profileKmElevation(hm.round()) : l10n.profileKmTotal;
    return Semantics(
      button: onTap != null,
      label: l10n.profileActivityLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                value: bikeCount?.toString() ?? '–',
                label: bikeCount == 1 ? l10n.profileBikeOne : l10n.profileBikes,
              ),
            ),
            Container(width: 1, height: 32, color: AppColors.border),
            Expanded(
              child: _StatTile(
                value: rideCount?.toString() ?? '–',
                label: rideCount == 1 ? l10n.profileRideOne : l10n.profileRides,
              ),
            ),
            Container(width: 1, height: 32, color: AppColors.border),
            Expanded(
              child: _StatTile(
                value: kmLabel,
                label: kmCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Abo-Karte mit Zustands-abhängigem Gewicht: Free = auffällige
/// Upsell-Karte (Konversion), Pro = ruhige Einzeiler-Zeile („schon
/// gewonnen" — nicht dieselbe visuelle Lautstärke wie der Verkaufsversuch).
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.isPro,
    required this.busy,
    required this.onManage,
    required this.onUpgrade,
  });

  final bool isPro;
  final bool busy;
  final VoidCallback onManage;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        decoration: BoxDecoration(
          color: AppColors.chipIdle,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                l10n.profileProActive,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: busy ? null : onManage,
              child: Text(l10n.profileManage),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.accent),
              const SizedBox(width: AppSpacing.s),
              Text(
                l10n.billingTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.profileProPerks,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton(
            onPressed: onUpgrade,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chrome,
              minimumSize: const Size.fromHeight(44),
            ),
            child: Text(l10n.profileUpgradePro),
          ),
        ],
      ),
    );
  }
}

/// Gemeinsamer Karten-Rahmen für Profil-Abschnitte — ersetzt den
/// unstrukturierten Ein-Listen-Flow des alten Screens.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.padded = true,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  /// false für reine Listen (Konto & Sync) — die ListTiles bringen ihr
  /// eigenes Innenpadding mit, doppeltes Padding würde sie einrücken.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padded ? AppSpacing.l : 0,
        vertical: AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: AppColors.chipIdle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: padded ? 0 : AppSpacing.l,
              right: padded ? 0 : AppSpacing.l,
              bottom: AppSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padded ? 0 : 0),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// View-Zustand des Fahrerprofils — die Standardansicht. Bearbeiten ist
/// eine bewusste Aktion (Button oben rechts), kein Dauerzustand.
class _RiderSummary extends StatelessWidget {
  const _RiderSummary({
    required this.weightKg,
    required this.disciplineLabel,
    required this.alsoLabels,
    required this.styleLabel,
    required this.skill,
    this.activeBikeHint,
  });

  final double weightKg;
  final String disciplineLabel;
  final List<String> alsoLabels;
  final String styleLabel;
  final int skill;
  final String? activeBikeHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final skillLabel = switch (skill.clamp(1, 5)) {
      1 => l10n.profileSkillBeginner,
      2 => l10n.profileSkillBasics,
      3 => l10n.profileSkillAdvanced,
      4 => l10n.profileSkillExperienced,
      _ => l10n.profileSkillPro,
    };
    final sub = [
      if (alsoLabels.isNotEmpty) l10n.profileAlsoList(alsoLabels.join(', ')),
      styleLabel,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(
          icon: Icons.pedal_bike,
          label: disciplineLabel,
          sub: sub,
        ),
        if (activeBikeHint != null && activeBikeHint!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s),
          _SummaryRow(
            icon: Icons.two_wheeler,
            label: activeBikeHint!,
            sub: l10n.profileSubGarage,
          ),
        ],
        const SizedBox(height: AppSpacing.s),
        _SummaryRow(
          icon: Icons.monitor_weight_outlined,
          label: '${weightKg.toStringAsFixed(0)} kg',
          sub: l10n.profileSubWeight,
        ),
        const SizedBox(height: AppSpacing.s),
        _SummaryRow(
          icon: Icons.trending_up,
          label: skillLabel,
          sub: l10n.profileSubSkill(skill),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.icon, required this.label, required this.sub});
  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: AppSpacing.s),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' · $sub',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Edit-Zustand — dieselben Felder wie vorher, jetzt mit klarem
/// Abbrechen/Speichern statt eines einzelnen, jederzeit aktiven Formulars.
class _RiderEditForm extends StatelessWidget {
  const _RiderEditForm({
    required this.nameCtrl,
    required this.weightCtrl,
    required this.style,
    required this.skill,
    required this.styleOptions,
    required this.busy,
    required this.onStyleChanged,
    required this.onSkillChanged,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController nameCtrl;
  final TextEditingController weightCtrl;
  final String style;
  final int skill;
  final List<({String id, String label})> styleOptions;
  final bool busy;
  final ValueChanged<String?> onStyleChanged;
  final ValueChanged<double> onSkillChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameCtrl,
          decoration: InputDecoration(labelText: l10n.profileDisplayName),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: weightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.profileRiderWeight),
        ),
        const SizedBox(height: AppSpacing.m),
        DropdownButtonFormField<String>(
          initialValue: styleOptions.any((e) => e.id == style)
              ? style
              : styleOptions.first.id,
          decoration: InputDecoration(labelText: l10n.profileRideStyle),
          dropdownColor: AppColors.surfaceDark,
          items: [
            for (final s in styleOptions)
              DropdownMenuItem(value: s.id, child: Text(s.label)),
          ],
          onChanged: onStyleChanged,
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.profileSkillBeginner,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            Text(l10n.profileSkillPro,
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        Slider(
          value: skill.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          label: '$skill / 5',
          onChanged: onSkillChanged,
        ),
        const SizedBox(height: AppSpacing.s),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: busy ? null : onCancel,
                child: Text(l10n.cancel),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: FilledButton(
                onPressed: busy ? null : onSave,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.label, this.url);
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.muted,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

void openProfileScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
  );
}

Future<void> openPrivacyScreen(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
  );
}
