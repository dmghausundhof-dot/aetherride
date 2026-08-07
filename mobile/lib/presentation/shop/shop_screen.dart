import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/app_database.dart';
import '../../domain/component.dart';
import '../../providers/app_providers.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ComponentSlot? _slot;
  final _q = TextEditingController();
  List<CatalogCacheData> _items = [];
  bool _loading = false;

  static String get _webShopUrl => '${AppConfig.apiBaseUrl}/shop';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref.read(catalogClientProvider).search(
          slot: _slot?.apiId,
          q: _q.text.trim().isEmpty ? null : _q.text.trim(),
          limit: 40,
        );
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  Future<void> _openFullShop() async {
    final uri = Uri.parse(_webShopUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shop: $_webShopUrl')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shop im Browser: $_webShopUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Katalog',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Passende Teile browsen — Kauf im Web-Shop.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ComponentSlot?>(
                  initialValue: _slot,
                  decoration: const InputDecoration(
                    labelText: 'Slot',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Alle'),
                    ),
                    for (final s in coreInstallSlots)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) {
                    setState(() => _slot = v);
                    _load();
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _q,
                  decoration: InputDecoration(
                    labelText: 'Suche',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _loading ? null : _load,
                    ),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openFullShop,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Vollständiger Shop im Browser'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(
                        child: Text(
                          'Keine Einträge — API offline oder Cache leer.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final it = _items[i];
                          return ListTile(
                            title: Text('${it.manufacturer} ${it.model}'),
                            subtitle: Text('${it.slot} · ${it.id}'),
                            dense: true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
