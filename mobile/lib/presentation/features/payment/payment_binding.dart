import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/services/payment_service.dart';
import '../../../data/repo/payment_repository.dart';
import 'payment_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentService>(
      () => AppConfig.useFakeApi
          ? FakePaymentService(Get.find())
          : PaymentService(Get.find()),
      fenix: true,
    );

    Get.lazyPut<PaymentRepository>(
      () => PaymentRepository(Get.find()),
      fenix: true,
    );

    Get.lazyPut<PaymentController>(
      () => PaymentController(
        paymentRepository: Get.find(),
        rentRepository: Get.find(),
        authStorage: Get.find(),
      ),
    );
  }
}
