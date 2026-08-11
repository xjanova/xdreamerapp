import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/xdr_colors.dart';
import '../theme/xdr_motion.dart';

/// True when the OS asks for reduced motion.
///
/// Everything decorative — sheen, pulse, float, the fiber-threads canvas — must
/// go still when this is set. Functional motion (a screen entering, a sheet
/// opening) still runs, just without the flourish.
bool reducedMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// `xdrUp` — fade in and rise 14px over 420ms. Every screen entrance, and any
/// panel that replaces another in place.
class XdrEnter extends StatefulWidget {
  const XdrEnter({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<XdrEnter> createState() => _XdrEnterState();
}

class _XdrEnterState extends State<XdrEnter> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: XdrMotion.enter,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        // The screen can be popped before a staggered child ever starts.
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: XdrMotion.ease);
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * XdrMotion.enterRise),
          child: child,
        ),
      ),
    );
  }
}

/// `xdrSheen` — a bar of light sweeping across a primary button every 3s.
class Sheen extends StatefulWidget {
  const Sheen({super.key, required this.child, this.radius = 18});

  final Widget child;
  final double radius;

  @override
  State<Sheen> createState() => _SheenState();
}

class _SheenState extends State<Sheen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: XdrMotion.sheen,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncToMotionPreference();
  }

  void _syncToMotionPreference() {
    if (reducedMotion(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return widget.child;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final eased = Curves.easeInOut.transform(_c.value);
                  return FractionalTranslation(
                    // -45% → 135% of its own width, as in the keyframe.
                    translation: Offset(-0.45 + eased * 1.8, 0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `xdrPulse` — the violet halo breathing behind the FAB.
class PulseHalo extends StatefulWidget {
  const PulseHalo({super.key, required this.size, this.color = XdrColors.violet});

  final double size;
  final Color color;

  @override
  State<PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<PulseHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: XdrMotion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return Transform.scale(
            scale: 1 + t * 0.12,
            child: Opacity(
              opacity: 0.45 + t * 0.45,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.45),
                      widget.color.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// `xdrFloat` — the onboarding logo drifting 10px over 6s.
class FloatBob extends StatefulWidget {
  const FloatBob({super.key, required this.child});

  final Widget child;

  @override
  State<FloatBob> createState() => _FloatBobState();
}

class _FloatBobState extends State<FloatBob> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: XdrMotion.float,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -10 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
    );
  }
}

/// `xdrBlink` — the caret at the end of the prompt. `steps(1)`, so it snaps
/// rather than fades.
class BlinkingCaret extends StatefulWidget {
  const BlinkingCaret({super.key, this.height = 15, this.width = 2});

  final double height;
  final double width;

  @override
  State<BlinkingCaret> createState() => _BlinkingCaretState();
}

class _BlinkingCaretState extends State<BlinkingCaret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: XdrMotion.blink,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: _c.value < 0.5 ? 1 : 0,
        child: Container(
          width: widget.width,
          height: widget.height,
          color: XdrColors.ice,
        ),
      ),
    );
  }
}

/// `xdrShim` — the skeleton sweep on a pending result tile.
///
/// Hand-rolled rather than pulled from a package because the design staggers
/// four tiles by 200ms each, which the usual shimmer widgets do not expose.
class ShimmerTile extends StatefulWidget {
  const ShimmerTile({super.key, this.radius = 14, this.index = 0});

  final double radius;
  final int index;

  @override
  State<ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<ShimmerTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: XdrMotion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reducedMotion(context)) {
      _c.stop();
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat();
      // Stagger by starting each tile part-way through the cycle rather than
      // with a delayed timer — no timer to leak if the panel is torn down.
      _c.value = (widget.index * XdrMotion.shimmerStagger.inMilliseconds) /
          XdrMotion.shimmer.inMilliseconds %
          1.0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final shift = 1.3 - _c.value * 2.6;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(shift - 1, -0.4),
                end: Alignment(shift + 1, 0.4),
                colors: [
                  Colors.white.withValues(alpha: 0.03),
                  XdrColors.ice.withValues(alpha: 0.13),
                  Colors.white.withValues(alpha: 0.03),
                ],
                stops: const [0.3, 0.5, 0.7],
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

/// `xdrSpin` — the conic brand ring around the progress percentage.
class SpinRing extends StatefulWidget {
  const SpinRing({
    super.key,
    required this.size,
    required this.child,
    this.ringWidth = 5,
  });

  final double size;
  final double ringWidth;
  final Widget child;

  @override
  State<SpinRing> createState() => _SpinRingState();
}

class _SpinRingState extends State<SpinRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: XdrMotion.spin,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This one keeps turning even under reduced motion — it is the only signal
    // that a 60-second video job is still alive. It is slowed instead.
    if (!_c.isAnimating) {
      _c.repeat();
      if (reducedMotion(context)) _c.duration = XdrMotion.spin * 3;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Transform.rotate(
              angle: _c.value * 2 * math.pi,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      XdrColors.emerald,
                      XdrColors.cyan,
                      XdrColors.violet,
                      XdrColors.emerald,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: widget.size - widget.ringWidth * 2,
            height: widget.size - widget.ringWidth * 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: XdrColors.wellFill,
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
