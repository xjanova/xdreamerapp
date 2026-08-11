import 'package:dio/dio.dart';

import '../../core/net/api_client.dart';
import '../models/generation.dart';

/// Which slice of the customer's own work to show.
///
/// The API has no public/community feed — `/api/gallery` is always scoped to
/// the signed-in user. The Community tab therefore shows the same body of work
/// sorted by popularity rather than by date, which is the honest reading of
/// what the backend can currently supply.
enum GalleryFilter {
  all(labelTh: 'ทั้งหมด'),
  image(labelTh: 'ภาพ', type: 'image'),
  video(labelTh: 'วิดีโอ', type: 'video'),
  favourites(labelTh: 'ที่ชื่นชอบ', favouritesOnly: true),
  upscaled(labelTh: 'อัปสเกลแล้ว', type: 'edit');

  const GalleryFilter({required this.labelTh, this.type, this.favouritesOnly = false});

  final String labelTh;
  final String? type;
  final bool favouritesOnly;
}

enum GallerySort {
  newest('newest', 'ล่าสุด'),
  trending('trending', 'ยอดนิยม'),
  top('top', 'ติดตาม');

  const GallerySort(this.value, this.labelTh);

  final String value;
  final String labelTh;
}

class GalleryRepository {
  GalleryRepository(this._client);

  final ApiClient _client;

  Future<GalleryPage> page({
    int page = 1,
    int limit = 20,
    GalleryFilter filter = GalleryFilter.all,
    GallerySort sort = GallerySort.newest,
    String? search,
    CancelToken? cancelToken,
  }) async {
    final data = await _client.getJson(
      '/api/gallery',
      cancelToken: cancelToken,
      query: {
        'page': page,
        'limit': limit,
        'sort': sort.value,
        if (filter.type != null) 'type': filter.type,
        if (filter.favouritesOnly) 'favorites': 'true',
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    return GalleryPage.fromJson(data);
  }

  Future<void> favourite(int generationId) =>
      _client.postJson('/api/favorites', body: {'generationId': generationId});

  Future<void> unfavourite(int generationId) =>
      _client.deleteJson('/api/favorites', body: {'generationId': generationId});
}
