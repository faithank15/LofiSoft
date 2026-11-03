import '../../../core/errors/app_exception.dart';
import '../services/payment_service.dart';

/// Faux service de paiement (`USE_FAKE_API=true`) : même simulation que le
/// back (driver « fake ») — après [delay], un numéro finissant par `00`
/// échoue, tout autre réussit. L'état est gardé en mémoire.
class FakePaymentService extends PaymentService {
  FakePaymentService(super.api);

  /// Délai avant la « réponse » de l'opérateur (réduit dans les tests).
  static Duration delay = const Duration(seconds: 4);

  static final Map<String, Map<String, dynamic>> _payments = {};
  static int _seq = 0;

  /// Paiement de démonstration pour ouvrir B4 depuis le menu de dev.
  static const demoId = 'demo';

  @override
  Future<Map<String, dynamic>> create({
    required String rentalId,
    required String period,
    required int amount,
    required String operator,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (rentalId.isEmpty) {
      throw const ServerException('Cette location ne vous appartient pas.');
    }
    final id = 'pay-${++_seq}';
    final now = DateTime.now();
    _payments[id] = {
      'id': id,
      'status': 'PENDING',
      'amount': amount,
      'operator': operator,
      'phone': phone,
      'period': period,
      'rental_id': rentalId,
      'created_at': now.toIso8601String(),
      'reference': 'RC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${id.substring(4).padLeft(4, '0')}',
    };
    return {
      'payment': {'id': id, 'status': 'PENDING', 'amount': amount, 'operator': operator},
    };
  }

  @override
  Future<Map<String, dynamic>> status(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final p = _payments[id] ?? (id == demoId ? _demo() : null);
    if (p == null) throw const ServerException('Paiement introuvable.');
    final created = DateTime.tryParse('${p['created_at']}') ?? DateTime.now();
    if (p['status'] == 'PENDING' && DateTime.now().difference(created) >= delay) {
      final ok = !'${p['phone']}'.endsWith('00');
      p['status'] = ok ? 'SUCCESS' : 'FAILED';
      if (ok) p['paid_at'] = DateTime.now().toUtc().toIso8601String();
    }
    return {'id': p['id'], 'status': p['status'], 'amount': p['amount'], 'operator': p['operator']};
  }

  @override
  Future<Map<String, dynamic>> receipt(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final p = _payments[id] ?? (id == demoId ? _demo() : null);
    if (p == null || p['status'] != 'SUCCESS') {
      throw const ValidationException('Aucun reçu disponible pour un paiement non abouti.');
    }
    return {
      'reference': p['reference'],
      'amount': p['amount'],
      'paid_at': p['paid_at'],
      'operator': p['operator'] == 'MOOV' ? 'Moov Money' : 'MTN Mobile Money',
      'housing': 'Appartement 1A',
      'period': p['period'],
    };
  }

  static Map<String, dynamic> _demo() => {
        'id': demoId,
        'status': 'SUCCESS',
        'amount': 30000,
        'operator': 'MTN',
        'phone': '0197123456',
        'period': '2026-11',
        'created_at': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String(),
        'paid_at': DateTime.now().subtract(const Duration(minutes: 3)).toUtc().toIso8601String(),
        'reference': 'RC-20261102-0001',
      };
}
