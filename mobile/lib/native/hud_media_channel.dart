import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/hud_media.dart';
import 'native_channels.dart';

/// Android MediaSession / media-keys bridge for the Ride HUD.
class HudMediaChannel {
  HudMediaChannel({
    MethodChannel? method,
    EventChannel? events,
  })  : _method = method ?? const MethodChannel(NativeChannels.hudMedia),
        _events = events ??
            const EventChannel('${NativeChannels.hudMedia}/now_playing');

  final MethodChannel _method;
  final EventChannel _events;

  StreamSubscription<dynamic>? _sub;
  final _controller = StreamController<HudNowPlaying>.broadcast();
  HudNowPlaying _last = HudNowPlaying.idle;
  Future<void> _queue = Future.value();
  bool _wantWatch = false;

  Stream<HudNowPlaying> get nowPlaying => _controller.stream;
  HudNowPlaying get last => _last;

  bool get _supported => supported;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static Future<bool> listenerEnabled() async {
    if (!supported) return false;
    try {
      return await const MethodChannel(NativeChannels.hudMedia)
              .invokeMethod<bool>('isListenerEnabled') ==
          true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<void> openListenerSettings() async {
    if (!supported) return;
    try {
      await const MethodChannel(NativeChannels.hudMedia)
          .invokeMethod('openListenerSettings');
    } on MissingPluginException {
      // iOS / tests
    } on PlatformException {
      // settings unavailable
    }
  }

  Future<void> startWatching() async {
    if (!_supported) return;
    _wantWatch = true;
    await _enqueue(_startBody);
  }

  Future<void> stopWatching() async {
    _wantWatch = false;
    _last = HudNowPlaying.idle;
    if (!_supported) return;
    await _enqueue(_stopBody);
  }

  Future<void> _enqueue(Future<void> Function() op) {
    final done = Completer<void>();
    _queue = _queue.then((_) async {
      try {
        await op();
      } catch (_) {
      } finally {
        if (!done.isCompleted) done.complete();
      }
    }).catchError((_) {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  Future<void> _startBody() async {
    if (!_wantWatch) return;
    _sub ??= _events.receiveBroadcastStream().listen(
      (raw) {
        if (!_wantWatch) return;
        final next = HudNowPlaying.fromMap(raw);
        _last = next;
        if (!_controller.isClosed) _controller.add(next);
      },
      onError: (_) {},
    );
    final snap = await _invoke('start');
    if (!_wantWatch) {
      await _stopBody();
      return;
    }
    if (snap != null) {
      final next = HudNowPlaying.fromMap(snap);
      _last = next;
      if (!_controller.isClosed) _controller.add(next);
    }
  }

  Future<void> _stopBody() async {
    await _sub?.cancel();
    _sub = null;
    _last = HudNowPlaying.idle;
    await _invoke('stop');
  }

  Future<void> playPause() async {
    await _invoke('playPause');
  }

  Future<void> skipNext() async {
    await _invoke('skipNext');
  }

  Future<void> skipPrevious() async {
    await _invoke('skipPrevious');
  }

  Future<void> openPlayer() async {
    await _invoke('openPlayer');
  }

  Future<dynamic> _invoke(String method) async {
    if (!_supported) return null;
    try {
      return await _method.invokeMethod(method);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> dispose() async {
    await stopWatching();
    await _controller.close();
  }
}
