import 'json_ext.dart';

/// One friend who joined on this account's code.
class ReferredFriend {
  const ReferredFriend({
    required this.id,
    required this.name,
    required this.totalCommission,
    required this.bonusCredits,
    this.joinedAt,
  });

  final int id;
  final String name;
  final int totalCommission;
  final int bonusCredits;
  final DateTime? joinedAt;

  factory ReferredFriend.fromJson(Map<String, dynamic> json) => ReferredFriend(
        id: json.intVal('id'),
        name: json.str('referredName', 'ผู้ใช้'),
        totalCommission: json.intVal('totalCommission'),
        bonusCredits: json.intVal('bonusCredits'),
        joinedAt: json.date('joinedAt'),
      );
}

/// `GET /api/referral`.
class ReferralStats {
  const ReferralStats({
    required this.code,
    required this.totalReferred,
    required this.totalCommission,
    required this.pendingCommission,
    required this.commissionRate,
    this.friends = const [],
  });

  const ReferralStats.empty()
      : code = '',
        totalReferred = 0,
        totalCommission = 0,
        pendingCommission = 0,
        commissionRate = 10,
        friends = const [];

  final String code;
  final int totalReferred;

  /// Credits already paid out from friends' purchases.
  final int totalCommission;
  final int pendingCommission;

  /// Percent of a referred friend's purchase paid back as credits.
  final int commissionRate;
  final List<ReferredFriend> friends;

  /// How many of the invited friends have actually generated something. The API
  /// does not report this directly; a friend who earned commission has spent,
  /// which is the closest honest proxy.
  int get activeFriends => friends.where((f) => f.totalCommission > 0).length;

  factory ReferralStats.fromJson(Map<String, dynamic> json) => ReferralStats(
        code: json.str('referralCode'),
        totalReferred: json.intVal('totalReferred'),
        totalCommission: json.intVal('totalCommission'),
        pendingCommission: json.intVal('pendingCommission'),
        commissionRate: json.intVal('commissionRate', 10),
        friends: json.objList('referrals').map(ReferredFriend.fromJson).toList(),
      );
}
