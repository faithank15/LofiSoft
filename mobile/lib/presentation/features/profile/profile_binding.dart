import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_auth_service.dart';
import '../../../data/remote/services/auth_service.dart';
import '../../../data/repo/auth_repository.dart';
import 'profile_controller.dart';

/// Injection de la page Profil. ApiClient et AuthStorage sont déjà enregistrés au démarrage.
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(
      () => AppConfig.useFakeApi ? FakeAuthService(Get.find()) : AuthService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<ProfileController>(
      () => ProfileController(repository: Get.find(), storage: Get.find()),
    );
  }
}
