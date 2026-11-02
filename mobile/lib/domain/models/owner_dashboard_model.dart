import '../../core/utils/json_utils.dart';
import 'enums.dart';

const _months = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

/// « Novembre »
String frenchMonthName(DateTime d) => _months[d.month - 1];

int _toInt(Object? v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;

/// Chiffres du mois pour le propriétaire (réponse de GET /owner/dashboard).
class OwnerDashboard {
  const OwnerDashboard({
    required this.month,
    required this.expected,
    required this.received,
    required this.lateCount,
    required this.tenantsCount,
    required this.housingsCount,
  });

  /// Mois au format « 2026-11 ».
  final String month;

  /// Loyers attendus ce mois-ci.
  final int expected;

  /// Loyers déjà reçus.
  final int received;
  final int lateCount;
  final int tenantsCount;
  final int housingsCount;

  /// Part reçue, entre 0 et 1.
  double get progress =>
      expected <= 0 ? 0 : (received / expected).clamp(0.0, 1.0).toDouble();

  int get percent => (progress * 100).round();

  DateTime get monthDate {
    final parts = month.split('-');
    final now = DateTime.now();
    final year = int.tryParse(parts.first) ?? now.year;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? now.month) : now.month;
    return DateTime(year, m);
  }

  /// « Novembre »
  String get monthName => frenchMonthName(monthDate);

  /// « Novembre 2026 »
  String get monthTitle => '$monthName ${monthDate.year}';

  String get previousMonthName =>
      frenchMonthName(DateTime(monthDate.year, monthDate.month - 1));

  /// « d’octobre » ou « de septembre » (pour « reportés d’octobre »).
  String get carriedFromLabel {
    final name = previousMonthName.toLowerCase();
    const vowels = 'aeiouyéèêàâîôû';
    return vowels.contains(name[0]) ? 'd’$name' : 'de $name';
  }

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) {
    return OwnerDashboard(
      month: '${json['month'] ?? ''}',
      expected: _toInt(json['expected']),
      received: _toInt(json['received']),
      lateCount: _toInt(json['late_count']),
      tenantsCount: _toInt(json['tenants_count']),
      housingsCount: _toInt(json['housings_count']),
    );
  }
}

/// Un locataire et sa situation pour le mois (une ligne de GET /owner/tenants).
class TenantRent {
  const TenantRent({
    required this.rentalId,
    required this.tenantName,
    required this.housing,
    required this.due,
    required this.carriedOver,
    required this.status,
    this.paid,
  });

  final String rentalId;
  final String tenantName;
  final String housing;

  /// Montant dû ce mois-ci (reports compris).
  final int due;

  /// Part du montant dû reportée du mois précédent.
  final int carriedOver;
  final RentStatus status;

  /// Montant déjà payé. Facultatif : le serveur ne le renvoie pas encore.
  final int? paid;

  /// Ce qu'il reste à payer, si on connaît le montant payé.
  int? get remaining {
    final p = paid;
    if (p == null) return null;
    final left = due - p;
    return left < 0 ? 0 : left;
  }

  /// « Éric »
  String get firstName {
    final parts = tenantName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  /// « ÉB » pour « Éric Bio-Tchané »
  String get initials {
    final parts = tenantName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// « Appart. 3C »
  String get shortHousing => housing.replaceFirst('Appartement', 'Appart.');

  factory TenantRent.fromJson(Map<String, dynamic> json) {
    return TenantRent(
      rentalId: '${json['rental_id'] ?? ''}',
      tenantName: '${json['tenant_name'] ?? ''}',
      housing: '${json['housing'] ?? ''}',
      due: _toInt(json['due']),
      carriedOver: _toInt(json['carried_over']),
      status: _parseStatus(json['status']),
      paid: json['paid'] == null ? null : _toInt(json['paid']),
    );
  }

  static RentStatus _parseStatus(Object? raw) {
    final val = '${raw ?? ''}'.toUpperCase();
    for (final s in RentStatus.values) {
      if (s.name == val) return s;
    }
    return RentStatus.UPCOMING;
  }
}