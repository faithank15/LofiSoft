import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_payment_service.dart';
import '../../../data/remote/fakes/fake_rental_service.dart';
import '../../../data/remote/services/payment_service.dart';
import '../../../data/remote/services/rental_service.dart';
import '../../../data/repo/payment_repository.dart';
import '../../../data/repo/tenant_rent_repository.dart';
import 'payment_controller.dart';

/// Injection du lot 6 (paiement B3/B4). ApiClient, AuthStorage et AppStorage
/// sont déjà enregistrés au démarrage (di/injector.dart).
class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentService>(
      () => AppConfig.useFakeApi ? FakePaymentService(Get.find()) : PaymentService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<PaymentRepository>(() => PaymentRepository(Get.find()), fenix: true);

    // Situation du locataire et loyer du mois (lot 5), réutilisés tels quels.
    Get.lazyPut<RentalService>(
      () => AppConfig.useFakeApi ? FakeRentalService(Get.find()) : RentalService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<TenantRentRepository>(() => TenantRentRepository(Get.find(), Get.find()), fenix: true);

    Get.lazyPut<PaymentController>(
      () => PaymentController(repository: Get.find(), rentRepository: Get.find()),
    );
  }
}
