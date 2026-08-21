import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog/catalog_client.dart';
import '../../domain/component.dart';
import '../../domain/garage/bike_photo_fill.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import 'garage_chrome.dart';
import '../shared/chrome_glyph.dart';

/// Katalog-Namen nachschlagen, ohne Grok-Zeilen eine SKU anzudichten.
Future<List<OemPartSuggestion>> resolveOemSuggestionNames(
  CatalogClient catalog,
  List<OemPartSuggestion> raw,
) async {
  return Future.wait(raw.map((s) async {
    if (!s.hasCatalogId) return s;
    if ((s.manufacturer ?? '').trim().isNotEmpty &&
        (s.model ?? '').trim().isNotEmpty) {
      return s;
    }
    final hit = await catalog.getModel(s.catalogModelId!);
    if (hit == null) return s;
    return namedSuggestion(
      s,
      manufacturer: hit.manufacturer,
      model: hit.model,
    );
  }));
}

Future<int> installCheckedOemParts({
  required WidgetRef ref,
  required String bikeId,
  required List<OemPartSuggestion> checked,
}) async {
  var n = 0;
  final repo = ref.read(componentRepositoryProvider);
  for (final s in checked) {
    if (!s.canInstall) continue;
    await repo.install(
      bikeId: bikeId,
      slot: s.slot,
      manufacturer: s.manufacturer,
      model: s.model,
      catalogModelId: s.hasCatalogId ? s.catalogModelId : null,
    );
    n++;
  }
  ref.invalidate(bikeComponentsProvider(bikeId));
  ref.invalidate(bikesProvider);
  return n;
}

/// Sichtbare Prüfliste: Katalog-OEM + Grok-Werte ohne SKU + selbst tippen.
Future<List<OemPartSuggestion>?> showOemPartChecklist({
  required BuildContext context,
  required List<OemPartSuggestion> suggestions,
  String? grokRead,
  String? identifyReason,
}) {
  return showModalBottomSheet<List<OemPartSuggestion>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _OemPartChecklistSheet(
      suggestions: suggestions,
      grokRead: grokRead,
      identifyReason: identifyReason,
    ),
  );
}

class _OemPartChecklistSheet extends StatefulWidget {
  const _OemPartChecklistSheet({
    required this.suggestions,
    this.grokRead,
    this.identifyReason,
  });

  final List<OemPartSuggestion> suggestions;
  final String? grokRead;
  final String? identifyReason;

  @override
  State<_OemPartChecklistSheet> createState() => _OemPartChecklistSheetState();
}

class _OemPartChecklistSheetState extends State<_OemPartChecklistSheet> {
  late List<OemPartSuggestion> _rows;
  final Set<int> _checked = {};

  @override
  void initState() {
    super.initState();
    _rows = List<OemPartSuggestion>.from(widget.suggestions);
  }

  Future<void> _addTyped() async {
    final typed = await showRiderTypedPartSheet(context);
    if (typed == null || !mounted) return;
    setState(() {
      _rows.add(typed);
      _checked.add(_rows.length - 1);
    });
  }

