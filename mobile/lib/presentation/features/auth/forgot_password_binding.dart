import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_auth_service.dart';
import '../../../data/remote/services/auth_service.dart';
import '../../../data/repo/auth_repository.dart';
import 'forgot_password_controller.dart';

/// Injection de l'écran « Mot de passe oublié » (route /forgot-password).
class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(
      () => AppConfig.useFakeApi ? FakeAuthService(Get.find()) : AuthService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController(repository: Get.find()));
  }
}
