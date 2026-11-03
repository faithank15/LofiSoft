import 'package:get/get.dart';
import '../api_client.dart';

class ReportService extends GetxService {
  ReportService(this._api);
  final ApiClient _api;
  Future<Map<String, dynamic>> submitReport({
    required String announcementId,
    required String reason,
    String? details,
  }) {
    return _api.post(
      '/announcements/$announcementId/reports',
      body: {
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }
}

class FakeReportService extends ReportService {
  FakeReportService(super.api);
  @override
  Future<Map<String, dynamic>> submitReport({
    required String announcementId,
    required String reason,
    String? details,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return {'message': 'Signalement envoyé.'};
  }
}
