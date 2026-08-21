import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class BikeStandReading {
  const BikeStandReading({required this.km, required this.hours});
  final double km;
  final double hours;
}

/// km and hours in one sheet — no jump into the Setup tab.
Future<BikeStandReading?> showBikeStandEditor({
  required BuildContext context,
  required double km,
  required double hours,
  bool focusHours = false,
}) {
  return showDialog<BikeStandReading>(
    context: context,
    builder: (ctx) => _BikeStandEditorDialog(
      km: km,
      hours: hours,
      focusHours: focusHours,
    ),
  );
}

class _BikeStandEditorDialog extends StatefulWidget {
  const _BikeStandEditorDialog({
    required this.km,
    required this.hours,
    required this.focusHours,
  });

  final double km;
  final double hours;
  final bool focusHours;

  @override
  State<_BikeStandEditorDialog> createState() => _BikeStandEditorDialogState();
}

class _BikeStandEditorDialogState extends State<_BikeStandEditorDialog> {
  late final TextEditingController _km;
  late final TextEditingController _hours;
  late final FocusNode _kmFocus;
  late final FocusNode _hoursFocus;

  @override
  void initState() {
    super.initState();
    _km = TextEditingController(
      text: widget.km > 0 ? widget.km.toStringAsFixed(0) : '',
    );
    _hours = TextEditingController(
      text: widget.hours > 0 ? widget.hours.toStringAsFixed(1) : '',
    );
    _kmFocus = FocusNode();
    _hoursFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      (widget.focusHours ? _hoursFocus : _kmFocus).requestFocus();
    });
  }

  @override
  void dispose() {
    _km.dispose();
    _hours.dispose();
    _kmFocus.dispose();
    _hoursFocus.dispose();
    super.dispose();
  }

  void _save() {
    final km = double.tryParse(_km.text.replaceAll(',', '.')) ?? 0;
    final hours = double.tryParse(_hours.text.replaceAll(',', '.')) ?? 0;
    Navigator.pop(
      context,
      BikeStandReading(
        km: km.clamp(0, 1e7),
        hours: hours.clamp(0, 1e6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.garageStandTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.garageStandHint,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.garageStandStravaHint,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.m),
          TextField(
            key: const Key('bike-stand-km'),
            controller: _km,
            focusNode: _kmFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.garageOdometer,
              suffixText: 'km',
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          TextField(
            key: const Key('bike-stand-hours'),
            controller: _hours,
            focusNode: _hoursFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.garageOperatingHours,
              suffixText: 'h',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
