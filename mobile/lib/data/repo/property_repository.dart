import '../../core/errors/app_exception.dart';
import '../../core/utils/json_utils.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/property_model.dart';
import '../cache/app_storage.dart';
import '../remote/services/property_service.dart';

/// Dépôt unique pour la gestion des logements du bailleur avec persistance hors-ligne.
class PropertyRepository {
  PropertyRepository(this._service, this._appStorage);

  final PropertyService _service;
  final AppStorage _appStorage;

  static const _cacheKey = 'owner_housings';

  /// Récupère la liste des logements distants avec repli sur le cache local en mode hors-ligne.
  Future<List<HousingModel>> list() async {
    try {
      final json = await _service.list();
      final items = asJsonList(
        json['data'],
      ).map((e) => HousingModel.fromJson(asJsonMap(e))).toList();

      await _appStorage.saveJson(_cacheKey, json['data']);
      return items;
    } on NetworkException {
      final cached = _appStorage.readJson<List<dynamic>>(_cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached.map((e) => HousingModel.fromJson(asJsonMap(e))).toList();
      }
      rethrow;
    }
  }

  /// Récupère le détail complet d'un logement par son identifiant.
  Future<HousingModel> detail(String id) async {
    final json = await _service.detail(id);
    return HousingModel.fromJson(asJsonMap(json['data']));
  }

  /// Crée un nouveau logement et retourne l'entité enregistrée avec son code logement.
  Future<HousingModel> create({
    required String title,
    required AccommodationType type,
    required int rent,
    required int dueDay,
    required String city,
    required String district,
    List<String>? photos,
  }) async {
    final json = await _service.create(
      title: title,
      type: type.name,
      rent: rent,
      dueDay: dueDay,
      city: city,
      district: district,
      photos: photos,
    );
    return HousingModel.fromJson(asJsonMap(json['data']));
  }

  /// Met à jour les informations d'un logement.
  Future<HousingModel> update(
    String id, {
    String? title,
    int? rent,
    int? dueDay,
    String? city,
    String? district,
  }) async {
    final json = await _service.update(
      id,
      title: title,
      rent: rent,
      dueDay: dueDay,
      city: city,
      district: district,
    );
    return HousingModel.fromJson(asJsonMap(json['data']));
  }

  /// Met fin à la location active en cours pour ce logement.
  Future<void> endRental(String rentalId) async {
    await _service.endRental(rentalId);
  }
}
