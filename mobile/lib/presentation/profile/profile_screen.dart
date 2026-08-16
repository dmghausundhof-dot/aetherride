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
import '../../data/sync/sync_engine.dart'
    show SyncConflictException, SyncConflictStrategy;
import '../../domain/bike.dart';
import '../../domain/home/greeting.dart';
import '../../domain/rider_profile.dart';
import '../../domain/sport/discipline_ux.dart';
import '../../providers/app_providers.dart';
import '../auth/auth_screen.dart';
import '../billing/upgrade_screen.dart';
import '../chat/chat_screen.dart';
import '../privacy/privacy_screen.dart';

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

  List<({String id, String label})> get _styleOptions {
    switch (_discipline) {
      case BikeCategory.road:
      case BikeCategory.gravel:
        return const [
          (id: 'efficient', label: 'Effizient / Tempo'),
          (id: 'flow', label: 'Gleichmäßig'),
          (id: 'explorative', label: 'Entdeckend'),
        ];
      case BikeCategory.urban:
      case BikeCategory.etrekking:
      case BikeCategory.cargo:
      case BikeCategory.folding:
      case BikeCategory.kids:
        return const [
          (id: 'efficient', label: 'Alltag / Pendeln'),
          (id: 'explorative', label: 'Touren'),
          (id: 'flow', label: 'Locker'),
        ];
      case BikeCategory.mtbEnduro:
      case BikeCategory.dh:
        return const [
          (id: 'aggressive', label: 'Aggressiv'),
          (id: 'flow', label: 'Flow'),
          (id: 'explorative', label: 'Linien suchen'),
        ];
      case BikeCategory.emtb:
      case BikeCategory.mtbTrail:
      case BikeCategory.mtbAm:
      case BikeCategory.hiking:
        return const [
          (id: 'flow', label: 'Flow'),
          (id: 'aggressive', label: 'Aggressiv'),
          (id: 'efficient', label: 'Effizient'),
          (id: 'explorative', label: 'Entdeckend'),
        ];
    }
  }

  Future<void> _load() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    if (!mounted) return;
    final styles = _styleOptions.map((e) => e.id).toSet();
    var style = store.riderProfile.style;
    if (!styles.contains(style)) style = _styleOptions.first.id;
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    if (mounted) setState(() {});
    _notify('Profilbild gesetzt');
  }

  Future<void> _saveProfile() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    store.displayName =
        _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim();
    store.preferredSport = _discipline;
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
    if (mounted) {
      setState(() => _editingRider = false);
      ref.invalidate(riderProfileProvider);
    }
    _notify('Profil gespeichert');
  }

  void _cancelEditRider() {
    unawaited(_load());
    setState(() => _editingRider = false);
  }

  Future<void> _sync() async {
    setState(() => _busy = true);
    try {
      final engine = ref.read(syncEngineProvider);
      try {
        final r = await engine.syncNow(onConflict: SyncConflictStrategy.ask);
        _notify(
          r.direction == 'pulled'
              ? 'Sync: Cloud übernommen'
              : r.direction == 'pushed'
                  ? 'Sync: Gerät hochgeladen'
                  : 'Sync: aktuell',
        );
      } on SyncConflictException catch (c) {
        if (!mounted) return;
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sync-Konflikt'),
            content: Text(
              'Cloud und dieses Gerät unterscheiden sich.\n'
              'Cloud: ${c.remoteUpdatedAt ?? "—"}\n\n'
              'Welche Version soll gelten?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'remote'),
                child: const Text('Cloud behalten'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'local'),
                child: const Text('Gerät erzwingen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen'),
              ),
            ],
          ),
        );
        if (choice == 'remote' || choice == 'local') {
          final r = await engine.resolveConflict(
            conflict: c,
            keepLocal: choice == 'local',
          );
          _notify(
            r.direction == 'pulled'
                ? 'Konflikt: Cloud behalten'
                : 'Konflikt: Gerät erzwungen',
          );
        } else {
          _notify('Sync abgebrochen');
        }
      }
    } catch (e) {
      _notify('$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPortal() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _notify('Bitte anmelden für Aboverwaltung');
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
        final err = body is Map
            ? (body['message'] as String? ?? body['error'] as String?)
            : null;
        _notify(
          err == 'no_stripe_customer'
              ? 'Noch kein Stripe-Abo — zuerst Pro upgraden.'
              : (err ?? 'Portal: ${res.statusCode}'),
        );
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        _notify('Keine Portal-URL');
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
      builder: (ctx) => AlertDialog(
        title: const Text('Familien-Fahrer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gewicht kg'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbruch'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    final riders = [...store.familyRiders];
    riders.add(
      FamilyRider(
        id: const Uuid().v4(),
        displayName:
            nameCtrl.text.trim().isEmpty ? 'Fahrer' : nameCtrl.text.trim(),
        weightKg: double.tryParse(weightCtrl.text) ?? 70,
      ),
    );
    await store.setFamilyRiders(riders);
    await ref.read(garageRepositoryProvider).touchLocalSync();
    if (mounted) setState(() {});
    _notify('Fahrer hinzugefügt');
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.l,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          _ProfileHeader(
            initials: initials,
            photo: photo,
            name: _nameCtrl.text.trim(),
            email: email,
            busy: _busy,
            onTapPhoto: _pickPhoto,
          ),
          const SizedBox(height: AppSpacing.l),
          _StatsRow(
            bikeCount: bikesAsync.valueOrNull?.length,
            rideCount: statsAsync.valueOrNull?.rideCount,
            totalKm: statsAsync.valueOrNull?.totalKm,
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
            title: 'Deine Disziplin',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Steuert Touren-Vorschläge, Routing und Setup-Hinweise.',
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
                      ChoiceChip(
                        label: Text(d.shortLabel),
                        selected: _discipline == d,
                        selectedColor:
                            AppColors.accent.withValues(alpha: 0.28),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _discipline == d
                              ? AppColors.accent
                              : AppColors.chipIdleText,
                        ),
                        onSelected: _busy
                            ? null
                            : (_) => unawaited(_setDisciplineQuick(d)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: 'Fahrerprofil',
            trailing: _editingRider
                ? null
                : TextButton(
                    onPressed: () => setState(() => _editingRider = true),
                    child: const Text('Bearbeiten'),
                  ),
            child: _editingRider
                ? _RiderEditForm(
                    nameCtrl: _nameCtrl,
                    weightCtrl: _weightCtrl,
                    discipline: _discipline,
                    style: _style,
                    skill: _skill,
                    styleOptions: _styleOptions,
                    busy: _busy,
                    onDisciplineChanged: (d) => setState(() {
                      _discipline = d;
                      final ids = _styleOptions.map((e) => e.id).toSet();
                      if (!ids.contains(_style)) {
                        _style = _styleOptions.first.id;
                      }
                    }),
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
                    discipline: _discipline,
                    disciplineLabel: _discipline.shortLabel,
                    styleLabel: _styleOptions
                        .firstWhere(
                          (s) => s.id == _style,
                          orElse: () => _styleOptions.first,
                        )
                        .label,
                    skill: _skill,
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: 'Konto & Sync',
            padded: false,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Jetzt synchronisieren'),
                  onTap: _busy ? null : _sync,
                ),
                ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: Text(session == null ? 'Anmelden' : 'Konto'),
                  subtitle: Text(
                    session == null
                        ? 'Cloud-Sync & Abo'
                        : (email ?? 'Angemeldet'),
                  ),
                  onTap: () => openAuthScreen(context),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Assistent'),
                  onTap: () => openChatScreen(context),
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Daten & Privatsphäre'),
                  onTap: () => openPrivacyScreen(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionCard(
            title: 'Familien-Garage',
            trailing: TextButton(
              onPressed: _addFamilyRider,
              child: const Text('Hinzufügen'),
            ),
            child: store.familyRiders.isEmpty
                ? const Text(
                    'Weitere Fahrer mit eigenem Gewicht — z. B. Partner oder Kind.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
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
            'Rechtliches',
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
              _LegalLink('Datenschutz', AppConfig.privacyPolicyUrl),
              _LegalLink('Impressum', AppConfig.impressumUrl),
              _LegalLink('Widerruf', AppConfig.widerrufUrl),
            ],
          ),
        ],
      ),
    );
  }

  static const _quickDisciplines = <BikeCategory>[
    BikeCategory.urban,
    BikeCategory.etrekking,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.emtb,
    BikeCategory.mtbTrail,
    BikeCategory.mtbAm,
    BikeCategory.mtbEnduro,
  ];

  Future<void> _setDisciplineQuick(BikeCategory d) async {
    setState(() {
      _discipline = d;
      final ids = _styleOptions.map((e) => e.id).toSet();
      if (!ids.contains(_style)) {
        _style = _styleOptions.first.id;
      }
    });
    final store = ref.read(userProfileStoreProvider);
    store.preferredSport = d;
    await store.setRiderProfile(
      store.riderProfile.copyWith(style: _style, skillLevel: _skill),
    );
    await store.save();
    await ref.read(garageRepositoryProvider).touchLocalSync();
    if (mounted) {
      ref.invalidate(riderProfileProvider);
      _notify('Disziplin: ${d.shortLabel}');
    }
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
  });

  final String initials;
  final String? photo;
  final String name;
  final String? email;
  final bool busy;
  final VoidCallback onTapPhoto;

  @override
  Widget build(BuildContext context) {
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
                : Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Fahrerprofil' : name,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                email ?? 'Lokal — Sync nach Anmeldung',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: busy ? null : onTapPhoto,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Foto ändern'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Aktivitäts-Kennzahlen — die Zeile, die Komoot/AllTrails haben und
/// AetherRide bisher nicht: bestätigt „ich habe hier eine Geschichte",
/// nutzt Daten, die die App längst hat (Garage-Odometer, Ride-Log).
class _StatsRow extends StatelessWidget {
  const _StatsRow({this.bikeCount, this.rideCount, this.totalKm});

  final int? bikeCount;
  final int? rideCount;
  final double? totalKm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: bikeCount?.toString() ?? '–',
            label: bikeCount == 1 ? 'Bike' : 'Bikes',
          ),
        ),
        Container(width: 1, height: 32, color: AppColors.border),
        Expanded(
          child: _StatTile(
            value: rideCount?.toString() ?? '–',
            label: rideCount == 1 ? 'Ride' : 'Rides',
          ),
        ),
        Container(width: 1, height: 32, color: AppColors.border),
        Expanded(
          child: _StatTile(
            value: totalKm == null ? '–' : totalKm!.round().toString(),
            label: 'km gesamt',
          ),
        ),
      ],
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
            const Expanded(
              child: Text(
                'AetherRide Pro aktiv',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: busy ? null : onManage,
              child: const Text('Verwalten'),
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
              const Text(
                'AetherRide Pro',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Offline-Karten, unbegrenzte Bikes, Fahrwerksanalyse & Bracketing.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton(
            onPressed: onUpgrade,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forestOnDark,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Pro upgraden'),
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
    required this.discipline,
    required this.disciplineLabel,
    required this.styleLabel,
    required this.skill,
  });

  final double weightKg;
  final BikeCategory discipline;
  final String disciplineLabel;
  final String styleLabel;
  final int skill;

  @override
  Widget build(BuildContext context) {
    const skillLabels = [
      '',
      'Einsteiger',
      'Grundlagen',
      'Fortgeschritten',
      'Erfahren',
      'Profi'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(
            icon: Icons.pedal_bike, label: disciplineLabel, sub: styleLabel),
        const SizedBox(height: AppSpacing.s),
        _SummaryRow(
          icon: Icons.monitor_weight_outlined,
          label: '${weightKg.toStringAsFixed(0)} kg',
          sub: 'Fahrergewicht',
        ),
        const SizedBox(height: AppSpacing.s),
        _SummaryRow(
          icon: Icons.trending_up,
          label: skillLabels[skill.clamp(1, 5)],
          sub: 'Können ($skill / 5)',
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: AppSpacing.xs),
        Text('· $sub',
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
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
    required this.discipline,
    required this.style,
    required this.skill,
    required this.styleOptions,
    required this.busy,
    required this.onDisciplineChanged,
    required this.onStyleChanged,
    required this.onSkillChanged,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController nameCtrl;
  final TextEditingController weightCtrl;
  final BikeCategory discipline;
  final String style;
  final int skill;
  final List<({String id, String label})> styleOptions;
  final bool busy;
  final ValueChanged<BikeCategory> onDisciplineChanged;
  final ValueChanged<String?> onStyleChanged;
  final ValueChanged<double> onSkillChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  static const _disciplines = [
    BikeCategory.urban,
    BikeCategory.etrekking,
    BikeCategory.gravel,
    BikeCategory.road,
    BikeCategory.emtb,
    BikeCategory.mtbTrail,
    BikeCategory.mtbAm,
    BikeCategory.mtbEnduro,
  ];

  static String _label(BikeCategory c) => c.shortLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Anzeigename'),
        ),
        const SizedBox(height: AppSpacing.s),
        TextField(
          controller: weightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Fahrergewicht (kg)'),
        ),
        const SizedBox(height: AppSpacing.m),
        const Text(
          'Disziplin',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final d in _disciplines)
              ChoiceChip(
                label: Text(_label(d)),
                selected: discipline == d,
                selectedColor: AppColors.accent.withValues(alpha: 0.25),
                labelStyle: TextStyle(
                  color: discipline == d
                      ? AppColors.accent
                      : AppColors.chipIdleText,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => onDisciplineChanged(d),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        DropdownButtonFormField<String>(
          initialValue: styleOptions.any((e) => e.id == style)
              ? style
              : styleOptions.first.id,
          decoration: const InputDecoration(labelText: 'Fahrstil'),
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
          children: const [
            Text('Einsteiger',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
            Text('Profi',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
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
                child: const Text('Abbrechen'),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: FilledButton(
                onPressed: busy ? null : onSave,
                child: const Text('Speichern'),
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
