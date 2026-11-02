import '../../core/utils/json_utils.dart';
import '../../domain/models/admin_model.dart';
import '../remote/services/admin_service.dart';

/// Source de vérité de l'espace administrateur.
class AdminRepository {
  AdminRepository(this._service);

  final AdminService _service;

  Future<List<ReportItem>> reports() async {
    final json = await _service.reports();
    return asJsonList(json['data']).map((e) => ReportItem.fromJson(asJsonMap(e))).toList();
  }

  /// Retire l'annonce signalée et clôt le signalement. Renvoie le message du serveur.
  Future<String> removeAnnouncement(String reportId) async =>
      _message(await _service.resolveReport(reportId, action: 'REMOVE_ANNOUNCEMENT'), 'Annonce supprimée.');

  Future<String> dismissReport(String reportId) async =>
      _message(await _service.dismissReport(reportId), 'Signalement ignoré.');

  Future<List<IdentityRequestItem>> identityRequests() async {
    final json = await _service.identityRequests();
    return asJsonList(json['data']).map((e) => IdentityRequestItem.fromJson(asJsonMap(e))).toList();
  }

  Future<String> approveIdentity(String id) async =>
      _message(await _service.approveIdentity(id), 'Propriétaire certifié.');

  Future<String> rejectIdentity(String id, {required String reason}) async =>
      _message(await _service.rejectIdentity(id, reason: reason.trim()), 'Demande refusée.');

  String _message(Map<String, dynamic> json, String fallback) => '${json['message'] ?? fallback}';
}
