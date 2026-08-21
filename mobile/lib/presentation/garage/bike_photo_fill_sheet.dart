import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/garage/bike_photo_sync.dart';
import '../../data/garage/stand_photo_file.dart';
import '../../domain/bike.dart';
import '../../domain/catalog_bike.dart';
import '../../domain/garage/bike_photo_fill.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/app_providers.dart';
import 'garage_chrome.dart';
import 'oem_part_checklist_sheet.dart';

export 'garage_chrome.dart' show GrokReadCard;

class CatalogPhotoPick {
  const CatalogPhotoPick({
    this.hit,
    required this.file,
    this.visionParts = const [],
    this.queries = const [],
    this.readSummary = '',
    this.applyReadAsName = false,
    this.identifyReason,
  });

  final CatalogBikeHit? hit;
  final File file;
  final List<CatalogVisionPart> visionParts;
  final List<String> queries;
  final String readSummary;
  final bool applyReadAsName;

  /// no_key / quota / failed / unreadable / no_catalog — ehrlich, kein Abbruch.
  final String? identifyReason;
}

Future<CatalogPhotoPick?> pickCatalogHitFromPhoto({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final source = await showGarageImageSourceSheet(
    context: context,
    hint: AppLocalizations.of(context).garagePhotoIdentifyHint,
  );
  if (source == null || !context.mounted) return null;

  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 82,
  );
  if (picked == null || !context.mounted) return null;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(AppLocalizations.of(context).garagePhotoIdentifying)),
  );

  CatalogIdentifyResult result;
  try {
    final bytes = await File(picked.path).readAsBytes();
    result = await ref.read(catalogClientProvider).identify(
          imageBase64: base64Encode(bytes),
        );
  } catch (_) {
    result = const CatalogIdentifyResult(reason: 'failed');
  }

  if (!context.mounted) return null;
  if (!result.canContinue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).identifyReasonLabel(result.reason),
        ),
      ),
    );
    return CatalogPhotoPick(
      file: File(picked.path),
      identifyReason: result.reason ?? 'failed',
    );
  }

  CatalogBikeHit? hit;
  var applyReadAsName = false;
  if (result.hasHits) {
    hit = await showModalBottomSheet<CatalogBikeHit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _IdentifyHitsSheet(result: result),
    );
  } else if (result.hasVisionRead || result.visionParts.isNotEmpty) {
    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GrokReadOnlySheet(result: result),
    );
    applyReadAsName = apply == true;
  }

  return CatalogPhotoPick(
    hit: hit,
    file: File(picked.path),
    visionParts: result.visionParts,
    queries: result.queries,
    readSummary: result.readSummary,
    applyReadAsName: applyReadAsName,
    identifyReason: result.reason,
  );
}

Future<void> persistPickedBikePhoto({
  required WidgetRef ref,
  required String bikeId,
  required File source,
}) async {
  final dir = await getApplicationSupportDirectory();
  final dest = File(p.join(dir.path, 'bike_photos', '$bikeId.jpg'));
  await writeStandCroppedJpeg(source: source, dest: dest);
  await FileImage(dest).evict();
  final store = ref.read(userProfileStoreProvider);
  await store.setBikePhoto(bikeId, dest.path);
  final url = await uploadBikePhotoToStorage(bikeId: bikeId, file: dest);
  if (url != null) {
    await store.setBikePhoto(bikeId, url);
  }
  final now = store.bikePhotos[bikeId] ?? dest.path;
  await store.markBikePhotoStandCropped(bikeId, now);
}

Future<void> persistGrokRead({
  required WidgetRef ref,
  required String bikeId,
  required String readSummary,
}) async {
  final t = readSummary.trim();
  if (t.isEmpty) return;
  await ref.read(userProfileStoreProvider).setBikeGrokRead(bikeId, t);
}

