import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';
import '../../data/shop/garage_bike_shopify.dart';
import '../../domain/bike.dart';
import '../../domain/bike_assist.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import '../../domain/catalog_bike.dart';
import '../../domain/garage/bike_photo_fill.dart';
import 'bike_photo_fill_sheet.dart';
import 'garage_chrome.dart';
import 'rad_glyph.dart';
import '../shared/chrome_glyph.dart';
import 'rad_stand_frame.dart';
import 'oem_part_checklist_sheet.dart';

/// Ein Schritt: Name, Antrieb, Typ. Rest später in der Identität.
class AddBikeSheet extends ConsumerStatefulWidget {
  const AddBikeSheet({super.key, this.initialCategory});

  final BikeCategory? initialCategory;

  @override
  ConsumerState<AddBikeSheet> createState() => _AddBikeSheetState();
}

class _AddBikeSheetState extends ConsumerState<AddBikeSheet> {
  final _name = TextEditingController();
  late BikeCategory _category;
  late BikeAssistMode _assistMode;
  bool _busy = false;
  CatalogBikeHit? _photoHit;
  CatalogBikeVariant? _photoCatalog;
  String? _photoBrand;
  File? _photoFile;
  var _photoCropped = false;
  String _grokRead = '';
  String? _identifyReason;
  List<OemPartSuggestion> _pendingParts = const [];

  Bike get _draftIdentity {
    return Bike(
      id: '',
      name: '',
      category: BikeAssistUx.persistCategory(_category, _assistMode),
      isEbike: BikeAssistUx.persistIsEbike(_category, _assistMode),
    );
  }

