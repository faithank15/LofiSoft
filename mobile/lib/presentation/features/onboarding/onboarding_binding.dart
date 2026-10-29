import 'package:get/get.dart';

import '../../../core/constants/app_config.dart';
import '../../../data/remote/fakes/fake_auth_service.dart';
import '../../../data/remote/fakes/fake_upload_service.dart';
import '../../../data/remote/services/auth_service.dart';
import '../../../data/remote/services/upload_service.dart';
import '../../../data/repo/identity_repository.dart';
import 'onboarding_controller.dart';

/// Injecteur de dépendances du module d'onboarding propriétaire (E5 à E7).
///
/// Le contrôleur est déclaré sans `fenix` afin de libérer immédiatement la mémoire dès
/// que l'utilisateur quitte le tunnel ; la couche données, elle, peut être recréée.
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthService>(
      () => AppConfig.useFakeApi ? FakeAuthService(Get.find()) : AuthService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<UploadService>(
      () => AppConfig.useFakeApi ? FakeUploadService(Get.find()) : UploadService(Get.find()),
      fenix: true,
    );
    Get.lazyPut<IdentityRepository>(() => IdentityRepository(Get.find(), Get.find()), fenix: true);
    Get.lazyPut<OnboardingController>(() => OnboardingController(repository: Get.find()));
  }
}
