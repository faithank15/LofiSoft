import '../../core/errors/app_exception.dart';
import '../../core/utils/json_utils.dart';
import '../../domain/models/tenant_rent_model.dart';
import '../cache/app_storage.dart';
import '../remote/services/rental_service.dart';

/// Données de l'écran « Mon loyer », avec repli sur la dernière réponse reçue hors connexion.
class TenantRentRepository {
  TenantRentRepository(this._service, this._storage);

  final RentalService _service;
  final AppStorage _storage;

  static const _cacheKey = 'tenant_rent';

  Future<TenantRentSnapshot> load() async {
    try {
      final situationJson = await _service.situation();
      final situation = TenantSituation.fromJson(situationJson);

      Map<String, dynamic>? summaryJson;
      List<dynamic> paymentsJson = const [];
      if (situation.phase == RentalPhase.active) {
        summaryJson = await _service.currentRent();
        paymentsJson = asJsonList((await _service.payments())['data']);
      }

      await _storage.saveJson(_cacheKey, {
        'situation': situationJson,
        'summary': summaryJson,
        'payments': paymentsJson,
        'saved_at': DateTime.now().toIso8601String(),
      });
      return _snapshot(situationJson, summaryJson, paymentsJson, fromCache: false, savedAt: DateTime.now());
    } on NetworkException {
      final cached = _storage.readJson<Map<dynamic, dynamic>>(_cacheKey);
      if (cached == null) rethrow;
      final map = asJsonMap(cached);
      return _snapshot(
        asJsonMap(map['situation']),
        map['summary'] == null ? null : asJsonMap(map['summary']),
        asJsonList(map['payments']),
        fromCache: true,
        savedAt: DateTime.tryParse('${map['saved_at'] ?? ''}'),
      );
    }
  }

  TenantRentSnapshot _snapshot(
    Map<String, dynamic> situation,
    Map<String, dynamic>? summary,
    List<dynamic> payments, {
    required bool fromCache,
    DateTime? savedAt,
  }) {
    return TenantRentSnapshot(
      situation: TenantSituation.fromJson(situation),
      summary: summary == null ? null : RentSummary.fromJson(summary),
      payments: payments.map((e) => PaymentRecord.fromJson(asJsonMap(e))).where((p) => p.success).toList(),
      fromCache: fromCache,
      savedAt: savedAt,
    );
  }
}
