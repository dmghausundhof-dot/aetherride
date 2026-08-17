import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/routing/route_collections.dart';
import '../../l10n/app_localizations.dart';
import '../shell/hof_threshold_nav.dart';

/// Fügt [routeId] einer lokalen Sammlung hinzu. `true` wenn gespeichert.
Future<bool> showAddToCollectionSheet(
  BuildContext context, {
  required String routeId,
}) async {
  var cols = await RouteCollectionsStore.list();
  if (!context.mounted) return false;
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final nameCtrl = TextEditingController();
      return StatefulBuilder(
        builder: (ctx, setModal) {
          final l10n = AppLocalizations.of(ctx);
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
                  l10n.akteAddToCollection,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.discoverLocalFoldersHint,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                if (cols.isEmpty)
                  Text(
                    l10n.discoverNoCollectionYet,
                    style: const TextStyle(color: AppColors.muted),
                  )
                else
                  for (final c in cols)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(c.name),
                      subtitle: Text(
                        l10n.collectionRouteCount(c.routeIds.length),
                      ),
                      onTap: () async {
                        await RouteCollectionsStore.addRoute(c.id, routeId);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      },
                    ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.discoverNewCollection,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final created = await RouteCollectionsStore.create(name);
                    await RouteCollectionsStore.addRoute(created.id, routeId);
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: Text(l10n.discoverCreate),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  return added == true;
}
