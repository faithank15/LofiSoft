import '../../core/utils/json_utils.dart';

class ReceiptModel {
  const ReceiptModel({
    required this.reference,
    required this.amount,
    required this.paidAt,
    required this.operator,
    required this.housing,
    required this.period,
  });
  final String reference;
  final int amount;
  final DateTime paidAt;
  final String operator;
  final String housing;
  final String period;
  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      reference: '${json['reference'] ?? ''}',
      amount: json['amount'] is num
          ? (json['amount'] as num).round()
          : int.tryParse('${json['amount'] ?? ''}') ?? 0,
      paidAt:
          DateTime.tryParse('${json['paid_at'] ?? ''}')?.toLocal() ??
          DateTime.now(),
      operator: '${json['operator'] ?? ''}',
      housing: '${json['housing'] ?? ''}',
      period: '${json['period'] ?? ''}',
    );
  }
  Map<String, dynamic> toJson() => {
    'reference': reference,
    'amount': amount,
    'paid_at': paidAt.toIso8601String(),
    'operator': operator,
    'housing': housing,
    'period': period,
  };
}
