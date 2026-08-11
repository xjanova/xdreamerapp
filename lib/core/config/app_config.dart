import 'package:flutter/foundation.dart';

/// Where this build points and what it is allowed to talk to.
///
/// Override for a local backend:
/// ```
/// flutter run --dart-define=XDR_API_BASE=http://10.0.2.2:3000
/// ```
/// (`10.0.2.2` is the host machine as seen from the Android emulator.)
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'XDR_API_BASE',
    defaultValue: 'https://ai.xman4289.com',
  );

  /// xmanstudio owns accounts and payments; this app links out to it for both.
  static const xmanBaseUrl = String.fromEnvironment(
    'XDR_XMAN_BASE',
    defaultValue: 'https://xman4289.com',
  );

  /// Registration lives in Laravel — `users` is xmanstudio's table and there is
  /// no signup endpoint on the AI side.
  static Uri get registerUrl => Uri.parse('$xmanBaseUrl/register');

  /// Credit purchases go through xmanstudio checkout, which calls back to
  /// `POST /api/webhooks/xman-credit` to top the balance up.
  static Uri checkoutUrl(String packageSlug) =>
      Uri.parse('$xmanBaseUrl/checkout/ai-credits/$packageSlug?ref=ai');

  /// A release build must never send a bearer token over cleartext. Debug
  /// builds may, so a `next dev` server on the LAN is reachable.
  static void assertTransportIsSafe() {
    if (kReleaseMode && !apiBaseUrl.startsWith('https://')) {
      throw StateError('XDR_API_BASE must be https:// in a release build (got: $apiBaseUrl)');
    }
  }
}
