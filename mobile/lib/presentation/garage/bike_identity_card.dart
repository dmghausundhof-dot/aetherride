import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import 'garage_chrome.dart';
import 'rad_glyph.dart';
import '../../domain/bike_owner.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../shared/chrome_glyph.dart';

/// Owner card: frame number, purchase, insurance. Local only.
class BikeIdentityCard extends StatelessWidget {
  const BikeIdentityCard({
    super.key,
    required this.bike,
    this.onEdit,
    this.onChanged,
  });

  final Bike bike;
  final VoidCallback? onEdit;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final owner = bike.owner;
    final rows = _identityRows(l10n, bike);

    return Container(
      key: const Key('bike-identity-card'),
      decoration: garageCardDecoration(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.s,
        AppSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const RadGlyph('identity', size: 18),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  l10n.garageBikeId,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  child: Text(
                    owner.isEmpty && rows.isEmpty
                        ? l10n.garageBikeIdAdd
                        : l10n.garageEditBike,
                  ),
                ),
            ],
          ),
          if (owner.isEmpty && rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 26,
                right: AppSpacing.s,
              ),
              child: Text(
                l10n.garageBikeIdEmpty,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            )
          else ...[
            if (owner.hasSerial)
              Padding(
                padding: const EdgeInsets.only(left: 26, right: AppSpacing.s),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        owner.serialNumber!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.garageSerial,
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: owner.serialNumber!),
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.garageSerialCopied)),
                        );
                      },
                      icon: const ChromeGlyph('copy', size: 18),
                    ),
                  ],
                ),
              ),
            if (rows.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  left: 26,
                  right: AppSpacing.m,
                  top: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 118,
                              child: Text(
                                row.$1,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                row.$2,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.only(
              left: 26,
              right: AppSpacing.m,
              top: AppSpacing.s,
            ),
            child: Text(
              l10n.garagePrivateHint,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

List<(String, String)> _identityRows(AppLocalizations l10n, Bike bike) {
  final o = bike.owner;
  return [
    if (o.color != null) (l10n.garageColor, o.color!),
    if (o.weightKg != null)
      (l10n.garageWeightKg, o.weightKg!.toStringAsFixed(1)),
    if (o.purchasedAt != null)
      (l10n.garagePurchasedAt, _formatDate(o.purchasedAt!)),
    if (o.purchasedFrom != null) (l10n.garagePurchasedFrom, o.purchasedFrom!),
    if (o.purchasePriceEur != null)
      (
        l10n.garagePurchasePrice,
        '${o.purchasePriceEur!.toStringAsFixed(0)} €',
      ),
    if (o.insuranceName != null) (l10n.garageInsurance, o.insuranceName!),
    if (o.insurancePolicy != null)
      (l10n.garageInsurancePolicy, o.insurancePolicy!),
    if (o.keyNumber != null) (l10n.garageKeyNumber, o.keyNumber!),
    if (o.hasWorkshop)
      (
        l10n.garageWorkshopOptional,
        [
          if ((o.workshopName ?? '').trim().isNotEmpty) o.workshopName!,
          if ((o.workshopAddress ?? '').trim().isNotEmpty) o.workshopAddress!,
          if ((o.workshopPhone ?? '').trim().isNotEmpty) o.workshopPhone!,
        ].join(' · '),
      ),
    if (o.notes != null) (l10n.garageOwnerNotes, o.notes!),
  ];
}

String _formatDate(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  return '${p[2]}.${p[1]}.${p[0]}';
}

Future<bool> showBikeIdentitySheet(
  BuildContext context,
  WidgetRef ref,
  Bike bike,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _BikeIdentitySheet(bike: bike),
  );
  if (saved == true) {
    ref.invalidate(bikesProvider);
    ref.invalidate(currentSetupProvider(bike.id));
  }
  return saved == true;
}

class _BikeIdentitySheet extends ConsumerStatefulWidget {
  const _BikeIdentitySheet({required this.bike});

  final Bike bike;

  @override
  ConsumerState<_BikeIdentitySheet> createState() => _BikeIdentitySheetState();
}

class _BikeIdentitySheetState extends ConsumerState<_BikeIdentitySheet> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _frameSize;
  late final TextEditingController _serial;
  late final TextEditingController _color;
  late final TextEditingController _weight;
  late final TextEditingController _purchasedAt;
  late final TextEditingController _purchasedFrom;
  late final TextEditingController _price;
  late final TextEditingController _insurance;
  late final TextEditingController _policy;
  late final TextEditingController _key;
  late final TextEditingController _notes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final b = widget.bike;
    final o = b.owner;
    _name = TextEditingController(text: b.name);
    _brand = TextEditingController(text: b.brand ?? '');
    _model = TextEditingController(text: b.model ?? '');
    _year = TextEditingController(text: b.year?.toString() ?? '');
    _frameSize = TextEditingController(text: b.frameSize ?? '');
    _serial = TextEditingController(text: o.serialNumber ?? '');
    _color = TextEditingController(text: o.color ?? '');
    _weight = TextEditingController(
      text: o.weightKg == null ? '' : o.weightKg!.toStringAsFixed(1),
    );
    _purchasedAt = TextEditingController(
      text: o.purchasedAt == null ? '' : _formatDate(o.purchasedAt!),
    );
    _purchasedFrom = TextEditingController(text: o.purchasedFrom ?? '');
    _price = TextEditingController(
      text: o.purchasePriceEur == null
          ? ''
          : o.purchasePriceEur!.toStringAsFixed(0),
    );
    _insurance = TextEditingController(text: o.insuranceName ?? '');
    _policy = TextEditingController(text: o.insurancePolicy ?? '');
    _key = TextEditingController(text: o.keyNumber ?? '');
    _notes = TextEditingController(text: o.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _frameSize.dispose();
    _serial.dispose();
    _color.dispose();
    _weight.dispose();
    _purchasedAt.dispose();
    _purchasedFrom.dispose();
    _price.dispose();
    _insurance.dispose();
    _policy.dispose();
    _key.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final existing = BikeOwner.normalizeDate(_purchasedAt.text);
    final now = DateTime.now();
    final initial = existing == null
        ? DateTime(now.year, now.month, now.day)
        : DateTime.parse(existing);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    _purchasedAt.text =
        '${picked.day.toString().padLeft(2, '0')}.'
        '${picked.month.toString().padLeft(2, '0')}.'
        '${picked.year}';
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bike = widget.bike;
      final year = int.tryParse(_year.text.trim());
      final owner = BikeOwner.normalize(
        serialNumber: _serial.text,
        color: _color.text,
        weightKg: _weight.text,
        notes: _notes.text,
        purchasedAt: _purchasedAt.text,
        purchasedFrom: _purchasedFrom.text,
        purchasePriceEur: _price.text,
        insuranceName: _insurance.text,
        insurancePolicy: _policy.text,
        keyNumber: _key.text,
        workshopName: bike.owner.workshopName,
        workshopAddress: bike.owner.workshopAddress,
        workshopPhone: bike.owner.workshopPhone,
        nextServiceAt: bike.owner.nextServiceAt,
        nextServiceNote: bike.owner.nextServiceNote,
        lastServiceAt: bike.owner.lastServiceAt,
        lastServiceWork: bike.owner.lastServiceWork,
        lastServiceAmountEur: bike.owner.lastServiceAmountEur,
        lastServiceNote: bike.owner.lastServiceNote,
        invoicePhotoPath: bike.owner.invoicePhotoPath,
      );
      await ref.read(garageRepositoryProvider).upsert(
            Bike(
              id: bike.id,
              name: resolvedBikeName(
                _name.text,
                bike.category,
                isEbike: bike.isEbike,
              ),
              category: bike.category,
              brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
              model: _model.text.trim().isEmpty ? null : _model.text.trim(),
              year: year != null && year >= 1980 && year <= DateTime.now().year + 1
                  ? year
                  : null,
              wheelSize: bike.wheelSize,
              catalogBikeId: bike.catalogBikeId,
              frameSize: _frameSize.text.trim().isEmpty
                  ? null
                  : _frameSize.text.trim(),
              travelFrontMm: bike.travelFrontMm,
              travelRearMm: bike.travelRearMm,
              odometerKm: bike.odometerKm,
              hours: bike.hours,
              isActive: bike.isActive,
              isEbike: bike.isEbike,
              owner: owner,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.paddingOf(context).bottom;
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const GarageSheetHandle(),
            GarageSheetTitle(
              title: l10n.garageEditBike,
              hint: l10n.garageBikeIdHint,
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: l10n.garageName,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _brand,
              decoration: InputDecoration(
                labelText: l10n.garageBrandOptional,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _model,
              decoration: InputDecoration(
                labelText: l10n.garageModelOptional,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _year,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.garageYear,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextField(
                    controller: _frameSize,
                    decoration: InputDecoration(
                      labelText: l10n.garageFrameSize,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _serial,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.garageSerial,
                hintText: l10n.garageSerialHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _color,
                    decoration: InputDecoration(
                      labelText: l10n.garageColor,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.garageWeightKg,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _purchasedAt,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: l10n.garagePurchasedAt,
                isDense: true,
                suffixIcon: const ChromeGlyph('calendar', size: 18),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _purchasedFrom,
              decoration: InputDecoration(
                labelText: l10n.garagePurchasedFrom,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.garagePurchasePrice,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _insurance,
              decoration: InputDecoration(
                labelText: l10n.garageInsurance,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _policy,
              decoration: InputDecoration(
                labelText: l10n.garageInsurancePolicy,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _key,
              decoration: InputDecoration(
                labelText: l10n.garageKeyNumber,
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
            const SizedBox(height: AppSpacing.s),
            Text(
              l10n.garagePrivateHint,
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.m),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
