import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/xdr_colors.dart';

/// The five machined finishes the whole app is cut from.
///
/// Every surface in X-DREAMER is a piece of metal with a real edge: a lit top
/// bevel, a dark bottom bevel and a shadow underneath. Reproducing CSS `inset`
/// shadows in Flutter is not possible with `BoxDecoration` alone, so each
/// finish is drawn as a clipped stack — face gradient, then edges, then
/// content. That is also why these are widgets rather than `BoxDecoration`
/// helpers.
enum MetalFinish {
  /// Cards, panels, sheets. Replaces every `glass` surface in the older spec.
  plate,

  /// A channel milled into the plate: prompt fields, progress tracks, the
  /// active segment of a control group.
  sunk,

  /// A raised key: secondary buttons, inactive chips, the action bar.
  keycap,

  /// Anodised blue — whichever option is currently selected.
  anodized,

  /// Brand-coloured knob: primary CTAs and the FAB.
  knob,
}

/// How a finish's top and bottom edges are drawn.
class _Edge {
  const _Edge.line(this.color, this.thickness) : fades = false;
  const _Edge.shade(this.color, this.thickness) : fades = true;

  final Color color;
  final double thickness;

  /// A hard 1–2px line (a bevel) or a soft band fading inward (an inset shadow).
  final bool fades;
}

class _FinishSpec {
  const _FinishSpec({
    required this.face,
    required this.top,
    required this.bottom,
    this.shadows = const [],
  });

  final Gradient face;
  final _Edge top;
  final _Edge bottom;
  final List<BoxShadow> shadows;
}

const _specs = <MetalFinish, _FinishSpec>{
  MetalFinish.plate: _FinishSpec(
    face: XdrColors.plateFace,
    top: _Edge.line(Color(0x21FFFFFF), 1.5),
    bottom: _Edge.line(Color(0xB3000000), 1.5),
    shadows: [
      BoxShadow(color: Color(0xFA000000), blurRadius: 28, spreadRadius: -20, offset: Offset(0, 14)),
    ],
  ),
  MetalFinish.sunk: _FinishSpec(
    face: XdrColors.sunkFace,
    top: _Edge.shade(Color(0xE6000000), 7),
    bottom: _Edge.line(Color(0x12FFFFFF), 1),
  ),
  MetalFinish.keycap: _FinishSpec(
    face: XdrColors.keycapFace,
    top: _Edge.line(Color(0x33FFFFFF), 1),
    bottom: _Edge.line(Color(0xB3000000), 1),
    shadows: [
      BoxShadow(color: Color(0xF2000000), blurRadius: 12, spreadRadius: -7, offset: Offset(0, 5)),
    ],
  ),
  MetalFinish.anodized: _FinishSpec(
    face: XdrColors.anodizedFace,
    top: _Edge.line(Color(0x73FFFFFF), 1.5),
    bottom: _Edge.shade(Color(0x73000000), 7),
    shadows: [
      BoxShadow(color: Color(0xD906B6D4), blurRadius: 16, spreadRadius: -7, offset: Offset(0, 6)),
    ],
  ),
  MetalFinish.knob: _FinishSpec(
    face: XdrColors.knobFace,
    top: _Edge.line(Color(0x8CFFFFFF), 2),
    bottom: _Edge.shade(Color(0x6B000000), 10),
    shadows: [
      BoxShadow(color: Color(0xF27C4DDB), blurRadius: 36, spreadRadius: -12, offset: Offset(0, 18)),
      BoxShadow(color: Color(0xA6000000), offset: Offset(0, 3)),
    ],
  ),
};

/// A single machined surface.
class MetalSurface extends StatelessWidget {
  const MetalSurface({
    super.key,
    required this.child,
    this.finish = MetalFinish.plate,
    this.radius = 18,
    this.padding,
    this.brushed = false,
    this.glow,
    this.borderColor,
    this.borderWidth = 1,
    this.faceOverride,
    this.dropShadows = true,
  });

  final Widget child;
  final MetalFinish finish;
  final double radius;
  final EdgeInsetsGeometry? padding;

  /// Adds the diagonal brushed-metal striping. Reserve it for the few plates
  /// that should read as the heaviest pieces — it costs a line per 3px.
  final bool brushed;

  /// An extra coloured halo under the surface, e.g. the violet bloom on the
  /// generating panel.
  final Color? glow;

  final Color? borderColor;
  final double borderWidth;

  /// Replaces the finish's face gradient while keeping its edges and shadows —
  /// used by the "popular" pricing tier, which is a plate tinted brand colours.
  final Gradient? faceOverride;

  /// Turn off when the surface sits inside something already casting a shadow,
  /// so overlapping darkness does not stack into a smear.
  final bool dropShadows;

  @override
  Widget build(BuildContext context) {
    final spec = _specs[finish]!;
    final corner = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corner,
        boxShadow: [
          if (dropShadows) ...spec.shadows,
          if (glow != null) BoxShadow(color: glow!, blurRadius: 44, spreadRadius: -14),
        ],
      ),
      child: ClipRRect(
        borderRadius: corner,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: faceOverride ?? spec.face),
              ),
            ),
            if (brushed)
              const Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _BrushedPainter())),
              ),
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    _edge(spec.top, top: true),
                    _edge(spec.bottom, top: false),
                    if (borderColor != null)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: corner,
                            border: Border.all(color: borderColor!, width: borderWidth),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _edge(_Edge edge, {required bool top}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: edge.thickness,
      child: edge.fades
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                  end: top ? Alignment.bottomCenter : Alignment.topCenter,
                  colors: [edge.color, edge.color.withValues(alpha: 0)],
                ),
              ),
            )
          : ColoredBox(color: edge.color),
    );
  }
}

/// A metal ring around framed art or an icon tile — light at the top-left,
/// black at the bottom-right, so the thing inside reads as recessed into it.
class BevelRing extends StatelessWidget {
  const BevelRing({
    super.key,
    required this.child,
    this.radius = 16,
    this.thickness = 2,
  });

  final Widget child;
  final double radius;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(thickness),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: XdrColors.bevelRing,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(0, radius - thickness)),
        child: child,
      ),
    );
  }
}

/// Fine diagonal striping — brushed aluminium, at the 112° of the spec.
class _BrushedPainter extends CustomPainter {
  const _BrushedPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x05FFFFFF)
      ..strokeWidth = 1;

    // 112° from the horizontal, i.e. leaning back slightly past vertical.
    const angle = 112 * math.pi / 180;
    final dx = math.cos(angle);
    final dy = math.sin(angle);
    final span = size.width + size.height;

    for (double offset = -size.height; offset < span; offset += 3) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + dx * size.height / dy, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BrushedPainter oldDelegate) => false;
}
