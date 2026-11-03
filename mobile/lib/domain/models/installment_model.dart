import '../../core/utils/json_utils.dart';
import 'enums.dart';

int _int(Object? v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;

/// Un paiement (acompte) du loyer : créé par `POST /payments`, puis suivi
/// par `GET /payments/{id}` jusqu'à sa conclusion (SUCCESS ou FAILED).
class Installment {
  const Installment({
    required this.id,
    required this.status,
    required this.amount,
    required this.operator,
  });

  final String id;
  final PaymentStatus status;
  final int amount;

  /// `MTN` ou `MOOV` (tel qu'envoyé au serveur).
  final String operator;

  /// « MTN Mobile Money », « Moov Money »…
  String get operatorLabel => switch (operator.toUpperCase()) {
        'MTN' => 'MTN Mobile Money',
        'MOOV' => 'Moov Money',
        'CASH' => 'Espèces',
        final other => other,
      };

  factory Installment.fromJson(Map<String, dynamic> json) {
    // POST /payments enveloppe dans « payment », GET /payments/{id} est plat.
    final wrapped = asJsonMap(json['payment']);
    final src = wrapped.isEmpty ? json : wrapped;
    return Installment(
      id: '${src['id'] ?? ''}',
      status: _status(src['status']),
      amount: _int(src['amount']),
      operator: '${src['operator'] ?? ''}',
    );
  }

  static PaymentStatus _status(Object? raw) {
    final val = '${raw ?? ''}'.toUpperCase();
    for (final s in PaymentStatus.values) {
      if (s.name == val) return s;
    }
    return PaymentStatus.PENDING;
  }
}
