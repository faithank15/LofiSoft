import '../../core/utils/json_utils.dart';

int _int(Object? v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;

DateTime? _date(Object? raw) => DateTime.tryParse('${raw ?? ''}')?.toLocal();

/// Reçu d'un paiement réussi (réponse de `GET /payments/{id}/receipt`).
class Receipt {
  const Receipt({
    required this.reference,
    required this.amount,
    this.paidAt,
    this.operator = '',
    this.housing = '',
    this.period = '',
  });

  /// Ex. « RC-20261102-A1B2 ».
  final String reference;
  final int amount;
  final DateTime? paidAt;

  /// Libellé complet : « MTN Mobile Money ».
  final String operator;

  /// Titre du logement concerné.
  final String housing;

  /// Mois de loyer payé : « 2026-11 ».
  final String period;

  DateTime get periodDate {
    final parts = period.split('-');
    final fallback = paidAt ?? DateTime.now();
    return DateTime(
      int.tryParse(parts.first) ?? fallback.year,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? fallback.month) : fallback.month,
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> json) => Receipt(
        reference: '${json['reference'] ?? ''}',
        amount: _int(json['amount']),
        paidAt: _date(json['paid_at']),
        operator: '${json['operator'] ?? ''}',
        housing: '${json['housing'] ?? ''}',
        period: '${json['period'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'amount': amount,
        'paid_at': paidAt?.toIso8601String(),
        'operator': operator,
        'housing': housing,
        'period': period,
      };
}
