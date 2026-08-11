import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'xdr_colors.dart';

/// Typography for X-DREAMER.
///
/// Two families, and which one leads matters. Thai copy is set in Noto Sans
/// Thai with Inter behind it; Latin-only runs — the wordmark, uppercase labels,
/// prices, stat numbers — are set in Inter, because Noto Sans Thai's Latin
/// glyphs are noticeably wider and break the tracked-out look the design leans
/// on.
///
/// Sizes are the literal values from the handoff, in logical pixels at the
/// 412×812 dp reference viewport.
abstract final class XdrType {
  /// Thai-leading. Use for anything a customer reads as a sentence.
  static TextStyle thai({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = XdrColors.textBody,
    double? height,
    double? letterSpacing,
    FontStyle? style,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.notoSansThai(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: style,
      shadows: shadows,
    ).copyWith(fontFamilyFallback: [_interFamily]);
  }

  /// Inter-leading. Use for wordmarks, uppercase labels, numbers and prices.
  static TextStyle latin({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = XdrColors.textBody,
    double? height,
    double? letterSpacing,
    FontStyle? style,
    List<Shadow>? shadows,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: style,
      shadows: shadows,
    ).copyWith(fontFamilyFallback: [_notoThaiFamily]);
  }

  static final String _interFamily = GoogleFonts.inter().fontFamily!;
  static final String _notoThaiFamily = GoogleFonts.notoSansThai().fontFamily!;

  // ── Named roles ─────────────────────────────────────────────────────────

  /// Onboarding headline. 33/300 with tight tracking.
  static TextStyle get hero => thai(
        size: 33,
        weight: FontWeight.w300,
        color: XdrColors.textPrimary,
        height: 1.28,
        letterSpacing: -0.33,
      );

  /// The emphasised second line of the hero — lighter, italic, gradient-masked.
  static TextStyle get heroAccent => hero.copyWith(
        fontWeight: FontWeight.w200,
        fontStyle: FontStyle.italic,
      );

  static TextStyle pageTitle({double size = 21}) =>
      thai(size: size, weight: FontWeight.w300, color: XdrColors.textPrimary);

  static TextStyle cardTitle({double size = 14, Color? color}) => thai(
        size: size,
        weight: FontWeight.w600,
        color: color ?? XdrColors.textPrimary,
      );

  static TextStyle body({double size = 13.5, Color? color, double height = 1.6}) =>
      thai(size: size, color: color ?? XdrColors.textBody, height: height);

  /// Tracked-out uppercase label — `PROMPT`, `STYLE PRESET`, `YOUR CODE`.
  static TextStyle label({double size = 10.5, Color? color, FontWeight weight = FontWeight.w400}) =>
      latin(
        size: size,
        weight: weight,
        color: color ?? XdrColors.textMuted,
        letterSpacing: size * 0.14,
      );

  /// `X-DREAMER`, always uppercase and heavily tracked.
  static TextStyle wordmark({double size = 11, Color? color}) => latin(
        size: size,
        weight: FontWeight.w900,
        color: color ?? XdrColors.textPrimary,
        letterSpacing: size * 0.20,
      );

  static TextStyle tabLabel({Color? color}) =>
      thai(size: 9.5, color: color ?? XdrColors.textDim);

  /// Big numbers on the profile stat cards; caller adds the coloured glow.
  static TextStyle statValue({double size = 24, required Color color}) => latin(
        size: size,
        weight: FontWeight.w700,
        color: color,
        shadows: [Shadow(color: color.withValues(alpha: 0.33), blurRadius: 22)],
      );

  static TextStyle price({double size = 21}) =>
      latin(size: size, weight: FontWeight.w700, color: XdrColors.textPrimary);
}

/// Text cut into the metal rather than printed on it: a hard black shadow
/// below, a whisper of light above.
const engraved = <Shadow>[
  Shadow(offset: Offset(0, 1), color: Color(0xE6000000)),
  Shadow(offset: Offset(0, -1), color: Color(0x0FFFFFFF)),
];