/// Foto → Identify → nur leere Felder. Sichtbar an Identität / technische Details.
Future<BikePhotoFill?> showBikePhotoFillSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Bike bike,
}) async {
  final picked = await pickCatalogHitFromPhoto(context: context, ref: ref);
  if (picked == null || !context.mounted) return null;
  await persistPickedBikePhoto(
    ref: ref,
    bikeId: bike.id,
    source: picked.file,
  );
  await persistGrokRead(
    ref: ref,
    bikeId: bike.id,
    readSummary: picked.readSummary,
  );
  final hit = picked.hit;

  ({CatalogManufacturer mfr, CatalogBikeVariant bike})? found;
  late BikePhotoFill fill;
  if (hit != null) {
    final catalog = await ref.read(catalogClientProvider).fetchBikes();
    found = findCatalogBikeInList(
      catalog,
      bikeId: hit.id,
      manufacturerId: hit.manufacturerId,
      manufacturerName: hit.manufacturerName,
    );
    fill = found == null
        ? fillEmptyBikeFromHit(bike: bike, hit: hit)
        : fillEmptyBikeFromCatalog(
            bike: bike,
            manufacturerName: found.mfr.name,
            catalog: found.bike,
          );
  } else if (picked.applyReadAsName && picked.queries.isNotEmpty) {
    found = null;
    fill = suggestNameFromGrokRead(bike: bike, query: picked.queries.first);
  } else {
    found = null;
    fill = BikePhotoFill(bike: bike, filled: const []);
  }

  if (fill.changed) {
    await ref.read(garageRepositoryProvider).upsert(fill.bike);
    ref.invalidate(bikesProvider);
  }

  final installed =
      await ref.read(componentRepositoryProvider).listInstalled(bike.id);
  final raw = oemSuggestionsFromMap(
    found?.bike.oemComponents ?? {},
    vision: visionPartsFromIdentify(picked.visionParts),
    installed: installed,
  );
  final suggestions = await resolveOemSuggestionNames(
    ref.read(catalogClientProvider),
    raw,
  );

  if (!context.mounted) return fill;
  final checked = await showOemPartChecklist(
    context: context,
    suggestions: suggestions,
    grokRead: picked.readSummary,
    identifyReason: picked.identifyReason,
  );
  if (checked != null && checked.isNotEmpty && context.mounted) {
    final n = await installCheckedOemParts(
      ref: ref,
      bikeId: bike.id,
      checked: checked,
    );
    if (context.mounted && n > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).garagePhotoPartsInstalled(n),
          ),
        ),
      );
    }
  } else if (fill.changed && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)
              .garagePhotoFilledFields(fill.filled.join(', ')),
        ),
      ),
    );
  } else if (picked.readSummary.isNotEmpty && context.mounted) {
    ref.invalidate(bikesProvider);
  } else if (!fill.changed && (checked == null || checked.isEmpty)) {
    if (context.mounted && suggestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).garagePhotoFillNone),
        ),
      );
    }
  }
  return fill;
}

class _IdentifyHitsSheet extends StatelessWidget {
  const _IdentifyHitsSheet({required this.result});

  final CatalogIdentifyResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GarageSheetHandle(),
          GarageSheetTitle(
            title: AppLocalizations.of(context).garagePhotoWhichBike,
            hint: AppLocalizations.of(context).garagePhotoHitsHint,
          ),
          if (result.readSummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            GrokReadCard(summary: result.readSummary),
          ],
          const SizedBox(height: AppSpacing.m),
          for (final hit in result.matches.take(6))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                hit.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  AppLocalizations.of(context).bikeCategoryShort(hit.category),
                  if (hit.isEbike)
                    AppLocalizations.of(context).garageEbikeBadge,
                ].join(' · '),
              ),
              onTap: () => Navigator.pop(context, hit),
            ),
        ],
      ),
    );
  }
}

class _GrokReadOnlySheet extends StatefulWidget {
  const _GrokReadOnlySheet({required this.result});

  final CatalogIdentifyResult result;

  @override
  State<_GrokReadOnlySheet> createState() => _GrokReadOnlySheetState();
}

class _GrokReadOnlySheetState extends State<_GrokReadOnlySheet> {
  bool _applyName = false;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final parts = visionPartsFromIdentify(result.visionParts);
    final query = result.queries.isEmpty ? '' : result.queries.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GarageSheetHandle(),
          GarageSheetTitle(
            title: AppLocalizations.of(context).garagePhotoNoHit,
            hint: AppLocalizations.of(context).garagePhotoNoHitHint,
          ),
          const SizedBox(height: AppSpacing.m),
          GrokReadCard(summary: result.readSummary, parts: parts),
          if (query.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            CheckboxListTile(
              value: _applyName,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _applyName = v ?? false),
              title: Text(
                AppLocalizations.of(context).garagePhotoApplyName(query),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                AppLocalizations.of(context).garagePhotoApplyNameHint,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          FilledButton(
            onPressed: () => Navigator.pop(context, _applyName),
            child: Text(AppLocalizations.of(context).garagePhotoContinueRead),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
        ],
      ),
    );
  }
}
