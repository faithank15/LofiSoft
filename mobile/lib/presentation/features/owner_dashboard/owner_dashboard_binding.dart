import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_owner_dashboard_service.dart';
import '../../../data/remote/services/owner_dashboard_service.dart';
import '../../../data/repo/owner_dashboard_repository.dart';
import 'owner_dashboard_controller.dart';

/// Injection des dépendances du lot 7 (tableau de bord et loyers propriétaire).
class OwnerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OwnerDashboardService>(
          () => AppConfig.useFakeApi
          ? FakeOwnerDashboardService(Get.find())
          : OwnerDashboardService(Get.find()),
      fenix: true,
    );

    Get.lazyPut<OwnerDashboardRepository>(
          () => OwnerDashboardRepository(Get.find()),
      fenix: true,
    );

    Get.lazyPut<OwnerDashboardController>(
          () => OwnerDashboardController(repository: Get.find(), authStorage: Get.find()),
    );
  }
}