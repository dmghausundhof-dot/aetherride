import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/component.dart';
import '../../domain/garage/bike_receipt.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_ext.dart';
import '../shared/chrome_glyph.dart';
import '../../providers/app_providers.dart';
import 'garage_chrome.dart';
import 'rad_glyph.dart';

class BikeReceiptsPanel extends ConsumerWidget {
  const BikeReceiptsPanel({
    super.key,
    required this.bike,
    this.components = const [],
    this.onChanged,
  });

  final Bike bike;
  final List<BikeComponent> components;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final receipts = store.receiptsForBike(bike.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: GarageSectionTitle(
                label: AppLocalizations.of(context).garageReceiptsTitle,
              ),
            ),
            TextButton.icon(
              onPressed: () => _add(context, ref),
              icon: const ChromeGlyph('add', size: 18),
              label: Text(AppLocalizations.of(context).garageReceiptAdd),
            ),
          ],
        ),
        Text(
          AppLocalizations.of(context).garageReceiptsHint,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.s),
        if (receipts.isEmpty)
          GarageInviteCard(
            title: AppLocalizations.of(context).garageReceiptsEmptyInvite,
            hint: AppLocalizations.of(context).garageReceiptsEmpty,
            mark: 'calendar',
            onTap: () => _add(context, ref),
          )
        else
          for (final r in receipts)
            _ReceiptTile(
              receipt: r,
              components: components,
              onOpen: () => _edit(context, ref, r),
            ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final source = await showGarageImageSourceSheet(
      context: context,
      allowSkip: true,
    );
    String? photoPath;
    ReceiptScanHint hint = const ReceiptScanHint();
    if (source != null) {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 82,
      );
      if (picked != null) {
        photoPath = await persistReceiptPhoto(
          bikeId: bike.id,
          sourcePath: picked.path,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).garageReceiptScanning,
              ),
            ),
          );
        }
        try {
          final bytes = await File(photoPath).readAsBytes();
          hint = await ref.read(catalogClientProvider).scanReceipt(
                base64Encode(bytes),
              );
        } catch (_) {
          hint = const ReceiptScanHint(reason: ReceiptScanReason.failed);
        }
        if (!hint.scanned && hint.reason == ReceiptScanReason.none) {
          hint = const ReceiptScanHint(reason: ReceiptScanReason.failed);
        }
      }
    }
    if (!context.mounted) return;
    final draft = BikeReceipt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bikeId: bike.id,
      kind: hint.kind,
      createdAt: DateTime.now().toUtc(),
      merchant: hint.merchant,
      date: hint.date,
      amountEur: hint.amountEur,
      title: hint.title ??
          (hint.items.isEmpty ? null : hint.items.join(', ')),
      photoPath: photoPath,
      ocrFilled: hint.scanned,
    );
    await _edit(
      context,
      ref,
      draft,
      creating: true,
      scanned: hint.scanned,
      scanReason: source == null ? ReceiptScanReason.none : hint.reason,
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    BikeReceipt receipt, {
    bool creating = false,
    bool scanned = false,
    ReceiptScanReason scanReason = ReceiptScanReason.none,
  }) async {
    final saved = await showModalBottomSheet<BikeReceipt>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReceiptSheet(
        receipt: receipt,
        components: components,
        creating: creating,
        scanned: scanned || receipt.ocrFilled,
        scanReason: scanned || receipt.ocrFilled
            ? ReceiptScanReason.ok
            : scanReason,
      ),
    );
    if (saved != null) {
      await ref.read(userProfileStoreProvider).upsertReceipt(saved);
    }
    onChanged?.call();
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({
    required this.receipt,
    required this.components,
    required this.onOpen,
  });

  final BikeReceipt receipt;
  final List<BikeComponent> components;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    BikeComponent? part;
    final cid = receipt.componentId;
    if (cid != null) {
      for (final c in components) {
        if (c.id == cid) {
          part = c;
          break;
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            decoration: garageCardDecoration(),
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Row(
              children: [
                _ReceiptThumb(path: receipt.photoPath),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.hasFacts
                            ? receipt.summary
                            : AppLocalizations.of(context)
                                .receiptKindLabel(receipt.kind),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          AppLocalizations.of(context)
                              .receiptKindLabel(receipt.kind),
                          if (part != null) part.model,
                          if (receipt.ocrFilled)
                            AppLocalizations.of(context).garagePhoto,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptThumb extends StatelessWidget {
  const _ReceiptThumb({this.path, this.size = 56});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    final has = file != null && file.existsSync();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: AppColors.surfaceDark,
        child: has
            ? Image.file(
                file,
                key: ValueKey('$path-${_receiptPhotoStamp(path!)}'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ChromeGlyph(
                  'file',
                  size: 22,
                  color: AppColors.muted,
                ),
              )
            : const ChromeGlyph('file', size: 22, color: AppColors.muted),
      ),
    );
  }
}

class _ReceiptSheet extends ConsumerStatefulWidget {
  const _ReceiptSheet({
    required this.receipt,
    required this.components,
    required this.creating,
    required this.scanned,
    this.scanReason = ReceiptScanReason.none,
  });

  final BikeReceipt receipt;
  final List<BikeComponent> components;
  final bool creating;
  final bool scanned;
  final ReceiptScanReason scanReason;

  @override
  ConsumerState<_ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends ConsumerState<_ReceiptSheet> {
  late BikeReceiptKind _kind;
  late final TextEditingController _merchant;
  late final TextEditingController _date;
  late final TextEditingController _amount;
  late final TextEditingController _title;
  late final TextEditingController _notes;
  String? _photoPath;
  String? _componentId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final r = widget.receipt;
    _kind = r.kind;
    _merchant = TextEditingController(text: r.merchant ?? '');
    _date = TextEditingController(text: r.date ?? '');
    _amount = TextEditingController(
      text: r.amountEur == null ? '' : r.amountEur!.toStringAsFixed(0),
    );
    _title = TextEditingController(text: r.title ?? '');
    _notes = TextEditingController(text: r.notes ?? '');
    _photoPath = r.photoPath;
    _componentId = r.componentId;
  }

  @override
  void dispose() {
    _merchant.dispose();
    _date.dispose();
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 82,
    );
    if (x == null) return;
    final path = await persistReceiptPhoto(
      bikeId: widget.receipt.bikeId,
      sourcePath: x.path,
    );
    setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    Navigator.pop(
      context,
      widget.receipt.copyWith(
        kind: _kind,
        merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
        date: _date.text.trim().isEmpty ? null : _date.text.trim(),
        amountEur: double.tryParse(_amount.text.replaceAll(',', '.')),
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        photoPath: _photoPath,
        componentId: _componentId,
        ocrFilled: widget.scanned,
        clearPhoto: _photoPath == null,
        clearComponent: _componentId == null,
      ),
    );
  }

  Future<void> _delete() async {
    await ref.read(userProfileStoreProvider).deleteReceipt(widget.receipt.id);
    if (mounted) Navigator.pop(context);
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GarageSheetHandle(),
            GarageSheetTitle(
              title: widget.creating
                  ? l10n.garageReceiptRemember
                  : l10n.garageReceiptsTitle,
              hint: l10n.receiptScanLabel(
                widget.scanned ? ReceiptScanReason.ok : widget.scanReason,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Center(
              child: GestureDetector(
                onTap: () => _pick(ImageSource.gallery),
                child: _ReceiptThumb(path: _photoPath, size: 120),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              children: [
                TextButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const RadGlyph('photo', size: 18),
                  label: Text(l10n.postRidePhotoCamera),
                ),
                TextButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const RadGlyph('photo', size: 18),
                  label: Text(l10n.garageGallery),
                ),
                if (_photoPath != null)
                  TextButton(
                    onPressed: () => setState(() => _photoPath = null),
                    child: Text(l10n.garageReceiptRemovePhoto),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: 8,
              children: [
                for (final k in BikeReceiptKind.values)
                  ChoiceChip(
                    label: Text(l10n.receiptKindLabel(k)),
                    selected: _kind == k,
                    onSelected: (_) => setState(() => _kind = k),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _merchant,
              decoration: InputDecoration(
                labelText: l10n.garageReceiptMerchant,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _date,
                    decoration: InputDecoration(
                      labelText: l10n.garageReceiptDate,
                      hintText: l10n.garageReceiptDateHint,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.garageReceiptAmount,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l10n.garageReceiptWhat,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.garageOwnerNotes,
                isDense: true,
              ),
            ),
            if (widget.components.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              DropdownButtonFormField<String?>(
                // ignore: deprecated_member_use
                value: _componentId,
                decoration: InputDecoration(
                  labelText: l10n.garageReceiptAttachPart,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.garageReceiptFreeOnBike),
                  ),
                  for (final c in widget.components)
                    DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text('${c.slot.label} · ${c.model}'),
                    ),
                ],
                onChanged: (v) => setState(() => _componentId = v),
              ),
            ],
            const SizedBox(height: AppSpacing.m),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(l10n.save),
            ),
            if (!widget.creating)
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await _delete();
                      },
                child: Text(l10n.delete),
              ),
          ],
        ),
      ),
    );
  }
}

Future<String> persistReceiptPhoto({
  required String bikeId,
  required String sourcePath,
}) async {
  final dir = await getApplicationSupportDirectory();
  final dest = File(
    p.join(
      dir.path,
      'bike_receipts',
      bikeId,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    ),
  );
  await dest.parent.create(recursive: true);
  await File(sourcePath).copy(dest.path);
  await FileImage(dest).evict();
  return dest.path;
}

int _receiptPhotoStamp(String path) {
  try {
    return File(path).lastModifiedSync().millisecondsSinceEpoch;
  } catch (_) {
    return 0;
  }
}
