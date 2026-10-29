import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_auth_service.dart';
import '../../../data/remote/services/auth_service.dart';
import '../../../data/repo/auth_repository.dart';
import 'auth_controller.dart';

/// Utilisé par les routes /login et /register.
/// ApiClient et AuthStorage sont déjà enregistrés par `initializeDependencies()`.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Couche données : fenix pour pouvoir être recréée plus tard.
    // Le service réel ou simulé est choisi selon le mode de compilation.
    Get.lazyPut<AuthService>(
      () => AppConfig.useFakeApi
          ? FakeAuthService(Get.find())
          : AuthService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find(), Get.find()),
      fenix: true,
    );
    // Contrôleur de l'écran : détruit à la fermeture de la page.
    Get.lazyPut<AuthController>(() => AuthController(repository: Get.find()));
  }
}
