import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_auth_service.dart';
import '../../../data/remote/services/auth_service.dart';
import '../../../data/repo/auth_repository.dart';
import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Le lancement revalide la session auprès du serveur (GET /auth/me).
    Get.lazyPut<AuthService>(
      () => AppConfig.useFakeApi ? FakeAuthService(Get.find()) : AuthService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find(), Get.find()), fenix: true);
    // Get.put (et non lazyPut) : la page n'utilise jamais `controller`, donc un lazyPut ne
    // serait jamais créé et la redirection ne partirait pas (splash infini).
    Get.put<SplashController>(SplashController());
  }
}
