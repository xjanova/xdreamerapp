import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/xdr_colors.dart';
import 'motion.dart';

/// The fiber-threads field behind every screen — sixteen slow bezier filaments
/// in the brand hues, drawn additively so where they cross they glow.
///
/// Ported from `FiberThreads` in the web repo with the mobile budget the
/// handoff asks for:
///
/// * **26fps, not 60.** The threads move at ~0.001 rad/ms; nobody can see the
///   difference and the GPU does 40% less work. Enforced by skipping ticks
///   rather than by a `Timer`, so it never runs while the tree is not ticking.
/// * **No accumulation buffer.** The web version fakes a trail by filling the
///   canvas with 9%-opaque background each frame. Doing that in Flutter means
///   round-tripping an offscreen texture every frame, which is exactly the kind
///   of thing that eats a phone battery. A blur on each stroke gives the same
///   soft bloom for one paint per thread.
/// * **Stops when it is not being looked at.** `TickerMode` mutes it on a route
///   that is covered, the lifecycle observer stops it when the app is
///   backgrounded, and reduced-motion freezes it on a single still frame.
class FiberThreads extends StatefulWidget {
  const FiberThreads({super.key, this.threadCount = 16, this.opacity = 0.5});

  final int threadCount;
  final double opacity;

  @override
  State<FiberThreads> createState() => _FiberThreadsState();
}

