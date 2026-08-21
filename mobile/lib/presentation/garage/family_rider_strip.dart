import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/garage/family_setup_memory.dart';
import '../../domain/rider_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';

/// Rider chips on the stand — weight and setup follow the selected person.
class FamilyRiderStrip extends ConsumerWidget {
  const FamilyRiderStrip({
    super.key,
    required this.bikeId,
    this.onChanged,
  });

  final String bikeId;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(userProfileStoreProvider);
    final riders = store.familyRiders;
    final l10n = AppLocalizations.of(context);
    final active = store.activeFamilyRiderId;

    return Padding(
      key: const Key('garage-family-strip'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.s,
        AppSpacing.l,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            riders.isEmpty ? l10n.garageFamilyHintEmpty : l10n.garageFamilyHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(
                label: l10n.garageFamilyYou,
                selected: active == null,
                onTap: () => _select(ref, null),
              ),
              for (final r in riders)
                _chip(
                  label: '${r.displayName} · ${r.weightKg.round()} kg',
                  selected: active == r.id,
                  onTap: () => _select(ref, r),
                ),
              _addChip(
                label: l10n.garageFamilyAdd,
                onTap: () => _add(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.chrome : AppColors.chipIdle,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.chrome : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.onAccent : AppColors.chipIdleText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: CustomPaint(
        painter: _DashedPillPainter(color: AppColors.border),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '70');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.garageFamilyAdd),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: loc.profileName),
              ),
              TextField(
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: loc.profileWeightKg),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(loc.add),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final store = ref.read(userProfileStoreProvider);
    final l10n = AppLocalizations.of(context);
    final riders = [
      ...store.familyRiders,
      FamilyRider(
        id: const Uuid().v4(),
        displayName: nameCtrl.text.trim().isEmpty
            ? l10n.profileRiderFallback
            : nameCtrl.text.trim(),
        weightKg: double.tryParse(weightCtrl.text) ?? 70,
      ),
    ];
    await store.setFamilyRiders(riders);
    await ref.read(garageRepositoryProvider).touchLocalSync();
    onChanged?.call();
  }

  Future<void> _select(WidgetRef ref, FamilyRider? rider) async {
    final store = ref.read(userProfileStoreProvider);
    final setups = await ref.read(setupRepositoryProvider).listForBike(bikeId);
    final current = setups.where((s) => s.isCurrent).firstOrNull;
    final snap = snapshotOwnSetup(
      activeRiderId: store.activeFamilyRiderId,
      currentSetupId: current?.id,
    );
    if (snap != null) await store.rememberOwnSetup(bikeId, snap);
    await store.setActiveFamilyRider(rider?.id);
    final next = setupToApplyOnFamilySwitch(
      nextRiderId: rider?.id,
      rememberedOwnId: store.ownSetupFor(bikeId),
      nextRiderSetupIds: rider?.setupIds ?? const [],
      existingSetupIds: setups.map((s) => s.id),
      familyOwnedSetupIds: [
        for (final r in store.familyRiders) ...r.setupIds,
      ],
      currentSetupId: current?.id,
    );
    if (next != null && next != current?.id) {
      await ref.read(setupRepositoryProvider).setCurrent(bikeId, next);
    }
    ref.invalidate(currentSetupProvider(bikeId));
    onChanged?.call();
  }
}

class _DashedPillPainter extends CustomPainter {
  _DashedPillPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      const dash = 4.0;
      const gap = 3.0;
      while (d < metric.length) {
        final end = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, end), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPillPainter oldDelegate) =>
      oldDelegate.color != color;
}
