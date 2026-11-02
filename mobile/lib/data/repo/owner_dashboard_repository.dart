import '../../core/utils/json_utils.dart';
import '../../domain/models/owner_dashboard_model.dart';
import '../remote/services/owner_dashboard_service.dart';

/// Source de vérité du tableau de bord propriétaire.
class OwnerDashboardRepository {
  OwnerDashboardRepository(this._service);

  final OwnerDashboardService _service;

  Future<OwnerDashboard> dashboard() async =>
      OwnerDashboard.fromJson(await _service.dashboard());

  Future<List<TenantRent>> tenants() async {
    final json = await _service.tenants();
    return asJsonList(json['data'])
        .map((e) => TenantRent.fromJson(asJsonMap(e)))
        .toList();
  }

  /// Retourne le message du serveur (« Rappel envoyé au locataire. »).
  Future<String> remind(String rentalId) async {
    final json = await _service.remind(rentalId);
    return '${json['message'] ?? 'Rappel envoyé.'}';
  }

  Future<List<RentalRequest>> requests() async {
    final json = await _service.requests();
    return asJsonList(json['data']).map((e) => RentalRequest.fromJson(asJsonMap(e))).toList();
  }

  Future<String> accept(String rentalId) async =>
      '${(await _service.accept(rentalId))['message'] ?? 'Locataire confirmé.'}';

  Future<String> reject(String rentalId) async =>
      '${(await _service.reject(rentalId))['message'] ?? 'Demande refusée.'}';
}
