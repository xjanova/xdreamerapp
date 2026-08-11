import 'package:flutter/material.dart';

/// X-DREAMER palette, Metal edition.
///
/// Values come straight from the design handoff
/// (`design/design_handoff_xdreamer_mobile/README.md`). The Metal revision
/// lifted the page base from `#030612` to `#05080f` so the bevel edges on every
/// plate stay readable against it — do not change one without the other.
abstract final class XdrColors {
  // ── Ground ──────────────────────────────────────────────────────────────
  static const base = Color(0xFF05080F);
  static const scrim = Color(0xFF04070E);

  /// The near-black the brand shipped with. Still used inside knobs and rings
  /// where a lighter ground would read as a smudge.
  static const inkwell = Color(0xFF030612);
  static const wellFill = Color(0xFF0B1020);

  // ── Text ────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFFFFFF);
  static const textBody = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF94A3B8);
  static const textDim = Color(0xFF64748B);

  // ── Accents ─────────────────────────────────────────────────────────────
  static const emerald = Color(0xFF10B981);
  static const cyan = Color(0xFF06B6D4);
  static const violet = Color(0xFF8B5CF6);
  static const ice = Color(0xFFA5F3FC);
  static const lilac = Color(0xFFC4B5FD);
  static const mint = Color(0xFF6EE7B7);
  static const danger = Color(0xFFFCA5A5);

  // ── Hairlines ───────────────────────────────────────────────────────────
  static const hairline = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const hairlineStrong = Color(0x24FFFFFF); // 0.14
  static final borderAccent = ice.withValues(alpha: 0.40);

  // ── Gradients ───────────────────────────────────────────────────────────

  /// The brand ramp: emerald → cyan → violet at 135°.
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emerald, cyan, violet],
    stops: [0.0, 0.5, 1.0],
  );

  /// Used with a shader mask on emphasised italic text.
  static const textRamp = LinearGradient(
    begin: Alignment(-1, -0.2),
    end: Alignment(1, 0.2),
    colors: [ice, lilac],
  );

  /// The plate face — 158° in CSS, which is down-and-slightly-right here.
  static const plateFace = LinearGradient(
    begin: Alignment(-0.35, -1),
    end: Alignment(0.35, 1),
    colors: [Color(0xFF1A2237), Color(0xFF0D1322), Color(0xFF111A2B)],
    stops: [0.0, 0.46, 1.0],
  );

  /// A channel milled into the plate: prompt fields, progress tracks, segmented
  /// controls.
  static const sunkFace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF05080F), Color(0xFF0A1120)],
  );

  /// A raised key — secondary buttons, inactive chips, the result action bar.
  static const keycapFace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A3550), Color(0xFF161E33), Color(0xFF0F1626)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Anodised blue — the finish on whichever option is currently selected.
  static const anodizedFace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2C8F9E), Color(0xFF155C73), Color(0xFF0D3D55)],
    stops: [0.0, 0.5, 1.0],
  );

  /// Brand-coloured knob — primary CTAs and the FAB.
  static const knobFace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF34D399), Color(0xFF0EA5B7), Color(0xFF7C4DDB)],
    stops: [0.0, 0.42, 1.0],
  );

  /// Ring of light around framed art and icon tiles.
  static const bevelRing = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [Color(0x57FFFFFF), Color(0x1A788CAF), Color(0xD9000000)],
    stops: [0.0, 0.45, 1.0],
  );
}
