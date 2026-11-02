import 'package:get/get.dart';

import '../api_client.dart';

/// Appels HTTP bruts de l'espace administrateur (signalements et vérifications d'identité).
class AdminService extends GetxService {
  AdminService(this._api);

  final ApiClient _api;

  /// Signalements à traiter (par défaut `PENDING`).
  Future<Map<String, dynamic>> reports({String status = 'PENDING'}) =>
      _api.get('/admin/reports', query: {'status': status});

  /// `action` : `REMOVE_ANNOUNCEMENT` (retire l'annonce) ou `WARN_OWNER`.
  Future<Map<String, dynamic>> resolveReport(String id, {required String action}) =>
      _api.post('/admin/reports/$id/resolve', body: {'action': action});

  Future<Map<String, dynamic>> dismissReport(String id) => _api.post('/admin/reports/$id/dismiss');

  /// Demandes de badge « Vérifié » (par défaut `PENDING`).
  Future<Map<String, dynamic>> identityRequests({String status = 'PENDING'}) =>
      _api.get('/admin/identity-requests', query: {'status': status});

  Future<Map<String, dynamic>> approveIdentity(String id) =>
      _api.post('/admin/identity-requests/$id/approve');

  Future<Map<String, dynamic>> rejectIdentity(String id, {required String reason}) =>
      _api.post('/admin/identity-requests/$id/reject', body: {'reason': reason});
}
