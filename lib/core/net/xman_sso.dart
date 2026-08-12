import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// The browser half of "Sign in with XMAN ID".
///
/// Opens xmanstudio's authorize page and waits for it to hand an authorization
/// code back over the `xdreamer://` scheme. Everything the customer sees —
/// already-signed-in, the login form, the register link — is Laravel's own,
/// which is the point: there is no second place to keep a password.
///
/// PKCE, because the return leg is a custom URL scheme and any installed app
/// can claim one. The verifier is generated here, never sent to the browser,
/// and only revealed when redeeming. A stolen code on its own is worthless.
class XmanSso {
  XmanSso({AppLinks? links}) : _links = links ?? AppLinks();

  final AppLinks _links;

  StreamSubscription<Uri>? _subscription;
  Completer<_SsoCallback>? _pending;
  String? _expectedState;

  /// Must be running before [signIn] is called, so a callback that arrives
  /// while the app was backgrounded is not missed.
  void start() {
    _subscription ??= _links.uriLinkStream.listen(_onLink, onError: (_) {});
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _failPending(ApiException('การเข้าสู่ระบบถูกยกเลิก'));
  }

  void _onLink(Uri uri) {
    if (uri.scheme != AppConfig.callbackScheme || uri.host != AppConfig.callbackHost) return;

    final pending = _pending;
    if (pending == null || pending.isCompleted) return;

    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      _failPending(ApiException('เข้าสู่ระบบด้วย XMAN ID ไม่สำเร็จ'));
      return;
    }

    // A callback carrying somebody else's state is not ours — most likely
    // another app firing the same scheme at us.
    if (uri.queryParameters['state'] != _expectedState) return;

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      _failPending(ApiException('ไม่ได้รับรหัสยืนยันจาก XMAN ID'));
      return;
    }

    pending.complete(_SsoCallback(code));
  }

  void _failPending(ApiException error) {
    final pending = _pending;
    _pending = null;
    _expectedState = null;
    if (pending != null && !pending.isCompleted) pending.completeError(error);
  }

  /// Run the browser leg and return the code plus the verifier that unlocks it.
  ///
  /// Throws [ApiException] if the browser cannot be opened, the customer backs
  /// out, or nothing comes back in time.
  Future<XmanAuthCode> signIn() async {
    start();

    // Abandon whatever was in flight — a second tap means the first attempt is
    // no longer the one the customer is waiting on.
    _failPending(ApiException('เริ่มการเข้าสู่ระบบใหม่'));

    final verifier = _randomUrlSafe(32);
    final state = _randomUrlSafe(16);
    final challenge = challengeFor(verifier);

    _expectedState = state;
    final pending = Completer<_SsoCallback>();
    _pending = pending;

    final authorizeUrl = AppConfig.xmanAuthorizeUrl(state: state, codeChallenge: challenge);

    final launched = await launchUrl(authorizeUrl, mode: LaunchMode.externalApplication);
    if (!launched) {
      _failPending(ApiException('เปิดหน้าเข้าสู่ระบบไม่สำเร็จ'));
      throw ApiException('เปิดหน้าเข้าสู่ระบบไม่สำเร็จ');
    }

    try {
      // Long, because the customer may have to sign in or even register at
      // xman4289.com before coming back.
      final callback = await pending.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () => throw ApiException('หมดเวลารอการเข้าสู่ระบบ กรุณาลองใหม่'),
      );
      return XmanAuthCode(code: callback.code, codeVerifier: verifier);
    } finally {
      // Only clear what this call owns. A second tap starts a new flow and
      // fails this one; without the identity check, this cleanup would run
      // afterwards and wipe the *new* flow's state, leaving its callback with
      // nobody listening and the customer staring at a spinner until timeout.
      if (identical(_pending, pending)) {
        _pending = null;
        _expectedState = null;
      }
    }
  }

  static final _random = Random.secure();

  /// base64url without padding — the alphabet PKCE requires.
  static String _randomUrlSafe(int bytes) {
    final buffer = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64UrlEncode(buffer).replaceAll('=', '');
  }

  /// PKCE S256: `base64url(sha256(verifier))`, unpadded.
  ///
  /// Has to agree byte for byte with what xmanstudio recomputes, or every
  /// sign-in fails at the exchange. Pulled out so a test can hold both sides to
  /// the same well-known vector.
  static String challengeFor(String verifier) =>
      base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes).replaceAll('=', '');
}

class _SsoCallback {
  const _SsoCallback(this.code);

  final String code;
}

/// What comes out of the browser leg, ready to redeem.
class XmanAuthCode {
  const XmanAuthCode({required this.code, required this.codeVerifier});

  final String code;
  final String codeVerifier;
}
