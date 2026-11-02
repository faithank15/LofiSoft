import 'package:get/get.dart';

import '../api_client.dart';

/// Appels HTTP bruts pour la gestion des logements par le propriétaire.
class PropertyService extends GetxService {
  PropertyService(this._api);

  final ApiClient _api;

  /// Liste tous les logements appartenant au bailleur connecté.
  Future<Map<String, dynamic>> list() => _api.get('/housings');

  /// Détails complets d'un logement, incluant la location active et le locataire.
  Future<Map<String, dynamic>> detail(String id) => _api.get('/housings/$id');

  /// Enregistre un nouveau logement et génère automatiquement son code unique.
  Future<Map<String, dynamic>> create({
    required String title,
    required String type,
    required int rent,
    required int dueDay,
    required String city,
    required String district,
    List<String>? photos,
  }) {
    return _api.post(
      '/housings',
      body: {
        'title': title,
        'type': type,
        'rent': rent,
        'due_day': dueDay,
        'city': city,
        'district': district,
        if (photos != null && photos.isNotEmpty) 'photos': photos,
      },
    );
  }

  /// Met à jour les informations d'un logement existant.
  Future<Map<String, dynamic>> update(
    String id, {
    String? title,
    int? rent,
    int? dueDay,
    String? city,
    String? district,
  }) {
    return _api.put(
      '/housings/$id',
      body: {
        'title': ?title,
        'rent': ?rent,
        'due_day': ?dueDay,
        'city': ?city,
        'district': ?district,
      },
    );
  }

  /// Clôture le bail actif d'un logement.
  Future<Map<String, dynamic>> endRental(String rentalId) =>
      _api.post('/rentals/$rentalId/end');
}
