import 'package:get/get.dart';
import 'onboarding_controller.dart';

/// Injecteur de dépendances du module d'onboarding.
///
/// Déclaré sans `fenix` afin de libérer immédiatement la mémoire dès
/// que l'utilisateur quitte le tunnel d'onboarding.
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}
