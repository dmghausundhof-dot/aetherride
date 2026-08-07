import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/home/greeting.dart';
import '../../domain/rider_profile.dart';
import '../../providers/app_providers.dart';
import '../auth/auth_screen.dart';
import '../billing/upgrade_screen.dart';
import '../chat/chat_screen.dart';
import '../privacy/privacy_screen.dart';

/// Profil: Rider, Familie, Sync, Billing-Portal, Legal.
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

  Future<void> _load() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    if (!mounted) return;
    setState(() {
      _nameCtrl.text = store.displayName ?? '';
      _weightCtrl.text = store.riderProfile.riderWeightKg.toStringAsFixed(0);
      _style = store.riderProfile.style;
      _skill = store.riderProfile.skillLevel;
    });
  }

  Future<void> _saveProfile() async {
    final store = ref.read(userProfileStoreProvider);
    await store.load();
    store.displayName = _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim();
    final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 75;
    await store.setRiderProfile(
      store.riderProfile.copyWith(
        style: _style,
        skillLevel: _skill,
        riderWeightKg: w,
      ),
    );
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
      setState(() => _msg = 'Bitte anmelden');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/billing/portal'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode != 200) {
        setState(() => _msg = 'Portal: ${res.statusCode}');
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbruch')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hinzufügen')),
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
        displayName: nameCtrl.text.trim().isEmpty ? 'Fahrer' : nameCtrl.text.trim(),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.trail,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greetingLine(displayName: _nameCtrl.text.isEmpty ? null : _nameCtrl.text),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    Text(
                      email ?? 'Nicht angemeldet',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    Text(
                      'Tarif: $tier',
                      style: const TextStyle(color: AppColors.accent, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Anzeigename',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Fahrergewicht (kg)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _style,
            decoration: const InputDecoration(
              labelText: 'Fahrstil',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'flow', child: Text('Flow')),
              DropdownMenuItem(value: 'aggressive', child: Text('Aggressiv')),
              DropdownMenuItem(value: 'efficient', child: Text('Effizient')),
              DropdownMenuItem(value: 'explorative', child: Text('Explorativ')),
            ],
            onChanged: (v) => setState(() => _style = v ?? 'flow'),
          ),
          const SizedBox(height: 8),
          Text('Skill $_skill / 5', style: const TextStyle(color: AppColors.muted)),
          Slider(
            value: _skill.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_skill',
            onChanged: (v) => setState(() => _skill = v.round()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: _busy ? null : _saveProfile,
            child: const Text('Profil speichern'),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sync),
            title: const Text('Jetzt synchronisieren'),
            onTap: _busy ? null : _sync,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_open),
            title: const Text('Anmelden / Konto'),
            onTap: () => openAuthScreen(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.workspace_premium),
            title: const Text('Pro upgraden'),
            onTap: () => openUpgradeScreen(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Stripe Kundenportal'),
            onTap: _busy ? null : _openPortal,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('KI-Chat'),
            onTap: () => openChatScreen(context),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Daten & Privatsphäre'),
            onTap: () => openPrivacyScreen(context),
          ),
          const Divider(),
          Row(
            children: [
              const Text(
                'Familien-Garage',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(onPressed: _addFamilyRider, child: const Text('Hinzufügen')),
            ],
          ),
          FutureBuilder(
            future: store.load(),
            builder: (context, _) {
              if (store.familyRiders.isEmpty) {
                return const Text(
                  'Keine weiteren Fahrer — z. B. Partner/Kind mit eigenem Gewicht.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                );
              }
              return Column(
                children: [
                  for (final r in store.familyRiders)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(r.displayName),
                      subtitle: Text('${r.weightKg.toStringAsFixed(0)} kg'),
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
                ],
              );
            },
          ),
          const Divider(),
          const Text('Legal', style: TextStyle(fontWeight: FontWeight.w800)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Impressum'),
            onTap: () => launchUrl(
              Uri.parse('${AppConfig.apiBaseUrl}/legal/impressum'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Widerruf'),
            onTap: () => launchUrl(
              Uri.parse('${AppConfig.apiBaseUrl}/legal/widerruf'),
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
}

void openProfileScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
  );
}

void openPrivacyScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
  );
}
