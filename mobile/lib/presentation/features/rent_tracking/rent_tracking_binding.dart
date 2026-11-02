import 'package:get/get.dart';

import '../../../data/cache/auth_storage.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_rental_service.dart';
import '../../../data/remote/services/rental_service.dart';
import '../../../data/repo/tenant_rent_repository.dart';
import 'rent_tracking_controller.dart';

/// Injection de « Mon loyer » et de l'historique. ApiClient, AuthStorage et AppStorage sont déjà enregistrés.
class RentTrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RentalService>(
      () => AppConfig.useFakeApi ? FakeRentalService(Get.find()) : RentalService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<TenantRentRepository>(() => TenantRentRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<RentTrackingController>(
      () => RentTrackingController(repository: Get.find(), authStorage: Get.find<AuthStorage>()),
    );
  }
}
