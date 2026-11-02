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

  /// Aucune location, demande en attente ou location active.
  Future<Map<String, dynamic>> situation() => _api.get('/me/situation');

  /// Loyer du mois en cours (location active).
  Future<Map<String, dynamic>> currentRent() => _api.get('/me/rent');

  /// Paiements du locataire, du plus récent au plus ancien.
  Future<Map<String, dynamic>> payments() => _api.get('/me/payments', query: {'per_page': '100'});
}