  String _sourceCaption(AppLocalizations l10n, OemPartSuggestion s) {
    if (s.source == OemPartSource.typed) return l10n.oemTypedSource;
    if (s.isGrokOnly) return l10n.oemGrokOnlyBadge;
    if (s.source == OemPartSource.vision) return l10n.oemVisionSource;
    return l10n.oemCatalogSource;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final empty = _rows.isEmpty;
    final height = MediaQuery.sizeOf(context).height * 0.78;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GarageSheetHandle(),
            GarageSheetTitle(
              title: l10n.oemCheckTitle,
              hint: empty ? l10n.oemCheckEmptyHint : l10n.oemCheckHint,
            ),
            if ((widget.identifyReason ?? '').isNotEmpty &&
                (widget.grokRead ?? '').trim().isEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.identifyReasonLabel(widget.identifyReason),
                style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
              ),
            ],
            if ((widget.grokRead ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              GrokReadCard(summary: widget.grokRead!, compact: true),
            ],
            const SizedBox(height: AppSpacing.m),
            Expanded(
              child: empty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChromeGlyph(
                            'care',
                            size: 40,
                            color: AppColors.muted.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            l10n.oemCheckEmpty,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.oemCheckEmptyHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.s),
                      itemBuilder: (context, i) {
                        final s = _rows[i];
                        final on = _checked.contains(i);
                        return _OemCheckRow(
                          suggestion: s,
                          checked: on,
                          sourceCaption: _sourceCaption(l10n, s),
                          occupiedLabel: s.occupied
                              ? l10n.oemOccupiedReplace
                              : null,
                          onToggle: () {
                            setState(() {
                              if (on) {
                                _checked.remove(i);
                              } else {
                                _checked.add(i);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: AppSpacing.s),
            OutlinedButton.icon(
              onPressed: _addTyped,
              icon: const ChromeGlyph('add', size: 18),
              label: Text(
                empty ? l10n.oemCheckAdd : l10n.oemCheckAddMore,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            FilledButton(
              onPressed: () {
                final picked = [
                  for (final i in _checked) _rows[i],
                ];
                Navigator.pop(context, picked);
              },
              child: Text(
                _checked.isEmpty
                    ? l10n.oemCheckContinueEmpty
                    : l10n.oemCheckInstallCount(_checked.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OemCheckRow extends StatelessWidget {
  const _OemCheckRow({
    required this.suggestion,
    required this.checked,
    required this.sourceCaption,
    required this.onToggle,
    this.occupiedLabel,
  });

  final OemPartSuggestion suggestion;
  final bool checked;
  final String sourceCaption;
  final String? occupiedLabel;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grok = suggestion.isGrokOnly;
    final catalog = suggestion.hasCatalogId;
    final bar = grok
        ? AppColors.warning
        : catalog
            ? AppColors.sageOnDark
            : AppColors.border;
    return Material(
      color: AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: checked ? AppColors.chrome : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(
                  color: bar,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.chip),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s,
                  AppSpacing.m,
                  AppSpacing.s,
                  AppSpacing.m,
                ),
                child: _OemCheckMark(on: checked),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpacing.s,
                    AppSpacing.m,
                    AppSpacing.s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.componentSlotLabel(suggestion.slot),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        suggestion.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _SourceBadge(
                            label: grok
                                ? l10n.oemGrokOnlyBadge
                                : catalog
                                    ? l10n.oemCatalogBadge
                                    : sourceCaption,
                            grok: grok,
                            catalog: catalog,
                          ),
                          if (occupiedLabel != null)
                            Text(
                              occupiedLabel!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OemCheckMark extends StatelessWidget {
  const _OemCheckMark({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: on ? AppColors.chrome : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: on ? AppColors.chrome : AppColors.border,
          width: 1.5,
        ),
      ),
      child: on
          ? const ChromeGlyph(
              'check',
              size: 16,
              color: AppColors.onAccent,
            )
          : null,
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({
    required this.label,
    required this.grok,
    required this.catalog,
  });

  final String label;
  final bool grok;
  final bool catalog;

  @override
  Widget build(BuildContext context) {
    final color = grok
        ? AppColors.warning
        : catalog
            ? AppColors.sageOnDark
            : AppColors.muted;
    return Container(
      key: grok
          ? const Key('oem-source-grok')
          : catalog
              ? const Key('oem-source-catalog')
              : const Key('oem-source-typed'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// Rider-typed: Slot + Hersteller/Modell, bewusst ohne Katalog-ID.
Future<OemPartSuggestion?> showRiderTypedPartSheet(BuildContext context) {
  return showModalBottomSheet<OemPartSuggestion>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _RiderTypedPartSheet(),
  );
}

class _RiderTypedPartSheet extends StatefulWidget {
  const _RiderTypedPartSheet();

  @override
  State<_RiderTypedPartSheet> createState() => _RiderTypedPartSheetState();
}

class _RiderTypedPartSheetState extends State<_RiderTypedPartSheet> {
  ComponentSlot _slot = ComponentSlot.fork;
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();

  @override
  void dispose() {
    _manufacturer.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GarageSheetHandle(),
          GarageSheetTitle(
            title: l10n.garageInstallPart,
            hint: l10n.oemTypedHint,
          ),
          const SizedBox(height: AppSpacing.m),
          DropdownButtonFormField<ComponentSlot>(
            // ignore: deprecated_member_use
            value: _slot,
            decoration: InputDecoration(labelText: l10n.garageSlotHeading),
            items: [
              for (final s in ComponentSlot.values)
                DropdownMenuItem(
                  value: s,
                  child: Text(l10n.componentSlotLabel(s)),
                ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _slot = v);
            },
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _manufacturer,
            decoration: InputDecoration(labelText: l10n.garageManufacturer),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            controller: _model,
            decoration: InputDecoration(labelText: l10n.garageBrandModel),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.m),
          FilledButton(
            onPressed: () {
              final mfr = _manufacturer.text.trim();
              final model = _model.text.trim();
              if (mfr.isEmpty && model.isEmpty) return;
              Navigator.pop(
                context,
                OemPartSuggestion(
                  slot: _slot,
                  manufacturer: mfr.isEmpty ? null : mfr,
                  model: model.isEmpty ? null : model,
                  source: OemPartSource.typed,
                ),
              );
            },
            child: Text(l10n.garageInstallPart),
          ),
        ],
        ),
      ),
    );
  }
}
