import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repo/payment_repository.dart';
import '../../../data/repo/tenant_rent_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/installment_model.dart';
import '../../../domain/models/receipt_model.dart';
import '../../../domain/models/tenant_rent_model.dart';
import '../../routes/app_routes.dart';
import '../../shared/load_status.dart';

/// Écrans B3 "Payer mon loyer" et B4 "Paiement réussi" (lot 6).
///
/// La situation du locataire (location, mois en cours, reste à payer) vient
/// du lot 5 (TenantRentRepository) : aucune requête en double.
class PaymentController extends GetxController {
  PaymentController({
    required PaymentRepository repository,
    required TenantRentRepository rentRepository,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPolls = 30,
  })  : _repository = repository,
        _rentRepository = rentRepository;

  final PaymentRepository _repository;
  final TenantRentRepository _rentRepository;

  /// Intervalle entre deux lectures de l'état du paiement (court dans les tests).
  final Duration pollInterval;

  /// Nombre maximal de lectures avant d'abandonner la confirmation.
  final int maxPolls;

  /// Montant minimal accepté par paiement (maquette B3).
  static const minAmount = 1000;

  final Rx<LoadStatus> loadStatus = LoadStatus.initial.obs;
  final RxnString errorMessage = RxnString();

  final Rxn<TenantSituation> situation = Rxn<TenantSituation>();
  final Rxn<RentSummary> summary = Rxn<RentSummary>();

  // ---- Formulaire B3 ----
  final RxInt amount = 0.obs;
  final RxnString amountError = RxnString();
  final Rx<Operator> operator = Operator.MTN.obs;
  String _phone = '';
  final RxnString phoneError = RxnString();

  // ---- Résultat ----
  final RxBool paying = false.obs;

  /// Dernier paiement réussi (alimente B4).
  final Rxn<Installment> paid = Rxn<Installment>();

  /// Reçu du dernier paiement réussi.
  final Rxn<Receipt> receipt = Rxn<Receipt>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// (Re)charge la situation du locataire et le loyer du mois en cours.
  Future<void> load() async {
    loadStatus.value = LoadStatus.loading;
    errorMessage.value = null;
    try {
      final snap = await _rentRepository.load();
      situation.value = snap.situation;
      summary.value = snap.summary;
      loadStatus.value = LoadStatus.loaded;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      loadStatus.value = LoadStatus.failure;
    } catch (_) {
      errorMessage.value = 'Impossible de charger votre loyer.';
      loadStatus.value = LoadStatus.failure;
    }
  }

  // ---- Valeurs pour B3 ----

  String get rentalId => situation.value?.rentalId ?? '';

  /// Mois de loyer concerné : "2026-11".
  String get period => summary.value?.period ?? _currentPeriod();

  int get remaining => summary.value?.remaining ?? 0;
  int get paidSoFar => summary.value?.paid ?? 0;
  int get total => summary.value?.total ?? 0;