  @override
  void initState() {
    super.initState();
    var cat = widget.initialCategory ??
        ref.read(userProfileStoreProvider).preferredSport ??
        BikeCategory.urban;
    if (cat == BikeCategory.hiking) cat = BikeCategory.urban;
    _category = cat;
    _assistMode = BikeAssistUx.modeFor(category: _category);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _fromPhoto() async {
    final picked = await pickCatalogHitFromPhoto(context: context, ref: ref);
    if (picked == null || !mounted) return;
    ({CatalogManufacturer mfr, CatalogBikeVariant bike})? found;
    if (picked.hit != null) {
      final catalog = await ref.read(catalogClientProvider).fetchBikes();
      found = findCatalogBikeInList(
        catalog,
        bikeId: picked.hit!.id,
        manufacturerId: picked.hit!.manufacturerId,
        manufacturerName: picked.hit!.manufacturerName,
      );
    }
    setState(() {
      _photoHit = picked.hit;
      _photoFile = picked.file;
      _photoCropped = picked.alreadyCropped;
      _photoCatalog = found?.bike;
      _photoBrand = found?.mfr.name ?? picked.hit?.manufacturerName;
      _grokRead = picked.readSummary;
      _identifyReason = picked.identifyReason;
      if (_name.text.trim().isEmpty) {
        final label = picked.hit?.label ??
            (picked.queries.isNotEmpty ? picked.queries.first : '');
        if (label.isNotEmpty) _name.text = label;
      }
    });
    if (!mounted) return;
    final raw = oemSuggestionsFromMap(
      found?.bike.oemComponents ?? {},
      vision: visionPartsFromIdentify(picked.visionParts),
    );
    final suggestions = await resolveOemSuggestionNames(
      ref.read(catalogClientProvider),
      raw,
    );
    if (!mounted) return;
    final checked = await showOemPartChecklist(
      context: context,
      suggestions: suggestions,
      grokRead: picked.readSummary,
      identifyReason: picked.identifyReason,
    );
    if (!mounted) return;
    if (checked != null) {
      setState(() => _pendingParts = checked);
    }
  }

  void _setAssistMode(BikeAssistMode mode) {
    setState(() {
      _assistMode = mode;
      _category = BikeAssistUx.coerceCategory(_category, mode);
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final garage = ref.read(garageRepositoryProvider);
      final existing = await garage.listBikes();
      final tier = ref.read(subscriptionTierProvider);
      final persisted = BikeAssistUx.persistCategory(_category, _assistMode);
      final isEbike = BikeAssistUx.persistIsEbike(_category, _assistMode);
      final draft = Bike(
        id: '',
        name: _name.text.trim(),
        category: persisted,
        isEbike: isEbike,
        wheelSize: BikeAssistUx.defaultWheelFor(persisted),
      );
      final filled = _photoCatalog != null
          ? fillEmptyBikeFromCatalog(
              bike: draft,
              manufacturerName: _photoBrand ?? '',
              catalog: _photoCatalog!,
            )
          : _photoHit != null
              ? fillEmptyBikeFromHit(bike: draft, hit: _photoHit!)
              : null;
      final spec = filled?.bike ?? draft;
      final bike = await garage.addBikeBasic(
        name: spec.name,
        category: spec.category,
        isEbike: spec.isEbike,
        brand: spec.brand,
        model: spec.model,
        year: spec.year,
        wheelSize: spec.wheelSize ?? BikeAssistUx.defaultWheelFor(persisted),
        catalogBikeId: spec.catalogBikeId,
        frameSize: spec.frameSize,
        travelFrontMm: spec.travelFrontMm,
        travelRearMm: spec.travelRearMm,
        makeActive: true,
      );

      final existingSetups =
          await ref.read(setupRepositoryProvider).listForBike(bike.id);
      if (existingSetups.isEmpty) {
        await ref.read(setupRepositoryProvider).createVersion(
              bikeId: bike.id,
              label: l10n.garageBaseSetup,
              values: const [],
              createdBy: 'basic',
            );
      }

      if (!mounted) return;
      if (existing.isNotEmpty && tier != 'pro') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.garageFreeExtraLocal)),
        );
      }
      if (_photoFile != null) {
        await persistPickedBikePhoto(
          context: context,
          ref: ref,
          bikeId: bike.id,
          source: _photoFile!,
          alreadyCropped: _photoCropped,
        );
      }
      if (_grokRead.isNotEmpty) {
        await persistGrokRead(
          ref: ref,
          bikeId: bike.id,
          readSummary: _grokRead,
        );
      }
      if (_pendingParts.isNotEmpty) {
        await installCheckedOemParts(
          ref: ref,
          bikeId: bike.id,
          checked: _pendingParts,
        );
      }
      if (AppConfig.shopEnabled) {
        unawaited(notifyGarageBikeShopify(bike));
      }
      final profile = ref.read(userProfileStoreProvider);
      profile.adoptBikeCategory(
        bike.category,
        makePrimary: existing.isEmpty,
      );
      await profile.save();
      ref.invalidate(riderProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop(bike.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.garageCreateFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GarageSheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                0,
                AppSpacing.s,
                AppSpacing.s,
              ),
              child: GarageSheetTitle(
                title: l10n.garageAddBike,
                trailing: IconButton(
                  tooltip: l10n.close,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.s,
                AppSpacing.l,
                AppSpacing.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: RadStandFrame(
                      height: 112,
                      child: RadSilhouette(bike: _draftIdentity),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _fromPhoto,
                    icon: const RadGlyph('photo', size: 18),
                    label: Text(
                      _photoHit != null
                          ? '${l10n.garagePhoto}: ${_photoHit!.label}'
                          : _grokRead.isNotEmpty
                              ? '${l10n.garagePhoto}: $_grokRead'
                              : _photoFile != null
                                  ? l10n.garagePhotoKept
                                  : l10n.garagePhotoFromBike,
                    ),
                  ),
                  if (_grokRead.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s),
                    GrokReadCard(summary: _grokRead),
                  ],
                  if (_photoHit != null ||
                      _grokRead.isNotEmpty ||
                      _photoFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _pendingParts.isNotEmpty
                            ? l10n.garageAddPhotoPartsPending(
                                _pendingParts.length,
                              )
                            : (_identifyReason ?? '').isNotEmpty &&
                                    _grokRead.isEmpty
                                ? l10n.identifyReasonLabel(_identifyReason)
                                : l10n.garageAddPhotoHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.l),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: l10n.garageNameOptional,
                      hintText: l10n.bikeCategoryLabel(_draftIdentity),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_busy) unawaited(_save());
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _AssistModeSegmented(
                    selected: _assistMode,
                    onSelect: _setAssistMode,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _CategoryChips(
                    selected: _category,
                    assistMode: _assistMode,
                    onSelect: (c) => setState(() => _category = c),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.s,
                  AppSpacing.l,
                  AppSpacing.m,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.garageCreateBike,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistModeSegmented extends StatelessWidget {
  const _AssistModeSegmented({
    required this.selected,
    required this.onSelect,
  });

  final BikeAssistMode selected;
  final ValueChanged<BikeAssistMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        for (final mode in BikeAssistMode.values) ...[
          if (mode != BikeAssistMode.values.first)
            const SizedBox(width: AppSpacing.s),
          Expanded(
            child: InkWell(
              onTap: () => onSelect(mode),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                decoration: BoxDecoration(
                  color:
                      selected == mode ? AppColors.accent : AppColors.chipIdle,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color:
                        selected == mode ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChromeGlyph(
                      'nav',
                      size: 18,
                      color: selected == mode
                          ? AppColors.onAccent
                          : AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.bikeAssistModeLabel(mode),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: selected == mode
                            ? AppColors.onAccent
                            : AppColors.chipIdleText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.assistMode,
    required this.onSelect,
  });

  final BikeCategory selected;
  final BikeAssistMode assistMode;
  final ValueChanged<BikeCategory> onSelect;

  String _groupLabel(AppLocalizations l10n, String id) {
    return switch (id) {
      'trail' => l10n.garagePickTrail,
      'tour' => l10n.garagePickTour,
      'everyday' => l10n.garagePickEveryday,
      _ => id,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allowed = BikeAssistUx.addCategories(assistMode).toSet();
    final sections = <Widget>[];
    for (final group in BikeAssistUx.pickGroups(assistMode)) {
      final cats = [
        for (final c in group.categories)
          if (allowed.contains(c)) c,
      ];
      if (cats.isEmpty) continue;
      sections.add(GarageSectionTitle(label: _groupLabel(l10n, group.id)));
      sections.add(const SizedBox(height: AppSpacing.s));
      sections.add(
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            for (final c in cats)
              _TypeChip(
                category: c,
                assistMode: assistMode,
                label: l10n.bikeAssistSubtypeLabel(c, assistMode),
                selected: BikeAssistUx.addTileSelected(
                  c,
                  selected,
                  assistMode,
                ),
                onTap: () => onSelect(c),
              ),
          ],
        ),
      );
      sections.add(const SizedBox(height: AppSpacing.m));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.category,
    required this.assistMode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final BikeCategory category;
  final BikeAssistMode assistMode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final draft = Bike(
      id: '',
      name: '',
      category: BikeAssistUx.persistCategory(category, assistMode),
      isEbike: BikeAssistUx.persistIsEbike(category, assistMode),
    );
    return ChoiceChip(
      avatar: RadMiniStand(
        bike: draft,
        width: 28,
        height: 20,
        selected: selected,
      ),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return AppColors.chipIdle;
      }),
      labelStyle: TextStyle(
        color: selected ? AppColors.onAccent : AppColors.chipIdleText,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.border,
      ),
    );
  }
}
