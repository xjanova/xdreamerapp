import '../../core/net/api_client.dart';
import '../models/referral.dart';

class ReferralRepository {
  ReferralRepository(this._client);

  final ApiClient _client;

  Future<ReferralStats> stats() async {
    final data = await _client.getJson('/api/referral');
    return ReferralStats.fromJson(data);
  }

  /// Redeem somebody else's code. The server enforces the rules (new accounts
  /// only, no prior purchase, not your own code) and returns Thai copy when it
  /// refuses — surface that message rather than writing a second version of it
  /// here that can drift out of step.
  Future<void> applyCode(String code) =>
      _client.postJson('/api/referral', body: {'code': code.trim().toUpperCase()});
}
