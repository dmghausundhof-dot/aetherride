import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/garage/stand_photo.dart';
import '../../l10n/app_localizations.dart';
import 'garage_chrome.dart';
import 'rad_stand_frame.dart';

class StandPhotoCropResult {
  const StandPhotoCropResult({
    required this.file,
    this.yBias = kStandPhotoYBias,
    this.xBias = kStandPhotoXBias,
  });

  final File file;
  final double yBias;
  final double xBias;
}

/// Pan and rotate on the stand. Null = dismissed.
Future<StandPhotoCropResult?> showStandPhotoCropSheet({
  required BuildContext context,
  required File file,
}) async {
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  if (!context.mounted) return null;
  return showModalBottomSheet<StandPhotoCropResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _StandPhotoCropSheet(
      file: file,
      imageWidth: decoded.width.toDouble(),
      imageHeight: decoded.height.toDouble(),
    ),
  );
}

class _StandPhotoCropSheet extends StatefulWidget {
  const _StandPhotoCropSheet({
    required this.file,
    required this.imageWidth,
    required this.imageHeight,
  });

  final File file;
  final double imageWidth;
  final double imageHeight;

  @override
  State<_StandPhotoCropSheet> createState() => _StandPhotoCropSheetState();
}

class _StandPhotoCropSheetState extends State<_StandPhotoCropSheet> {
  late File _file = widget.file;
  late double _w = widget.imageWidth;
  late double _h = widget.imageHeight;
  late double _yBias = kStandPhotoYBias;
  late double _xBias = kStandPhotoXBias;
  var _busy = false;

  bool get _tall => _w / _h < kStandPhotoRatio;

  void _pan(Offset delta, Size viewport) {
    if (viewport.width <= 0 || viewport.height <= 0) return;
    setState(() {
      if (_tall) {
        _yBias = (_yBias - delta.dy / viewport.height).clamp(0.0, 1.0);
      } else {
        _xBias = (_xBias - delta.dx / viewport.width).clamp(0.0, 1.0);
      }
    });
  }

  Future<void> _rotate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final bytes = await _file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final rotated = img.copyRotate(decoded, angle: 90);
    final dir = await getTemporaryDirectory();
    final out = File(
      p.join(dir.path, 'stand_rot_${DateTime.now().millisecondsSinceEpoch}.jpg'),
    );
    await out.writeAsBytes(img.encodeJpg(rotated, quality: 85));
    if (!mounted) return;
    setState(() {
      _file = out;
      _w = rotated.width.toDouble();
      _h = rotated.height.toDouble();
      _yBias = kStandPhotoYBias;
      _xBias = kStandPhotoXBias;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l + bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GarageSheetHandle(),
          GarageSheetTitle(
            title: l10n.garagePhotoCropTitle,
            hint: l10n.garagePhotoCropHint,
          ),
          const SizedBox(height: AppSpacing.m),
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onPanUpdate: (d) => _pan(
                  d.delta,
                  Size(
                    constraints.maxWidth,
                    constraints.maxWidth / kStandPhotoRatio,
                  ),
                ),
                child: RadStandFrame(
                  useStandRatio: true,
                  photo: true,
                  child: Image.file(
                    _file,
                    key: ValueKey(_file.path),
                    fit: BoxFit.cover,
                    alignment: standPhotoAlignment(
                      yBias: _yBias,
                      xBias: _xBias,
                    ),
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.s),
          OutlinedButton(
            key: const Key('stand-photo-crop-rotate'),
            onPressed: _busy ? null : _rotate,
            child: Text(l10n.garagePhotoRotate),
          ),
          const SizedBox(height: AppSpacing.s),
          FilledButton(
            key: const Key('stand-photo-crop-save'),
            onPressed: _busy
                ? null
                : () => Navigator.pop(
                      context,
                      StandPhotoCropResult(
                        file: _file,
                        yBias: _yBias,
                        xBias: _xBias,
                      ),
                    ),
            child: Text(l10n.garagePhotoCropSave),
          ),
        ],
      ),
    );
  }
}
