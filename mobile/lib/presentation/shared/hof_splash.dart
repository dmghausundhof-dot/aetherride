import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Official FlowLine boot (vector GIF, portrait lockup, never cropped).
///
/// [Image.asset] keeps GIFs on the first frame under Impeller. We decode
/// frames with [ui.instantiateImageCodec] and paint each one as [RawImage].
class HofSplash extends StatefulWidget {
  const HofSplash({super.key, this.onFinished});

  static const Color bg = Color(0xFFFAFAFA);
  static const Duration motion = Duration(milliseconds: 3000);
  static const String gifAsset = 'assets/brand/boot.gif';

  final VoidCallback? onFinished;

  @override
  State<HofSplash> createState() => _HofSplashState();
}

class _HofSplashState extends State<HofSplash> {
  ui.Codec? _codec;
  ui.Image? _frame;
  Timer? _pause;
  Completer<void>? _gate;
  var _index = 0;
  var _dueMs = 0;
  var _finished = false;
  DateTime? _origin;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final data = await rootBundle.load(HofSplash.gifAsset);
      if (!mounted) return;
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      if (!mounted) {
        codec.dispose();
        return;
      }
      _codec = codec;
      _origin = DateTime.now();
      await _play();
    } catch (_) {
      _finish();
    }
  }

  Future<void> _play() async {
    final codec = _codec;
    final origin = _origin;
    if (codec == null || origin == null) {
      _finish();
      return;
    }
    while (mounted && _index < codec.frameCount) {
      final info = await codec.getNextFrame();
      if (!mounted) {
        info.image.dispose();
        return;
      }
      _index += 1;
      _dueMs += info.duration.inMilliseconds;
      final previous = _frame;
      setState(() => _frame = info.image);
      previous?.dispose();
      if (_index < codec.frameCount) {
        final elapsed = DateTime.now().difference(origin).inMilliseconds;
        if (elapsed < _dueMs) {
          await _sleep(Duration(milliseconds: _dueMs - elapsed));
        }
      }
    }
    if (mounted) {
      await _sleep(const Duration(milliseconds: 420));
    }
    _finish();
  }

  Future<void> _sleep(Duration duration) {
    final gate = Completer<void>();
    _gate = gate;
    _pause?.cancel();
    _pause = Timer(duration, () {
      if (!gate.isCompleted) gate.complete();
    });
    return gate.future;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished?.call();
  }

  @override
  void dispose() {
    _pause?.cancel();
    final gate = _gate;
    if (gate != null && !gate.isCompleted) gate.complete();
    _codec?.dispose();
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: HofSplash.bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: HofSplash.bg,
        child: SizedBox.expand(
          child: _frame == null
              ? const SizedBox.expand()
              : RawImage(
                  image: _frame,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
        ),
      ),
    );
  }
}
