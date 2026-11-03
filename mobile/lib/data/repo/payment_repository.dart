import '../../domain/models/installment_model.dart';
import '../../domain/models/receipt_model.dart';
import '../remote/services/payment_service.dart';

/// Source de vérité des paiements du locataire (lot 6).
class PaymentRepository {
  PaymentRepository(this._service);

  final PaymentService _service;

  /// Crée un paiement en attente.
  Future<Installment> create({
    required String rentalId,
    required String period,
    required int amount,
    required String operator,
    required String phone,
  }) async =>
      Installment.fromJson(await _service.create(
        rentalId: rentalId,
        period: period,
        amount: amount,
        operator: operator,
        phone: phone,
      ));

  /// État courant du paiement.
  Future<Installment> status(String id) async =>
      Installment.fromJson(await _service.status(id));

  /// Reçu d'un paiement réussi.
  Future<Receipt> receipt(String id) async => Receipt.fromJson(await _service.receipt(id));
}
