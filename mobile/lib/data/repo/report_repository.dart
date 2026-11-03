import '../remote/services/report_service.dart';

class ReportRepository {
  ReportRepository(this._service);
  final ReportService _service;
  Future<String> submitReport({
    required String announcementId,
    required String reason,
    String? details,
  }) async {
    final response = await _service.submitReport(
      announcementId: announcementId,
      reason: reason,
      details: details,
    );
    return '${response['message'] ?? 'Signalement envoyé avec succès.'}';
  }
}
