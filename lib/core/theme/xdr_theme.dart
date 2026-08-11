import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'xdr_colors.dart';
import 'xdr_type.dart';

/// Material only supplies the plumbing here — ripples, text selection, the
/// keyboard's own scrim. Every visible surface is a [MetalSurface], so this
/// theme mostly exists to stop Material's defaults leaking through.
abstract final class XdrTheme {
  static ThemeData build() {
    const scheme = ColorScheme.dark(
      primary: XdrColors.ice,
      onPrimary: XdrColors.inkwell,
      secondary: XdrColors.violet,
      onSecondary: Colors.white,
      surface: XdrColors.base,
      onSurface: XdrColors.textBody,
      error: XdrColors.danger,
      onError: XdrColors.inkwell,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: XdrColors.base,
      canvasColor: XdrColors.base,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      // Metal has its own press language (PressSink); Material's ink spreading
      // across a machined plate looks like a spill.
      splashColor: Colors.transparent,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: XdrColors.ice,
        selectionColor: Color(0x4006B6D4),
        selectionHandleColor: XdrColors.ice,
      ),
      textTheme: TextTheme(
        bodyMedium: XdrType.body(),
        bodySmall: XdrType.body(size: 12),
        titleMedium: XdrType.cardTitle(size: 16),
        labelSmall: XdrType.label(),
      ),
      dividerTheme: const DividerThemeData(color: XdrColors.hairline, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: XdrColors.ice,
        linearTrackColor: Color(0x0FFFFFFF),
      ),
    );
  }

  /// Transparent bars with light icons — the backdrop already supplies the
  /// darkness, and the app draws under both bars.
  static const systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );
}
