import 'package:get/get.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/tenant_rent_repository.dart';
import '../../../domain/models/tenant_rent_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

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

/// « Mon loyer » (B2, B6) et historique (B5), alimentés par l'API.
class RentTrackingController extends GetxController {
  RentTrackingController({required TenantRentRepository repository, required AuthStorage authStorage})
      : _repository = repository,
        _storage = authStorage;

  final TenantRentRepository _repository;
  final AuthStorage _storage;

  final Rx<LoadStatus> loadStatus = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();

  /// Aucune location, demande en attente ou location active.
  final Rx<RentalPhase> phase = RentalPhase.none.obs;

  /// Vrai quand il n'y a pas de connexion (on affiche alors les dernières informations reçues).
  final isOffline = false.obs;

  final Rxn<TenantSituation> situation = Rxn<TenantSituation>();
  final Rxn<RentSummary> summary = Rxn<RentSummary>();
  final payments = <Payment>[].obs;

  /// Date des dernières informations reçues (affichée hors ligne).
  DateTime lastSync = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// (Re)charge la situation du locataire, son loyer du mois et ses paiements.
  Future<void> load() async {
    loadStatus.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      final snap = await _repository.load();
      situation.value = snap.situation;
      phase.value = snap.situation.phase;
      summary.value = snap.summary;
      payments.assignAll([
        for (final p in snap.payments)
          Payment(id: p.id, date: p.paidAt, amount: p.amount, operator: p.operatorLabel, period: p.periodDate),
      ]);
      isOffline.value = snap.fromCache;
      lastSync = snap.savedAt ?? DateTime.now();
      loadStatus.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      loadStatus.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = 'Impossible de charger votre loyer.';
      loadStatus.value = LoadStatus.failure;
    }
  }

  // ---- Valeurs pour la page principale (B2 et B6) ----

  /// Premier prénom du compte connecté.
  String get tenantName {
    final prenoms = _storage.user?.prenoms.trim() ?? '';
    return prenoms.isEmpty ? '' : prenoms.split(RegExp(r'\s+')).first;
  }

  /// « Appartement 1A · Fidjrossè, Cotonou »
  String get housing => situation.value?.housingLabel ?? '';

  String get ownerName => situation.value?.ownerName ?? '';

  String? get ownerPhone => situation.value?.ownerPhone;

  /// Montant dû ce mois-ci (report compris).
  num get monthlyRent => summary.value?.total ?? situation.value?.rent ?? 0;

  /// Mois de loyer affiché sur la page principale.
  DateTime get currentPeriod => summary.value?.periodDate ?? DateTime(DateTime.now().year, DateTime.now().month);

  DateTime get dueDate {
    final fromServer = summary.value?.dueDate;
    if (fromServer != null) return fromServer;
    final p = currentPeriod;
    return DateTime(p.year, p.month, situation.value?.dueDay ?? 5);
  }

  /// Pour tester l'état hors ligne sans couper vraiment la connexion.
  void toggleOffline() => isOffline.toggle();

  /// Navigation de la barre du bas.
  void goToTab(int index) {
    switch (index) {
      case 0:
        Get.offNamed(AppRoutes.listings);
      case 1:
        Get.offNamed(AppRoutes.favorites);
      case 2:
        Get.offNamed(AppRoutes.rentTracking);
      case 3:
        Get.toNamed(AppRoutes.profile);
    }
  }

  /// Saisir un code logement (B1), puis relire la situation au retour.
  Future<void> joinHousing() async {
    await Get.toNamed<void>(AppRoutes.joinHousing);
    await load();
  }

  /// « novembre » (pour « Reste à payer pour novembre »).
  String get monthLabel => monthName(currentPeriod).toLowerCase();

  /// Total déjà payé pour le mois en cours.
  num get paidThisPeriod => summary.value?.paid ?? 0;

  /// Ce qu'il reste à payer ce mois-ci.
  num get remaining => summary.value?.remaining ?? 0;

  RentStatus get status => _statusFor(paidThisPeriod, monthlyRent);

  /// « Avant le 5 novembre »
  String get dueLabel => 'Avant le ${dueDate.day} ${monthName(dueDate).toLowerCase()}';

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
    final periods = payments.map((p) => p.period).toSet().toList()..sort((a, b) => b.compareTo(a));
    final monthRent = situation.value?.rent ?? monthlyRent;

    return periods.map((period) {
      final list = payments.where((p) => p.period == period).toList()..sort((a, b) => b.date.compareTo(a.date));
      final paid = list.fold<num>(0, (sum, p) => sum + p.amount);
      return MonthGroup(period: period, payments: list, paid: paid, rent: monthRent);
    }).toList();
  }
}
