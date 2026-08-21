import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/bike.dart';
import '../../domain/bike_owner.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import 'bike_receipts_panel.dart';
import 'garage_chrome.dart';
import '../shared/chrome_glyph.dart';
import 'rad_glyph.dart';

class ServiceCareCard extends ConsumerWidget {
  const ServiceCareCard({
    super.key,
    required this.bike,
    this.onChanged,
  });

  final Bike bike;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final o = bike.owner;
    final days = o.daysUntilService();
    return Container(
      decoration: garageCardDecoration(),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GarageSectionTitle(
            label: l10n.garageServiceTitle,
            mark: 'care',
          ),
          Align(
            alignment: Alignment.centerRight,
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 0,
              children: [
                TextButton(
                  onPressed: () => _open(context, ref),
                  child: Text(
                    o.hasServiceAppointment ||
                            o.hasWorkshop ||
                            o.hasLastService
                        ? l10n.garageServiceChange
                        : l10n.garageServiceAdd,
                  ),
                ),
                if (o.hasServiceAppointment)
                  TextButton(
                    onPressed: () => _clear(context, ref),
                    child: Text(l10n.delete),
                  ),
              ],
            ),
          ),
          if (o.hasServiceAppointment)
            Text(
              [
                BikeOwner.formatDate(o.nextServiceAt!),
                if (days != null && days < 0) l10n.garageServiceOverdue,
                if (days != null && days == 0) l10n.garageServiceToday,
                if (o.nextServiceNote != null) o.nextServiceNote!,
              ].join(' · '),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              l10n.garageServiceEmpty,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          if (o.hasWorkshop) ...[
            const SizedBox(height: 4),
            Text(
              [
                if ((o.workshopName ?? '').trim().isNotEmpty) o.workshopName!,
                if ((o.workshopAddress ?? '').trim().isNotEmpty)
                  o.workshopAddress!,
                if ((o.workshopPhone ?? '').trim().isNotEmpty) o.workshopPhone!,
              ].join(' · '),
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.m),
          Text(
            l10n.garageLastServiceTitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          if (o.hasLastService)
            Text(
              [
                if (o.lastServiceAt != null)
                  BikeOwner.formatDate(o.lastServiceAt!),
                if ((o.lastServiceWork ?? '').trim().isNotEmpty)
                  o.lastServiceWork!,
                if (o.lastServiceAmountEur != null)
                  '${o.lastServiceAmountEur!.toStringAsFixed(0)} €',
              ].join(' · '),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            )
          else
            Text(
              l10n.garageLastServiceEmpty,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          if (o.hasInvoicePhoto) ...[
            const SizedBox(height: 4),
            Text(
              l10n.garageInvoicePhoto,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    await ref.read(garageRepositoryProvider).upsert(
          bike.copyWith(owner: bike.owner.clearServiceAppointment()),
        );
    ref.invalidate(bikesProvider);
    onChanged?.call();
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final ok = await showServiceCareEditor(context, ref, bike);
    if (ok) onChanged?.call();
  }
}

Future<bool> showServiceCareEditor(
  BuildContext context,
  WidgetRef ref,
  Bike bike,
) async {
  final saved = await showModalBottomSheet<BikeOwner>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ServiceCareSheet(bikeId: bike.id, owner: bike.owner),
  );
  if (saved == null) return false;
  await ref.read(garageRepositoryProvider).upsert(
        bike.copyWith(owner: saved),
      );
  ref.invalidate(bikesProvider);
  return true;
}

class _ServiceCareSheet extends StatefulWidget {
  const _ServiceCareSheet({required this.bikeId, required this.owner});

  final String bikeId;
  final BikeOwner owner;

  @override
  State<_ServiceCareSheet> createState() => _ServiceCareSheetState();
}

class _ServiceCareSheetState extends State<_ServiceCareSheet> {
  late final TextEditingController _date;
  late final TextEditingController _note;
  late final TextEditingController _shop;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _lastDate;
  late final TextEditingController _lastWork;
  late final TextEditingController _lastAmount;
  late final TextEditingController _lastNote;
  String? _invoicePath;

  @override
  void initState() {
    super.initState();
    final o = widget.owner;
    _date = TextEditingController(
      text: o.nextServiceAt == null ? '' : BikeOwner.formatDate(o.nextServiceAt!),
    );
    _note = TextEditingController(text: o.nextServiceNote ?? '');
    _shop = TextEditingController(text: o.workshopName ?? '');
    _address = TextEditingController(text: o.workshopAddress ?? '');
    _phone = TextEditingController(text: o.workshopPhone ?? '');
    _lastDate = TextEditingController(
      text: o.lastServiceAt == null ? '' : BikeOwner.formatDate(o.lastServiceAt!),
    );
    _lastWork = TextEditingController(text: o.lastServiceWork ?? '');
    _lastAmount = TextEditingController(
      text: o.lastServiceAmountEur?.toStringAsFixed(0) ?? '',
    );
    _lastNote = TextEditingController(text: o.lastServiceNote ?? '');
    _invoicePath = o.invoicePhotoPath;
  }

  @override
  void dispose() {
    _date.dispose();
    _note.dispose();
    _shop.dispose();
    _address.dispose();
    _phone.dispose();
    _lastDate.dispose();
    _lastWork.dispose();
    _lastAmount.dispose();
    _lastNote.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool last}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1980),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    final text =
        '${picked.day.toString().padLeft(2, '0')}.'
        '${picked.month.toString().padLeft(2, '0')}.'
        '${picked.year}';
    if (last) {
      _lastDate.text = text;
    } else {
      _date.text = text;
    }
  }

  Future<void> _pickInvoice() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      imageQuality: 82,
    );
    if (picked == null) return;
    final path = await persistReceiptPhoto(
      bikeId: widget.bikeId,
      sourcePath: picked.path,
    );
    if (!mounted) return;
    setState(() => _invoicePath = path);
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
              title: l10n.garageServiceTitle,
              hint: l10n.garageServiceHint,
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _date,
              readOnly: true,
              onTap: () => _pickDate(last: false),
              decoration: InputDecoration(
                labelText: l10n.garageServiceDateLabel,
                suffixIcon: const ChromeGlyph('calendar', size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _note,
              decoration: InputDecoration(
                labelText: l10n.garageServiceNoteLabel,
                hintText: l10n.garageServiceNoteHint,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              l10n.garageWorkshopOptional,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _shop,
              decoration: InputDecoration(
                labelText: l10n.garageName,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _address,
              decoration: InputDecoration(
                labelText: l10n.garageWorkshopAddress,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.garageWorkshopPhone,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              l10n.garageLastServiceTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _lastDate,
              readOnly: true,
              onTap: () => _pickDate(last: true),
              decoration: InputDecoration(
                labelText: l10n.garageLastServiceDate,
                suffixIcon: const ChromeGlyph('calendar', size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _lastWork,
              decoration: InputDecoration(
                labelText: l10n.garageLastServiceWork,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _lastAmount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.garageLastServiceAmount,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            TextField(
              controller: _lastNote,
              decoration: InputDecoration(
                labelText: l10n.garageLastServiceNote,
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            OutlinedButton.icon(
              onPressed: _pickInvoice,
              icon: const RadGlyph('photo', size: 18),
              label: Text(
                _invoicePath == null
                    ? l10n.garageInvoiceAdd
                    : l10n.garageInvoicePhoto,
              ),
            ),
            if (_invoicePath != null) ...[
              TextButton(
                onPressed: () => setState(() => _invoicePath = null),
                child: Text(l10n.garageInvoiceRemove),
              ),
              if (File(_invoicePath!).existsSync())
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    child: Image.file(
                      File(_invoicePath!),
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.m),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  BikeOwner.normalize(
                    serialNumber: widget.owner.serialNumber,
                    color: widget.owner.color,
                    weightKg: widget.owner.weightKg,
                    notes: widget.owner.notes,
                    purchasedAt: widget.owner.purchasedAt,
                    purchasedFrom: widget.owner.purchasedFrom,
                    purchasePriceEur: widget.owner.purchasePriceEur,
                    insuranceName: widget.owner.insuranceName,
                    insurancePolicy: widget.owner.insurancePolicy,
                    keyNumber: widget.owner.keyNumber,
                    workshopName: _shop.text,
                    workshopAddress: _address.text,
                    workshopPhone: _phone.text,
                    nextServiceAt: _date.text,
                    nextServiceNote: _note.text,
                    lastServiceAt: _lastDate.text,
                    lastServiceWork: _lastWork.text,
                    lastServiceAmountEur: _lastAmount.text,
                    lastServiceNote: _lastNote.text,
                    invoicePhotoPath: _invoicePath,
                  ),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
