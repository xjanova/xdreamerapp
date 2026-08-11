import 'package:flutter/material.dart';

/// The keyframes from the handoff, named so screens read like the spec.
abstract final class XdrMotion {
  /// `cubic-bezier(.16, 1, .3, 1)` — the overshoot-free ease everything
  /// entering the screen uses.
  static const ease = Cubic(0.16, 1, 0.3, 1);

  /// `xdrUp` — fade in and rise 14px. Every screen entrance.
  static const enter = Duration(milliseconds: 420);
  static const enterRise = 14.0;

  /// `xdrSheet` — the create-mode sheet coming up from the bottom.
  static const sheet = Duration(milliseconds: 320);

  /// `xdrSpin` — the conic ring while a job is running.
  static const spin = Duration(milliseconds: 1500);

  /// `xdrShim` — skeleton sweep, staggered 0 / .2 / .4 / .6s across four tiles.
  static const shimmer = Duration(milliseconds: 1500);
  static const shimmerStagger = Duration(milliseconds: 200);

  /// `xdrSheen` — the light bar travelling across a primary button.
  static const sheen = Duration(milliseconds: 3000);

  /// `xdrPulse` — halo behind the FAB.
  static const pulse = Duration(milliseconds: 2400);

  /// `xdrFloat` — the onboarding logo drifting.
  static const float = Duration(milliseconds: 6000);

  /// `xdrBlink` — caret at the end of the prompt.
  static const blink = Duration(milliseconds: 1100);

  /// Press feedback. Short enough that the sink feels like contact, not travel.
  static const press = Duration(milliseconds: 120);

  /// How far a pressed control sinks into the panel.
  static const pressDepth = 2.5;
}
