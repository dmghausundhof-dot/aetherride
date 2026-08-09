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
import '../../domain/bike.dart';
import '../../domain/home/greeting.dart';
import '../../domain/rider_profile.dart';
import '../../providers/app_providers.dart';
import '../auth/auth_screen.dart';
import '../billing/upgrade_screen.dart';
import '../chat/chat_screen.dart';
import '../privacy/privacy_screen.dart';

/// Profil: Foto, Disziplin, Fahrstil, Sync, Abo, Legal — kein Shop-Modus.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;
  String? _msg;
  late TextEditingController _nameCtrl;
  late TextEditingController _weightCtrl;
  String _style = 'flow';
  int _skill = 3;
  BikeCategory _discipline = BikeCategory.mtbAm;

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
          (id: 'explorative', label: 'Explorativ'),
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
      _discipline = store.preferredSport ?? BikeCategory.mtbAm;
    });
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
    if (mounted) setState(() => _msg = 'Profilbild gesetzt');
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
      setState(() => _msg = 'Profil gespeichert');
      ref.invalidate(riderProfileProvider);
    }
  }

  Future<void> _sync() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      await ref.read(syncEngineProvider).syncNow();
      setState(() => _msg = 'Sync OK');
    } catch (e) {
      setState(() => _msg = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPortal() async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      setState(() => _msg = 'Bitte anmelden für Aboverwaltung');
      return;
    }
    setState(() {
      _busy = true;
      _msg = null;
    });
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
        setState(() {
          _msg = err == 'no_stripe_customer'
              ? 'Noch kein Stripe-Abo — zuerst Pro upgraden.'
              : (err ?? 'Portal: ${res.statusCode}');
        });
        return;
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        setState(() => _msg = 'Keine Portal-URL');
        return;
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      setState(() => _msg = '$e');
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
    if (mounted) setState(() => _msg = 'Fahrer hinzugefügt');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final tier = ref.watch(subscriptionTierProvider);
    final store = ref.watch(userProfileStoreProvider);
    final email = session?.user.email;
    final initials = avatarInitials(
      displayName: _nameCtrl.text,
      email: email,
    );
    final photo = store.profilePhotoPath;
    final isPro = tier == 'pro';

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Header
          Row(
            children: [
              InkWell(
                onTap: _busy ? null : _pickPhoto,
                borderRadius: BorderRadius.circular(40),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.trail,
                  backgroundImage: photo != null &&
                          (photo.startsWith('http') || File(photo).existsSync())
                      ? (photo.startsWith('http')
                          ? NetworkImage(photo)
                          : FileImage(File(photo)) as ImageProvider)
                      : null,
                  child: photo == null ||
                          (!photo.startsWith('http') &&
                              !File(photo).existsSync())
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameCtrl.text.trim().isEmpty
                          ? 'Fahrerprofil'
                          : _nameCtrl.text.trim(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? 'Lokal — Sync nach Anmeldung',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _busy ? null : _pickPhoto,
                      child: const Text('Foto ändern'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Abo card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.chipIdle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'AetherRide Pro',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPro
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPro ? 'Aktiv' : 'Free',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isPro ? AppColors.accent : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isPro
                      ? 'Abo verwalten, Rechnungen und Zahlungsmethoden.'
                      : 'Offline-Packs, mehr Bikes und Pro-Features.',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                if (isPro)
                  OutlinedButton(
                    onPressed: _busy ? null : _openPortal,
                    child: const Text('Abo verwalten'),
                  )
                else
                  FilledButton(
                    onPressed: () => openUpgradeScreen(context),
                    child: const Text('Pro upgraden'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Text(
            'Fahrer',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Anzeigename'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Fahrergewicht (kg)'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Disziplin',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in const [
                BikeCategory.mtbAm,
                BikeCategory.mtbEnduro,
                BikeCategory.gravel,
                BikeCategory.emtb,
                BikeCategory.road,
                BikeCategory.urban,
              ])
                ChoiceChip(
                  label: Text(_disciplineLabel(d)),
                  selected: _discipline == d,
                  selectedColor: AppColors.accent.withValues(alpha: 0.25),
                  labelStyle: TextStyle(
                    color: _discipline == d
                        ? AppColors.accent
                        : AppColors.chipIdleText,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _discipline = d;
                      final ids = _styleOptions.map((e) => e.id).toSet();
                      if (!ids.contains(_style)) {
                        _style = _styleOptions.first.id;
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _styleOptions.any((e) => e.id == _style)
                ? _style
                : _styleOptions.first.id,
            decoration: const InputDecoration(labelText: 'Fahrstil'),
            dropdownColor: AppColors.surfaceDark,
            items: [
              for (final s in _styleOptions)
                DropdownMenuItem(value: s.id, child: Text(s.label)),
            ],
            onChanged: (v) => setState(() => _style = v ?? _style),
          ),
          const SizedBox(height: 8),
          Text(
            'Können $_skill / 5',
            style: const TextStyle(color: AppColors.muted),
          ),
          Slider(
            value: _skill.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_skill',
            onChanged: (v) => setState(() => _skill = v.round()),
          ),
          FilledButton(
            onPressed: _busy ? null : _saveProfile,
            child: const Text('Profil speichern'),
          ),
          const SizedBox(height: 20),

          const Text(
            'Konto & Sync',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sync),
            title: const Text('Jetzt synchronisieren'),
            onTap: _busy ? null : _sync,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
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
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Assistent'),
            onTap: () => openChatScreen(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Daten & Privatsphäre'),
            onTap: () => openPrivacyScreen(context),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Text(
                'Familien-Garage',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: _addFamilyRider,
                child: const Text('Hinzufügen'),
              ),
            ],
          ),
          if (store.familyRiders.isEmpty)
            const Text(
              'Weitere Fahrer mit eigenem Gewicht — z. B. Partner oder Kind.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            )
          else
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
                      store.familyRiders.where((x) => x.id != r.id).toList(),
                    );
                    setState(() {});
                  },
                ),
              ),
          const Divider(height: 28),
          const Text(
            'Rechtliches',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Datenschutz'),
            onTap: () => launchUrl(
              Uri.parse(AppConfig.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Impressum'),
            onTap: () => launchUrl(
              Uri.parse(AppConfig.impressumUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Widerruf'),
            onTap: () => launchUrl(
              Uri.parse(AppConfig.widerrufUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (_msg != null) ...[
            const SizedBox(height: 12),
            Text(_msg!, style: const TextStyle(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }

  String _disciplineLabel(BikeCategory c) => switch (c) {
        BikeCategory.mtbAm => 'MTB',
        BikeCategory.mtbEnduro => 'Enduro',
        BikeCategory.gravel => 'Gravel',
        BikeCategory.emtb => 'E-MTB',
        BikeCategory.road => 'Rennrad',
        BikeCategory.urban => 'City',
        _ => c.name,
      };
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
