import 'package:get/get.dart';

import '../api_client.dart';

/// Appels HTTP bruts du code logement et de la location du locataire.
class RentalService extends GetxService {
  RentalService(this._api);

  final ApiClient _api;

  /// Montre le logement correspondant au code, avant confirmation.
  Future<Map<String, dynamic>> lookup(String code) =>
      _api.get('/housings/lookup', query: {'code': code});

  /// Rejoint le logement : crée une location en attente de confirmation.
  Future<Map<String, dynamic>> join(String code) => _api.post('/rentals/join', body: {'code': code});
}
