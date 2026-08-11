import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/xdr_motion.dart';

/// Press feedback for the Metal edition: controls **sink**, they do not shrink.
///
/// The earlier flat-glass revision scaled buttons down on press. Metal reads
/// wrong that way — a key that gets smaller looks like it is receding, not like
/// it has been pushed. So the child travels 2–3px down the z-axis and an inner
/// shadow appears along its top edge, which is what actually happens when a key
/// bottoms out.
///
/// Wrap the whole tappable thing, including its [MetalSurface]; the hit target
/// is whatever the child measures, so keep it ≥ 44px.
class PressSink extends StatefulWidget {
  const PressSink({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.depth = XdrMotion.pressDepth,
    this.radius = 14,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double depth;

  /// Match the child's corner radius so the press shadow clips to its shape.
  final double radius;
  final bool haptic;

  @override
  State<PressSink> createState() => _PressSinkState();
}

class _PressSinkState extends State<PressSink> with SingleTickerProviderStateMixin {
  late final AnimationController _sink = AnimationController(
    vsync: this,
    duration: XdrMotion.press,
    reverseDuration: XdrMotion.press,
  );

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  void dispose() {
    _sink.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) => _sink.forward();
  void _up(TapUpDetails _) => _sink.reverse();
  void _cancel() => _sink.reverse();

  void _tap() {
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? _down : null,
      onTapUp: _enabled ? _up : null,
      onTapCancel: _enabled ? _cancel : null,
      onTap: widget.onTap == null ? null : _tap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _sink,
        child: widget.child,
        builder: (context, child) {
          final t = _sink.value;
          return Transform.translate(
            offset: Offset(0, t * widget.depth),
            child: Stack(
              children: [
                child!,
                if (t > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(widget.radius),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55 * t),
                                Colors.black.withValues(alpha: 0.10 * t),
                              ],
                              stops: const [0.0, 0.35],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
