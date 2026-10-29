import 'package:get/get.dart';

import '../../../core/network/api_client.dart';

/// Appels HTTP bruts des annonces et des favoris. Renvoie le JSON du serveur.
class AnnouncementService extends GetxService {
  AnnouncementService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> list({
    String? city,
    String? type,
    int? minPrice,
    int? maxPrice,
    String? q,
    int page = 1,
    int perPage = 20,
  }) =>
      _api.get('/announcements', query: {
        if (city != null && city.isNotEmpty) 'city': city,
        if (type != null && type.isNotEmpty) 'type': type,
        if (minPrice != null) 'min_price': '$minPrice',
        if (maxPrice != null) 'max_price': '$maxPrice',
        if (q != null && q.isNotEmpty) 'q': q,
        'page': '$page',
        'per_page': '$perPage',
      });

  Future<Map<String, dynamic>> detail(String id) => _api.get('/announcements/$id');

  Future<Map<String, dynamic>> favorites() => _api.get('/me/favorites');

  Future<void> addFavorite(String id) => _api.put('/announcements/$id/favorite');

  Future<void> removeFavorite(String id) => _api.delete('/announcements/$id/favorite');
}
