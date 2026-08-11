import 'json_ext.dart';

/// The signed-in account. Mirrors `MobileSession.user` on the server — no
/// password hash, no Stripe id, nothing the app has no business holding.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.role = 'user',
  });

  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String role;

  /// The letter in the avatar ring when there is no picture. Runes rather than
  /// `[0]` so a Thai or emoji first character is not sliced in half.
  String get initial {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    return String.fromCharCode(source.runes.first).toUpperCase();
  }

  /// `@handle` shown under the name on the profile screen. Derived from the
  /// email local part because the platform has no separate handle field.
  String get handle {
    final local = email.split('@').first;
    return local.isEmpty ? 'creator' : local;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json.intVal('id'),
        name: json.str('name', 'ผู้ใช้'),
        email: json.str('email'),
        avatar: json.strOrNull('avatar'),
        role: json.str('role', 'user'),
      );
}

/// `ai_user_credits` for this account.
class CreditBalance {
  const CreditBalance({
    required this.balance,
    required this.totalBought,
    required this.totalUsed,
    required this.totalBonus,
  });

  const CreditBalance.empty()
      : balance = 0,
        totalBought = 0,
        totalUsed = 0,
        totalBonus = 0;

  final int balance;
  final int totalBought;
  final int totalUsed;
  final int totalBonus;

  factory CreditBalance.fromJson(Map<String, dynamic> json) => CreditBalance(
        balance: json.intVal('balance'),
        totalBought: json.intVal('totalBought'),
        totalUsed: json.intVal('totalUsed'),
        totalBonus: json.intVal('totalBonus'),
      );
}

/// What `/api/mobile/login`, `/refresh` and `/me` all return.
class MobileSession {
  const MobileSession({required this.user, required this.credits});

  final UserProfile user;
  final CreditBalance credits;

  factory MobileSession.fromJson(Map<String, dynamic> json) => MobileSession(
        user: UserProfile.fromJson(json.obj('user') ?? const {}),
        credits: CreditBalance.fromJson(json.obj('credits') ?? const {}),
      );
}

/// Login and refresh hand back the pair plus the session in one response.
class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.session,
  });

  final String accessToken;
  final String refreshToken;
  final MobileSession session;

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json.str('accessToken'),
        refreshToken: json.str('refreshToken'),
        session: MobileSession.fromJson(json),
      );

  bool get isUsable => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}
