import 'package:aetherride_mobile/domain/community/map_place.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_ext.dart';
import '../../shared/chrome_glyph.dart';

enum OrtSheetAction { addVia, routeHere, openMaps }

/// Ort auf der Karte: Zwischenziel zuerst, Maps zuletzt.
Future<OrtSheetAction?> showOrtSheet(
  BuildContext context, {
  required MapPlace place,
  bool canAddVia = true,
  bool onLiveRoute = false,
}) {
  return showModalBottomSheet<OrtSheetAction>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => OrtSheet(
      place: place,
      canAddVia: canAddVia,
      onLiveRoute: onLiveRoute,
    ),
  );
}

class OrtSheet extends StatelessWidget {
  const OrtSheet({
    super.key,
    required this.place,
    this.canAddVia = true,
    this.onLiveRoute = false,
  });

  final MapPlace place;
  final bool canAddVia;
  final bool onLiveRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maps = place.mapsUrl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.mapPlaceKindLabel(place.kind),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (place.tip != null && place.tip!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                place.tip!.trim(),
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            if (canAddVia)
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, OrtSheetAction.addVia),
                icon: const ChromeGlyph('karte', size: 20),
                label: Text(
                  onLiveRoute
                      ? l10n.discoverPlaceOnRoute
                      : l10n.ortSheetVia,
                ),
              ),
            if (canAddVia) const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pop(context, OrtSheetAction.routeHere),
              icon: const ChromeGlyph('flag', size: 20),
              label: Text(l10n.ortSheetHere),
            ),
            if (maps != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, OrtSheetAction.openMaps);
                  try {
                    await launchUrl(
                      Uri.parse(maps),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                },
                child: Text(l10n.ortSheetMaps),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
