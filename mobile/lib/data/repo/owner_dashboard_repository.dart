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
}