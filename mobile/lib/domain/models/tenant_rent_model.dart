import '../../core/utils/json_utils.dart';

int _int(Object? v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;

/// Où en est le locataire (réponse de GET /me/situation).
enum RentalPhase {
  /// Aucune location : il doit saisir un code logement.
  none,

  /// Demande envoyée, le propriétaire n'a pas encore répondu.
  pending,

  /// Location confirmée : le loyer peut être suivi et payé.
  active,
}

class TenantSituation {
  const TenantSituation({
    required this.phase,
    this.rentalId = '',
    this.housingTitle = '',
    this.city = '',
    this.district = '',
    this.rent = 0,
    this.dueDay = 5,
    this.ownerName = '',
    this.ownerPhone,
  });

  final RentalPhase phase;
  final String rentalId;
  final String housingTitle;
  final String city;
  final String district;
  final int rent;
  final int dueDay;
  final String ownerName;
  final String? ownerPhone;

  /// « Résidence · Fidjrossè, Cotonou »
  String get housingLabel {
    final place = [district, city].where((s) => s.trim().isNotEmpty).join(', ');
    return [housingTitle, place].where((s) => s.trim().isNotEmpty).join(' · ');
  }

  factory TenantSituation.fromJson(Map<String, dynamic> json) {
    final phase = switch ('${json['status'] ?? ''}'.toUpperCase()) {
      'ACTIVE' => RentalPhase.active,
      'PENDING' => RentalPhase.pending,
      _ => RentalPhase.none,
    };
    final housing = asJsonMap(json['housing']);
    final owner = asJsonMap(json['owner']);
    final phone = '${owner['telephone'] ?? ''}'.trim();
    return TenantSituation(
      phase: phase,
      rentalId: '${json['rental_id'] ?? ''}',
      housingTitle: '${housing['title'] ?? ''}',
      city: '${housing['city'] ?? ''}',
      district: '${housing['district'] ?? ''}',
      rent: _int(housing['rent']),
      dueDay: housing['due_day'] == null ? 5 : _int(housing['due_day']),
      ownerName: '${owner['name'] ?? ''}'.trim(),
      ownerPhone: phone.isEmpty ? null : phone,
    );
  }
}

/// Le mois en cours (réponse de GET /me/rent).
class RentSummary {
  const RentSummary({
    required this.period,
    required this.total,
    required this.paid,
    required this.remaining,
    this.dueDate,
  });

  /// « 2026-11 »
  final String period;

  /// Montant dû ce mois-ci, report éventuel compris.
  final int total;
  final int paid;
  final int remaining;
  final DateTime? dueDate;

  DateTime get periodDate {
    final parts = period.split('-');
    final now = DateTime.now();
    return DateTime(
      int.tryParse(parts.first) ?? now.year,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? now.month) : now.month,
    );
  }

  factory RentSummary.fromJson(Map<String, dynamic> json) => RentSummary(
        period: '${json['period'] ?? ''}',
        total: _int(json['total']),
        paid: _int(json['paid']),
        remaining: _int(json['remaining']),
        dueDate: DateTime.tryParse('${json['due_date'] ?? ''}'),
      );
}

/// Un paiement du locataire (une ligne de GET /me/payments).
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.operator,
    required this.period,
    required this.paidAt,
    required this.success,
  });

  final String id;
  final int amount;

  /// `MTN`, `MOOV` ou `CASH`.
  final String operator;

  /// « 2026-11 »
  final String period;
  final DateTime paidAt;

  /// Seuls les paiements réussis comptent dans le loyer payé.
  final bool success;

  /// « MTN Mobile Money »
  String get operatorLabel => switch (operator.toUpperCase()) {
        'MTN' => 'MTN Mobile Money',
        'MOOV' => 'Moov Money',
        'CASH' => 'Espèces',
        final other => other,
      };

  DateTime get periodDate {
    final parts = period.split('-');
    return DateTime(int.tryParse(parts.first) ?? paidAt.year, parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1);
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: '${json['id'] ?? ''}',
      amount: _int(json['amount']),
      operator: '${json['operator'] ?? ''}',
      period: '${json['period'] ?? ''}',
      paidAt: DateTime.tryParse('${json['paid_at'] ?? ''}')?.toLocal() ?? DateTime.now(),
      success: '${json['status'] ?? ''}'.toUpperCase() == 'SUCCESS',
    );
  }
}

/// Tout ce que l'écran « Mon loyer » affiche, avec sa provenance (réseau ou cache).
class TenantRentSnapshot {
  const TenantRentSnapshot({
    required this.situation,
    this.summary,
    this.payments = const [],
    this.fromCache = false,
    this.savedAt,
  });

  final TenantSituation situation;
  final RentSummary? summary;
  final List<PaymentRecord> payments;

  /// `true` : réseau indisponible, ce sont les dernières informations reçues.
  final bool fromCache;
  final DateTime? savedAt;
}
