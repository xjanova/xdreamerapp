import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/xdr_colors.dart';
import 'common.dart';
import 'motion.dart';
import 'press.dart';

/// Shows a finished result — a still, or a clip with tap-to-play.
///
/// The controller is created per URL and disposed when the URL changes or the
/// widget goes away; a video player left running behind a closed screen is the
/// classic way to keep a phone warm for no reason.
class ResultMedia extends StatefulWidget {
  const ResultMedia({super.key, required this.url, required this.isVideo, this.fit = BoxFit.cover});

  final String? url;
  final bool isVideo;
  final BoxFit fit;

  @override
  State<ResultMedia> createState() => _ResultMediaState();
}

class _ResultMediaState extends State<ResultMedia> {
  VideoPlayerController? _player;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant ResultMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.isVideo != widget.isVideo) {
      _close();
      _open();
    }
  }

  Future<void> _open() async {
    final url = widget.url;
    if (!widget.isVideo || url == null || url.isEmpty) return;

    final player = VideoPlayerController.networkUrl(Uri.parse(url));
    _player = player;
    try {
      await player.initialize();
      await player.setLooping(true);
      // The widget can be gone before a 20MB clip finishes buffering.
      if (!mounted || _player != player) {
        await player.dispose();
        return;
      }
      setState(() {});
    } catch (_) {
      if (!mounted || _player != player) return;
      setState(() => _failed = true);
    }
  }

  void _close() {
    final player = _player;
    _player = null;
    _failed = false;
    player?.dispose();
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _togglePlay() {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;
    setState(() => player.value.isPlaying ? player.pause() : player.play());
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVideo) {
      return RemoteArt(url: widget.url, fit: widget.fit);
    }

    final player = _player;
    if (_failed) {
      return const ColoredBox(
        color: XdrColors.wellFill,
        child: Center(child: Icon(Icons.videocam_off_outlined, color: XdrColors.textDim, size: 24)),
      );
    }
    if (player == null || !player.value.isInitialized) {
      return const ShimmerTile(radius: 0);
    }

    return PressSink(
      radius: 0,
      depth: 0,
      haptic: false,
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: player.value.size.width,
              height: player.value.size.height,
              child: VideoPlayer(player),
            ),
          ),
          if (!player.value.isPlaying)
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: XdrColors.inkwell.withValues(alpha: 0.62),
                  border: Border.all(color: XdrColors.ice.withValues(alpha: 0.35)),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: XdrColors.ice, size: 28),
              ),
            ),
        ],
      ),
    );
  }
}
