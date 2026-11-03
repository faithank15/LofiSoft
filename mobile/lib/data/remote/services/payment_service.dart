import 'package:get/get.dart';

import '../api_client.dart';

/// Appels HTTP bruts du paiement de loyer (lot 6 : B3 « Payer », B4 « Reçu »).
class PaymentService extends GetxService {
  PaymentService(this._api);

  final ApiClient _api;

  /// Crée un paiement en attente : `POST /payments` -> 201 `{payment: {...}}`.
  Future<Map<String, dynamic>> create({
    required String rentalId,
    required String period,
    required int amount,
    required String operator,
    required String phone,
  }) =>
      _api.post('/payments', body: {
        'rental_id': rentalId,
        'period': period,
        'amount': amount,
        'operator': operator,
        'phone': phone,
      });

  /// État courant du paiement, interrogé jusqu'à la conclusion.
  Future<Map<String, dynamic>> status(String id) => _api.get('/payments/$id');

  /// Reçu d'un paiement réussi (400 tant que le paiement n'est pas SUCCESS).
  Future<Map<String, dynamic>> receipt(String id) => _api.get('/payments/$id/receipt');
}
