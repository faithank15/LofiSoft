import 'package:get/get.dart';

import '../api_client.dart';

/// Appels HTTP bruts de l'espace propriétaire (tableau de bord et loyers).
class OwnerDashboardService extends GetxService {
  OwnerDashboardService(this._api);

  final ApiClient _api;

  /// Chiffres du mois : loyers attendus, reçus, retards.
  Future<Map<String, dynamic>> dashboard() => _api.get('/owner/dashboard');

  /// Un locataire par ligne, avec son statut pour le mois.
  Future<Map<String, dynamic>> tenants() => _api.get('/owner/tenants');

  /// Envoie un rappel de paiement au locataire d'une location.
  Future<Map<String, dynamic>> remind(String rentalId) =>
      _api.post('/owner/rentals/$rentalId/remind');

  /// Demandes de location en attente de réponse.
  Future<Map<String, dynamic>> requests() => _api.get('/owner/requests');

  /// Accepte la demande : le locataire devient actif sur le logement.
  Future<Map<String, dynamic>> accept(String rentalId) => _api.post('/owner/rentals/$rentalId/accept');

  /// Refuse la demande : le locataire pourra en faire une autre.
  Future<Map<String, dynamic>> reject(String rentalId) => _api.post('/owner/rentals/$rentalId/reject');
}
