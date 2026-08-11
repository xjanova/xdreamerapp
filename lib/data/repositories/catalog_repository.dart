import '../../core/net/api_client.dart';
import '../models/catalog.dart';

/// Models, style presets and credit packages — the three lists the studio and
/// pricing screens are built from. All three are public endpoints.
class CatalogRepository {
  CatalogRepository(this._client);

  final ApiClient _client;

  Future<List<AiModelInfo>> models() async {
    final data = await _client.getJson('/api/models');
    final raw = data['models'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => AiModelInfo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<StylePreset>> styles() async {
    final data = await _client.getJson('/api/styles');
    final raw = data['styles'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => StylePreset.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CreditPackage>> packages() async {
    final data = await _client.getJson('/api/packages');
    final raw = data['packages'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CreditPackage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
