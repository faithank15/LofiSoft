import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_admin_service.dart';
import '../../../data/remote/services/admin_service.dart';
import '../../../data/repo/admin_repository.dart';
import 'admin_controller.dart';

/// Injection des dépendances du lot 9 (signalements et vérifications d'identité).
/// ApiClient et AuthStorage sont déjà enregistrés au démarrage (di/injector.dart).
class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminService>(
      () => AppConfig.useFakeApi ? FakeAdminService(Get.find()) : AdminService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<AdminRepository>(() => AdminRepository(Get.find()), fenix: true);

    Get.lazyPut<AdminController>(
      () => AdminController(repository: Get.find()),
    );
  }
}
