import 'package:get/get.dart';

import '../../../data/remote/services/auth_service.dart';
import '../../../data/repo/auth_repository.dart';
import 'auth_controller.dart';

/// Utilisé par les routes /login et /register.
/// ApiClient et AuthStorage sont déjà enregistrés dans main.dart.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Couche données : fenix pour pouvoir être recréée plus tard.
    Get.lazyPut<AuthService>(() => AuthService(Get.find()), fenix: true);
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find(), Get.find()),
      fenix: true,
    );
    // Contrôleur de l'écran : détruit à la fermeture de la page.
    Get.lazyPut<AuthController>(() => AuthController(repository: Get.find()));
  }
}
