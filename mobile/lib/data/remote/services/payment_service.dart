import 'package:get/get.dart';
import '../api_client.dart';

class PaymentService extends GetxService {
  PaymentService(this._api);
  final ApiClient _api;
  Future<Map<String, dynamic>> initiate({
    required String rentalId,
    required String period,
    required int amount,
    required String operator,
    required String phone,
  }) {
    return _api.post(
      '/payments',
      body: {
        'rental_id': rentalId,
        'period': period,
        'amount': amount,
        'operator': operator,
        'phone': phone,
      },
    );
  }

  Future<Map<String, dynamic>> checkStatus(String paymentId) {
    return _api.get('/payments/$paymentId');
  }

  Future<Map<String, dynamic>> receipt(String paymentId) {
    return _api.get('/payments/$paymentId/receipt');
  }
}

class FakePaymentService extends PaymentService {
  FakePaymentService(super.api);
  final Map<String, Map<String, dynamic>> _storage = {};
  final Map<String, int> _pollCount = {};
  @override
  Future<Map<String, dynamic>> initiate({
    required String rentalId,
    required String period,
    required int amount,
    required String operator,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final id = 'sim-pay-${DateTime.now().millisecondsSinceEpoch}';
    _storage[id] = {
      'id': id,
      'status': 'PENDING',
      'amount': amount,
      'operator': operator,
      'phone': phone,
      'rental_id': rentalId,
      'period': period,
      'reference': 'RC-SIM-${DateTime.now().millisecondsSinceEpoch}',
      'paid_at': DateTime.now().toIso8601String(),
    };
    _pollCount[id] = 0;
    return {
      'payment': {
        'id': id,
        'status': 'PENDING',
        'amount': amount,
        'operator': operator,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> checkStatus(String paymentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final item = _storage[paymentId];
    if (item == null) {
      return {
        'id': paymentId,
        'status': 'FAILED',
        'amount': 0,
        'operator': 'MTN',
      };
    }
    final count = (_pollCount[paymentId] ?? 0) + 1;
    _pollCount[paymentId] = count;
    if (count >= 2) {
      final phone = '${item['phone'] ?? ''}';
      final ok = !phone.endsWith('00');
      item['status'] = ok ? 'SUCCESS' : 'FAILED';
    }
    return {
      'id': item['id'],
      'status': item['status'],
      'amount': item['amount'],
      'operator': item['operator'],
    };
  }

  @override
  Future<Map<String, dynamic>> receipt(String paymentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final item = _storage[paymentId] ?? {};
    return {
      'reference': item['reference'] ?? 'RC-SIM-001',
      'amount': item['amount'] ?? 0,
      'paid_at': item['paid_at'] ?? DateTime.now().toIso8601String(),
      'operator': item['operator'] == 'MOOV'
          ? 'Moov Money'
          : 'MTN Mobile Money',
      'housing': 'Logement principal',
      'period': item['period'] ?? '2026-11',
    };
  }
}
