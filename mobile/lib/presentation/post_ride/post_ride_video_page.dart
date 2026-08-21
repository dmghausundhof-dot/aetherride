import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Fullscreen playback for a locally stored ride clip.
class PostRideVideoPage extends StatefulWidget {
  const PostRideVideoPage({super.key, required this.path});

  final String path;

  @override
  State<PostRideVideoPage> createState() => _PostRideVideoPageState();
}

class _PostRideVideoPageState extends State<PostRideVideoPage> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final file = File(widget.path);
    if (!file.existsSync()) {
      setState(() => _error = 'missing');
      return;
    }
    final c = VideoPlayerController.file(file);
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      await c.setLooping(true);
      await c.play();
      setState(() => _controller = c);
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _error = 'fail');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.postRideVideoPlay),
      ),
      body: Center(
        child: _error != null
            ? Text(
                l10n.postRideVideoMissing,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              )
            : c == null
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: () {
                      if (c.value.isPlaying) {
                        c.pause();
                      } else {
                        c.play();
                      }
                      setState(() {});
                    },
                    child: AspectRatio(
                      aspectRatio:
                          c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          VideoPlayer(c),
                          if (!c.value.isPlaying)
                            const Icon(
                              Icons.play_circle_fill,
                              size: 64,
                              color: Colors.white70,
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: c == null
          ? null
          : ColoredBox(
              color: Colors.black,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: VideoProgressIndicator(
                    c,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.accent,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