  DateTime get periodDate {
    final p = summary.value?.periodDate;
    if (p != null) return p;
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// "novembre"
  String get monthLabel => AppDateFormat.monthName(periodDate.month);

  DateTime get dueDate =>
      summary.value?.dueDate ?? DateTime(periodDate.year, periodDate.month, situation.value?.dueDay ?? 5);

  /// "avant le 5 novembre"
  String get dueLabel => 'avant le ${dueDate.day} ${AppDateFormat.monthName(dueDate.month)}';

  /// "Loyer de novembre"
  String get rentCardTitle => 'Loyer de $monthLabel';

  /// "Reste 60 000 FCFA"
  String get rentCardRemaining => 'Reste ${CurrencyFormatter.format(remaining)}';

  /// "90 000 déjà payés sur 150 000 . avant le 5 novembre"
  String get progressLegend =>
      '${CurrencyFormatter.number(paidSoFar)} déjà payés sur ${CurrencyFormatter.number(total)} . $dueLabel';

  double get progressValue => total <= 0 ? 0 : paidSoFar / total;

  // ---- Saisie B3 ----

  void setAmount(String raw) {
    amount.value = int.tryParse(raw) ?? 0;
    amountError.value = validateAmount();
  }

  String? validateAmount() {
    if (amount.value <= 0) return 'Entrez un montant à payer.';
    if (amount.value < minAmount) {
      return 'Minimum : ${CurrencyFormatter.format(minAmount)} par paiement.';
    }
    if (amount.value > remaining) {
      return 'Le montant dépasse le reste à payer (${CurrencyFormatter.format(remaining)}).';
    }
    return null;
  }

  void setOperator(Operator op) => operator.value = op;

  void setPhone(String raw) {
    _phone = raw.replaceAll(RegExp(r'[\s.\-]'), '');
    phoneError.value = Validators.phone(raw);
  }

  /// Numéro nettoyé, tel qu'envoyé au serveur (10 chiffres, sans +229).
  String get phone => _phone;

  /// "+229 01 97 •• •• 56"
  String get maskedPhone => maskPhone(_phone);

  /// Numéro débité par le paiement réussi (B4), masqué comme le formulaire.
  /// Repli sur le numéro saisi si le serveur ne le renvoie pas.
  String get paidPhoneLabel {
    final p = paid.value?.phone ?? '';
    return maskPhone(p.isEmpty ? _phone : p);
  }

  /// Masque un numéro local : "0197123456" -> "+229 01 97 •• •• 56".
  String maskPhone(String raw) {
    final p = raw.replaceAll(RegExp(r'[\s.\-]'), '');
    if (p.isEmpty) return '';
    if (p.length < 10) return '${AppConstants.phoneCode} $p';
    return '${AppConstants.phoneCode} ${p.substring(0, 2)} ${p.substring(2, 4)} •• •• ${p.substring(8)}';
  }

  // ---- Paiement ----

  /// Envoie le paiement puis attend la réponse de l'opérateur.
  Future<void> pay() async {
    amountError.value = validateAmount();
    phoneError.value = Validators.phone(_phone);
    if (amountError.value != null || phoneError.value != null) return;
    if (rentalId.isEmpty) {
      _notify('Paiement indisponible', 'Aucune location active à payer.');
      return;
    }
    if (paying.value) return;
    paying.value = true;
    try {
      var current = await _repository.create(
        rentalId: rentalId,
        period: period,
        amount: amount.value,
        operator: operator.value.name,
        phone: _phone,
      );
      var polls = 0;
      while (current.status == PaymentStatus.PENDING && polls < maxPolls) {
        await Future<void>.delayed(pollInterval);
        current = await _repository.status(current.id);
        polls++;
      }
      if (current.status == PaymentStatus.SUCCESS) {
        paid.value = current;
        await load(); // nouveau reste à payer
        try {
          receipt.value = await _repository.receipt(current.id);
        } on AppException {
          receipt.value = null; // le reçu reste disponible plus tard
        }
        Get.offNamed(AppRoutes.paymentSuccess);
      } else if (current.status == PaymentStatus.FAILED) {
        _notify('Paiement échoué', "L'opérateur a refusé le paiement. Vérifiez le numéro et réessayez.");
      } else {
        _notify('Paiement en attente', "La confirmation n'a pas abouti à temps. Consultez votre solde.");
      }
    } on AppException catch (e) {
      _notify('Paiement refusé', e.message);
    } catch (_) {
      _notify('Paiement refusé', 'Une erreur est survenue. Réessayez.');
    } finally {
      paying.value = false;
    }
  }

  // ---- B4 ----

  /// B4 ouvert directement (menu de dev) : recharge le paiement de la route.
  Future<void> ensurePaid() async {
    if (paid.value != null) return;
    final id = Get.parameters['id'] ?? '';
    if (id.isEmpty) return;
    try {
      final current = await _repository.status(id);
      if (current.status == PaymentStatus.SUCCESS) {
        paid.value = current;
        await load();
        receipt.value = await _repository.receipt(id);
      }
    } on AppException catch (e) {
      errorMessage.value = e.message;
    }
  }

  /// Recharge le reçu du dernier paiement réussi.
  Future<void> loadReceipt() async {
    final p = paid.value;
    if (p == null) return;
    receipt.value = await _repository.receipt(p.id);
  }

  /// "Retour à mon loyer" (B4).
  void backToRent() => Get.offNamed(AppRoutes.rentTracking);

  void _notify(String title, String message) {
    // Hors widget test (pas d'overlay), aucune snackbar possible.
    if (Get.context == null) return;
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  static String _currentPeriod() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}