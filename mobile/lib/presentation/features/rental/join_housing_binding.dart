import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_rental_service.dart';
import '../../../data/remote/services/rental_service.dart';
import '../../../data/repo/rental_repository.dart';
import 'join_housing_controller.dart';

class JoinHousingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentalService>(
      () => AppConfig.useFakeApi ? FakeRentalService(Get.find()) : RentalService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<RentalRepository>(() => RentalRepository(Get.find()), fenix: true);
    Get.lazyPut<JoinHousingController>(
      () => JoinHousingController(repository: Get.find(), authStorage: Get.find()),
    );
  }
}
