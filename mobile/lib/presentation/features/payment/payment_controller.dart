import 'package:get/get.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/cache/auth_storage.dart';
import '../../../data/repo/payment_repository.dart';
import '../../../data/repo/tenant_rent_repository.dart';
import '../../../domain/models/receipt_model.dart';
import '../../../domain/models/tenant_rent_model.dart';
import '../../routes/app_routes.dart';

enum PaymentStep { form, processing, failure }

class PaymentController extends GetxController {
  PaymentController({
    required PaymentRepository paymentRepository,
    required TenantRentRepository rentRepository,
    required AuthStorage authStorage,
  }) : _paymentRepository = paymentRepository,
       _rentRepository = rentRepository,
       _authStorage = authStorage;
  final PaymentRepository _paymentRepository;
  final TenantRentRepository _rentRepository;
  final AuthStorage _authStorage;
  final Rx<PaymentStep> step = PaymentStep.form.obs;
  final RxBool isLoadingData = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();
  final RxString rentalId = ''.obs;
  final RxString period = ''.obs;
  final RxString housingTitle = ''.obs;
  final RxInt remainingDue = 0.obs;
  final RxInt totalDue = 0.obs;
  final RxInt paidSoFar = 0.obs;
  final RxString dueDateLabel = ''.obs;
  final RxString selectedOperator = 'MTN'.obs;
  final Rxn<ReceiptModel> receipt = Rxn<ReceiptModel>();
  String get defaultPhone {
    final phone = _authStorage.user?.telephone ?? '';
    return phone.replaceFirst('+229', '').trim();
  }

  @override
  void onInit() {
    super.onInit();
    _loadRentDetails();
  }

  Future<void> _loadRentDetails() async {
    isLoadingData.value = true;
    errorMessage.value = null;
    try {
      final snapshot = await _rentRepository.load();
      final situation = snapshot.situation;
      final summary = snapshot.summary;
      rentalId.value = situation.rentalId;
      housingTitle.value = situation.housingTitle;
      period.value =
          summary?.period ??
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      remainingDue.value = summary?.remaining ?? situation.rent;
      totalDue.value = summary?.total ?? situation.rent;
      paidSoFar.value = summary?.paid ?? 0;
      final dueDay = situation.dueDay;
      dueDateLabel.value = 'avant le $dueDay du mois';
      isLoadingData.value = false;
    } on AppException catch (e) {
      errorMessage.value = e.message;
      isLoadingData.value = false;
    } catch (_) {
      errorMessage.value = 'Impossible de charger les données du loyer.';
      isLoadingData.value = false;
    }
  }

  void selectOperator(String op) {
    selectedOperator.value = op;
  }

  Future<void> submitPayment({
    required int amount,
    required String phone,
  }) async {
    if (isSubmitting.value) return;

    if (amount < 1000) {
      Get.snackbar(
        'Montant insuffisant',
        'Le montant minimum par paiement est de 1 000 FCFA.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (amount > remainingDue.value && remainingDue.value > 0) {
      Get.snackbar(
        'Montant excessif',
        'Le montant ne peut pas dépasser le solde restant (${remainingDue.value} FCFA).',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    isSubmitting.value = true;
    errorMessage.value = null;
    step.value = PaymentStep.processing;
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final initiation = await _paymentRepository.initiatePayment(
        rentalId: rentalId.value,
        period: period.value,
        amount: amount,
        operator: selectedOperator.value,
        phone: cleanPhone,
      );
      final finalStatus = await _paymentRepository.pollStatus(initiation.id);
      if (finalStatus == 'SUCCESS') {
        final rec = await _paymentRepository.fetchReceipt(initiation.id);
        receipt.value = rec;
        isSubmitting.value = false;
        Get.offNamed(AppRoutes.paymentReceipt);
      } else if (finalStatus == 'FAILED') {
        isSubmitting.value = false;
        step.value = PaymentStep.failure;
        errorMessage.value =
            'Le paiement a échoué. Vérifiez votre solde Mobile Money et votre code secret.';
      } else {
        isSubmitting.value = false;
        step.value = PaymentStep.form;
        Get.snackbar(
          'Paiement en attente',
          'Votre paiement est toujours en cours de confirmation. Vous le retrouverez dans votre historique.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        Get.offAllNamed(AppRoutes.rentTracking);
      }
    } on AppException catch (e) {
      isSubmitting.value = false;
      step.value = PaymentStep.form;
      errorMessage.value = e.message;
      Get.snackbar(
        'Erreur de paiement',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      isSubmitting.value = false;
      step.value = PaymentStep.form;
      errorMessage.value = 'Une erreur inattendue est survenue.';
      Get.snackbar(
        'Erreur',
        'Impossible de joindre le serveur de paiement.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void retry() {
    step.value = PaymentStep.form;
    errorMessage.value = null;
  }
}
