import '../../core/errors/app_exception.dart';
import '../../core/utils/json_utils.dart';
import '../../domain/models/receipt_model.dart';
import '../remote/services/payment_service.dart';

class PaymentInitiationResult {
  const PaymentInitiationResult({
    required this.id,
    required this.status,
    required this.amount,
    required this.operator,
  });
  final String id;
  final String status;
  final int amount;
  final String operator;
  factory PaymentInitiationResult.fromJson(Map<String, dynamic> json) {
    final root = asJsonMap(json['payment'] ?? json['data'] ?? json);
    return PaymentInitiationResult(
      id: '${root['id'] ?? ''}',
      status: '${root['status'] ?? 'PENDING'}',
      amount: root['amount'] is num
          ? (root['amount'] as num).round()
          : int.tryParse('${root['amount'] ?? ''}') ?? 0,
      operator: '${root['operator'] ?? ''}',
    );
  }
}

class PaymentRepository {
  PaymentRepository(this._service);
  final PaymentService _service;
  Future<PaymentInitiationResult> initiatePayment({
    required String rentalId,
    required String period,
    required int amount,
    required String operator,
    required String phone,
  }) async {
    final response = await _service.initiate(
      rentalId: rentalId,
      period: period,
      amount: amount,
      operator: operator,
      phone: phone,
    );
    return PaymentInitiationResult.fromJson(response);
  }

  Future<String> pollStatus(
    String paymentId, {
    int maxAttempts = 12,
    Duration interval = const Duration(seconds: 2),
  }) async {
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(interval);
      final response = await _service.checkStatus(paymentId);
      final status = '${response['status'] ?? 'PENDING'}'.toUpperCase();
      if (status != 'PENDING') {
        return status;
      }
    }
    return 'PENDING';
  }

  Future<ReceiptModel> fetchReceipt(String paymentId) async {
    final response = await _service.receipt(paymentId);
    return ReceiptModel.fromJson(asJsonMap(response));
  }
}
