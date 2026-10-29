import '../../core/network/json_utils.dart';
import '../../domain/models/announcement_model.dart';
import '../remote/services/announcement_service.dart';

/// Source de vérité des annonces et des favoris pour les contrôleurs.
class AnnouncementRepository {
  AnnouncementRepository(this._service);

  final AnnouncementService _service;

  Future<AnnouncementPage> list({
    String? city,
    String? type,
    int? minPrice,
    int? maxPrice,
    String? q,
    int page = 1,
  }) async {
    final json = await _service.list(
      city: city,
      type: type,
      minPrice: minPrice,
      maxPrice: maxPrice,
      q: q,
      page: page,
    );
    final meta = asJsonMap(json['meta']);
    return AnnouncementPage(
      items: _parseList(json['data']),
      currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? page,
    );
  }

  Future<AnnouncementModel> detail(String id) async =>
      AnnouncementModel.fromJson(await _service.detail(id));

  Future<List<AnnouncementModel>> favorites() async =>
      _parseList((await _service.favorites())['data']);

  Future<void> setFavorite(String id, {required bool favorite}) =>
      favorite ? _service.addFavorite(id) : _service.removeFavorite(id);

  List<AnnouncementModel> _parseList(Object? data) => asJsonList(data)
      .map((e) => AnnouncementModel.fromJson(asJsonMap(e)))
      .toList();
}
