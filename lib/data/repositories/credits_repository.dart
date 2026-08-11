import '../../core/net/api_client.dart';
import '../models/generation.dart';
import '../models/session.dart';

class CreditsRepository {
  CreditsRepository(this._client);

  final ApiClient _client;

  Future<CreditBalance> balance() async {
    final data = await _client.getJson('/api/credits');
    return CreditBalance.fromJson(data);
  }

  Future<List<CreditTransaction>> history({int page = 1, int limit = 30}) async {
    final data = await _client.getJson(
      '/api/credits/history',
      query: {'page': page, 'limit': limit},
    );
    final raw = data['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CreditTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