class _FiberThreadsState extends State<FiberThreads>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;

  /// Drives the painter directly, so a frame never rebuilds the widget tree.
  final _clock = ValueNotifier<double>(0);

  late final List<_Thread> _threads;

  static const _frameIntervalMs = 1000 / 26;
  double _lastPaintedMs = 0;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final random = math.Random();
    _threads = List.generate(widget.threadCount, (i) => _Thread.random(random, i));

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Nothing to animate for a user who is not looking at the screen.
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (!_ticker.isTicking) _ticker.start();
    } else if (_ticker.isTicking) {
      _ticker.stop();
    }
  }

  void _onTick(Duration elapsed) {
    final ms = elapsed.inMicroseconds / 1000.0;
    if (ms - _lastPaintedMs < _frameIntervalMs) return;
    _lastPaintedMs = ms;
    _clock.value = ms;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reducedMotion(context);
    if (still && _ticker.isTicking) {
      _ticker.stop();
    } else if (!still && _foreground && !_ticker.isTicking) {
      _ticker.start();
    }

    return IgnorePointer(
      child: Opacity(
        opacity: widget.opacity,
        child: RepaintBoundary(
          child: CustomPaint(
            isComplex: true,
            willChange: !still,
            painter: _FiberPainter(threads: _threads, clock: _clock),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

/// Brand hues in HSL, already carrying the +70° shift the web version applies.
const _paletteHsl = <List<double>>[
  [160, 85, 55],
  [180, 80, 60],
  [210, 90, 65],
  [250, 75, 68],
  [275, 70, 65],
  [295, 65, 68],
];
const _hueShift = 70.0;

class _Thread {
  _Thread({
    required this.start,
    required this.end,
    required this.control1,
    required this.control2,
    required this.f1,
    required this.f2,
    required this.f3,
    required this.phase,
    required this.width,
    required this.alpha,
    required this.hue,
    required this.saturation,
    required this.lightness,
  });

  factory _Thread.random(math.Random r, int index) {
    final swatch = _paletteHsl[index % _paletteHsl.length];
    double unit() => r.nextDouble();

    return _Thread(
      // Positions are fractions of the canvas so a rotation or a keyboard
      // opening re-lays them out instead of clipping them.
      start: Offset(unit() * 1.2 - 0.1, unit()),
      end: Offset(unit() * 1.2 - 0.1, unit()),
      control1: Offset(unit(), unit()),
      control2: Offset(unit(), unit()),
      f1: 0.0004 + unit() * 0.0008,
      f2: 0.0003 + unit() * 0.0007,
      f3: 0.0002 + unit() * 0.0006,
      phase: unit() * 2 * math.pi,
      width: 0.3 + unit() * 1.3,
      alpha: 0.25 + unit() * 0.5,
      hue: (swatch[0] + _hueShift) % 360,
      saturation: swatch[1] / 100,
      lightness: swatch[2] / 100,
    );
  }

  final Offset start;
  final Offset end;
  final Offset control1;
  final Offset control2;
  final double f1;
  final double f2;
  final double f3;
  final double phase;
  final double width;
  final double alpha;
  final double hue;
  final double saturation;
  final double lightness;

  Color get color =>
      HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();

  /// The +20° companion hue that makes the middle of each filament read as a
  /// different metal from its ends.
  Color get midColor =>
      HSLColor.fromAHSL(1, (hue + 20) % 360, saturation, lightness).toColor();
}

class _FiberPainter extends CustomPainter {
  _FiberPainter({required this.threads, required this.clock}) : super(repaint: clock);

  final List<_Thread> threads;
  final ValueNotifier<double> clock;

  /// Control points swing this far; endpoints swing less, so the filament
  /// bends more than it wanders.
  static const _controlSwing = 120.0;
  static const _endpointSwing = 70.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t = clock.value;

    for (final thread in threads) {
      final p0 = _at(thread.start, size) +
          Offset(
            math.sin(t * thread.f3 + thread.phase) * _endpointSwing,
            math.cos(t * thread.f1 + thread.phase) * _endpointSwing,
          );
      final p3 = _at(thread.end, size) +
          Offset(
            math.cos(t * thread.f1 + thread.phase) * _endpointSwing,
            math.sin(t * thread.f2 + thread.phase) * _endpointSwing,
          );
      final c1 = _at(thread.control1, size) +
          Offset(
            math.sin(t * thread.f1 + thread.phase) * _controlSwing,
            math.cos(t * thread.f2 + thread.phase) * _controlSwing,
          );
      final c2 = _at(thread.control2, size) +
          Offset(
            math.cos(t * thread.f2 + thread.phase) * _controlSwing,
            math.sin(t * thread.f3 + thread.phase) * _controlSwing,
          );

      final transparent = thread.color.withValues(alpha: 0);
      final shader = ui.Gradient.linear(
        p0,
        p3,
        [
          transparent,
          thread.color.withValues(alpha: thread.alpha * 0.5),
          thread.midColor.withValues(alpha: thread.alpha * 0.55),
          thread.color.withValues(alpha: thread.alpha * 0.5),
          transparent,
        ],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

      final paint = Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = thread.width
        ..strokeCap = StrokeCap.round
        // `lighter` in the web version. Where filaments cross they add up.
        ..blendMode = BlendMode.plus
        // Stands in for the accumulated trail — same bloom, no offscreen pass.
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p3.dx, p3.dy),
        paint,
      );
    }
  }

  Offset _at(Offset fraction, Size size) =>
      Offset(fraction.dx * size.width, fraction.dy * size.height);

  @override
  bool shouldRepaint(covariant _FiberPainter oldDelegate) =>
      oldDelegate.threads != threads;
}

/// The three-layer ground every screen sits on: base colour, the thread field,
/// then a vignette that pushes the threads back behind the content.
class XdrBackdrop extends StatelessWidget {
  const XdrBackdrop({super.key, required this.child, this.threads = true});

  final Widget child;

  /// Off for screens that carry their own full-bleed artwork (onboarding).
  final bool threads;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: XdrColors.base,
      child: Stack(
        children: [
          if (threads) const Positioned.fill(child: FiberThreads()),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.56),
                    radius: 1.1,
                    colors: [
                      Color(0x59030612),
                      Color(0xD1030612),
                      Color(0xF5030612),
                    ],
                    stops: [0.0, 0.58, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
