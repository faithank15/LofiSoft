import 'package:get/get.dart';
import '../../routes/app_routes.dart';

/// Situation d'un mois de loyer.
enum RentStatus { paid, partial, unpaid }

RentStatus _statusFor(num paid, num rent) {
  if (paid >= rent) return RentStatus.paid;
  if (paid <= 0) return RentStatus.unpaid;
  return RentStatus.partial;
}

/// Un paiement fait par le locataire.
class Payment {
  Payment({
    required this.id,
    required this.date,
    required this.amount,
    required this.operator,
    required this.period,
  });

  final String id;

  /// Jour où le locataire a payé.
  final DateTime date;

  final num amount;

  /// Opérateur Mobile Money (MTN Mobile Money, Moov Money…).
  final String operator;

  /// Mois de loyer concerné (le jour est toujours le 1).
  final DateTime period;
}

/// Les paiements d'un même mois de loyer (pour l'historique, écran B5).
class MonthGroup {
  MonthGroup({
    required this.period,
    required this.payments,
    required this.paid,
    required this.rent,
  });

  final DateTime period;
  final List<Payment> payments;
  final num paid;
  final num rent;

  RentStatus get status => _statusFor(paid, rent);
}

const _months = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

const _shortMonths = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// « Novembre »
String monthName(DateTime d) => _months[d.month - 1];

class RentTrackingController extends GetxController {
  // Données de démonstration, à remplacer quand le backend sera prêt.
  final tenantName = 'Patrick';
  final housing = 'Appartement 1A · Résidence Le Soleil';
  final ownerName = 'Koffi Mensah';
  final num monthlyRent = 150000;

  /// Mois de loyer affiché sur la page principale.
  final currentPeriod = DateTime(2026, 11);
  final dueDate = DateTime(2026, 11, 5);

  /// Date des dernières informations reçues (affichée hors ligne).
  final lastSync = DateTime(2026, 10, 22, 18, 40);

  /// Vrai quand il n'y a pas de connexion.
  final isOffline = false.obs;

  final payments = <Payment>[
    Payment(
      id: '1',
      date: DateTime(2026, 10, 15),
      amount: 40000,
      operator: 'MTN Mobile Money',
      period: DateTime(2026, 11),
    ),
    Payment(
      id: '2',
      date: DateTime(2026, 10, 8),
      amount: 50000,
      operator: 'MTN Mobile Money',
      period: DateTime(2026, 11),
    ),
    Payment(
      id: '3',
      date: DateTime(2026, 10, 3),
      amount: 150000,
      operator: 'Moov Money',
      period: DateTime(2026, 10),
    ),
    Payment(
      id: '4',
      date: DateTime(2026, 9, 4),
      amount: 150000,
      operator: 'MTN Mobile Money',
      period: DateTime(2026, 9),
    ),
  ].obs;

  /// Pour tester l'état hors ligne sans couper vraiment la connexion.
  void toggleOffline() => isOffline.toggle();

  // ---- Valeurs pour la page principale (B2 et B6) ----
  /// Navigation de la barre du bas.
  void goToTab(int index) {
    switch (index) {
      case 0:
        Get.offNamed(AppRoutes.listings);
      case 1:
        Get.offNamed(AppRoutes.favorites);
      case 2:
        Get.offNamed(AppRoutes.rentTracking);
    }
  }

  /// « novembre » (pour « Reste à payer pour novembre »).
  String get monthLabel => monthName(currentPeriod).toLowerCase();

  /// Total déjà payé pour le mois en cours.
  num get paidThisPeriod => payments
      .where((p) => p.period == currentPeriod)
      .fold<num>(0, (sum, p) => sum + p.amount);

  /// Ce qu'il reste à payer ce mois-ci.
  num get remaining => (monthlyRent - paidThisPeriod).clamp(0, monthlyRent);

  RentStatus get status => _statusFor(paidThisPeriod, monthlyRent);

  /// « Avant le 5 novembre »
  String get dueLabel =>
      'Avant le ${dueDate.day} ${monthName(dueDate).toLowerCase()}';

  /// « Informations du 22 oct. à 18 h 40 »
  String get lastSyncLabel {
    final minutes = lastSync.minute.toString().padLeft(2, '0');
    return 'Informations du ${lastSync.day} ${_shortMonths[lastSync.month - 1]}'
        ' à ${lastSync.hour} h $minutes';
  }

  /// Les deux paiements les plus récents.
  List<Payment> get lastPayments {
    final sorted = [...payments]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(2).toList();
  }

  // ---- Historique (B5) ----

  /// Paiements regroupés par mois de loyer, du plus récent au plus ancien.
  List<MonthGroup> get history {
    final periods = payments.map((p) => p.period).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    return periods.map((period) {
      final list = payments.where((p) => p.period == period).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final paid = list.fold<num>(0, (sum, p) => sum + p.amount);
      return MonthGroup(
        period: period,
        payments: list,
        paid: paid,
        rent: monthlyRent,
      );
    }).toList();
  }
}